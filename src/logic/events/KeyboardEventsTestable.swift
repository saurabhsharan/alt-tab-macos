import Cocoa
import Carbon.HIToolbox.Events
import ShortcutRecorder

class KeyboardEventsTestable {
    static let globalShortcutsIds = [
        "nextWindowShortcut": 0,
        "nextWindowShortcut2": 1,
        "nextWindowShortcut3": 2,
        "holdShortcut": 5,
        "holdShortcut2": 6,
        "holdShortcut3": 7,
    ]
}

/// Helpers for behavior that is hard to unit-test end-to-end (e.g. when we intercept and swallow system key events).
///
/// This lives next to `handleKeyboardEvent` so the unit-tests target can compile and exercise it without pulling in
/// `KeyboardEvents.swift` (which depends on CGEvent taps and other runtime plumbing).
enum CommandShiftTabInterception {
    /// Intercepts `Cmd+Shift+Tab` *only while AltTab is active* for the specific personal-fork behavior:
    ///
    /// - `Preferences.previousWindowShortcut == "⇧"` (Shift-only)
    /// - current Control's Hold shortcut is **Command-only**
    /// - key event is `Tab` with exactly `Cmd+Shift` modifiers
    ///
    /// Why this exists:
    /// - We keep the native macOS `Cmd+Shift+Tab` hotkey enabled so it can open the system app switcher when AltTab is not open.
    /// - While AltTab *is* open, we swallow the system `Cmd+Shift+Tab` event so macOS doesn't show its switcher.
    /// - Because we swallow the event, our usual local `keyUp` does not get delivered, which can leave the
    ///   `previousWindowShortcut` state stuck in `.down` and make subsequent presses do nothing.
    /// - To avoid that, we explicitly reset the shortcut state back to `.up` after triggering.
    @discardableResult
    static func interceptCommandShiftTabIfNeeded(_ keyCode: UInt32, _ modifiers: NSEvent.ModifierFlags, _ isARepeat: Bool) -> Bool {
        guard App.app.appIsBeingUsed else { return false }
        guard Preferences.previousWindowShortcut == "⇧" else { return false }

        let holdMods = ControlsTab.shortcuts[Preferences.indexToName("holdShortcut", App.app.shortcutIndex)]?.shortcut.carbonModifierFlags.cleaned() ?? 0
        guard holdMods == UInt32(cmdKey) else { return false }

        guard keyCode == UInt32(kVK_Tab) else { return false }
        let modifiersCleaned = modifiers.cleaned()
        let modifiersCarbon = cocoaToCarbonFlags(modifiersCleaned).cleaned()
        guard modifiersCarbon == UInt32(cmdKey | shiftKey) else { return false }

        _ = handleKeyboardEvent(nil, nil, keyCode, modifiersCleaned, isARepeat)
        // We may have swallowed the original system event (see `KeyboardEvents.cgEventCommandShiftTabHandler`),
        // so we might never see the corresponding local `keyUp`. Ensure the state machine can trigger again.
        ControlsTab.shortcuts["previousWindowShortcut"]?.state = .up
        return true
    }
}

/// When `previousWindowShortcut` is modifiers-only, macOS won't send repeated "key pressed" events.
/// We simulate repeats via a timer in `KeyRepeatTimer.startRepeatingKeyPreviousWindow()`.
///
/// However, when "Select previous window" is configured as Shift-only ("⇧"), we *no longer trigger it on Shift*.
/// We trigger it on `Hold + Shift + Tab`, and in that mode the OS's natural `Tab` key repeat is sufficient.
enum PreviousWindowArtificialRepeatPolicy {
    static func shouldStartArtificialRepeat(preference: String, shortcut: Shortcut) -> Bool {
        // Shift-only is special-cased to require Hold+Shift+Tab; artificial repeat would cause "ghost repeats"
        // after a single press because the shortcut state isn't tied to a key-up we reliably receive.
        if preference == "⇧" { return false }
        // When a shortcut includes a keycode, the OS repeats keyDown events naturally.
        return shortcut.keyCode == .none
    }
}

@discardableResult
func handleKeyboardEvent(_ globalId: Int?, _ shortcutState: ShortcutState?, _ keyCode: UInt32?, _ modifiers: NSEvent.ModifierFlags?, _ isARepeat: Bool) -> Bool {
    if let globalId, let shortcutState {
        Logger.debug {
            let shortcut = KeyboardEventsTestable.globalShortcutsIds.first { $0.value == globalId }
            return "globalShortcut:\(shortcut?.key ?? "") state:\(shortcutState)"
        }
    } else {
        // TODO: use proper pattern from SwiftBeaver to not compute SymbolicModifierFlagsTransformer when logs are off
        Logger.debug {
            let modifiersAsString = modifiers.flatMap { SymbolicModifierFlagsTransformer.shared.transformedValue(NSNumber(value: $0.rawValue)) }
            let keyCodeAsString = keyCode.flatMap { SymbolicKeyCodeTransformer.shared.transformedValue(NSNumber(value: $0)) }
            return "keys:\(modifiersAsString ?? "")\(keyCodeAsString ?? "") isARepeat:\(isARepeat)"
        }
    }
    var someShortcutTriggered = false
    for shortcut in ControlsTab.shortcuts.values {
        if shortcut.matches(globalId, shortcutState, keyCode, modifiers) && shortcut.shouldTrigger() {
            shortcut.executeAction(isARepeat)
            // we want to pass-through alt-up to the active app, since it saw alt-down previously
            if !shortcut.id.starts(with: "holdShortcut") {
                someShortcutTriggered = true
            }
        }
        shortcut.redundantSafetyMeasures()
    }
    // TODO if we manage to move all keyboard listening to the background thread, we'll have issues returning this boolean
    // this function uses many objects that are also used on the main-thread. It also executes the actions
    // we'll have to rework this whole approach. Today we rely on somewhat in-order events/actions
    // special attention should be given to App.app.appIsBeingUsed which is being set to true when executing the nextWindowShortcut action
    return someShortcutTriggered
}
