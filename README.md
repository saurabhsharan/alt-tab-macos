# AltTab

Fork of [AltTab](https://alt-tab-macos.netlify.app/) with custom tweaks.

### Fixing TCC permissions when doing local dev
1. Delete existing AltTab.app binary
2. Remove TCC record from Privacy & Security and then also run `sudo tccutil reset Accessibility com.lwouis.alt-tab-macos`
3. Copy the new AltTab.app into /Applications (but don't open it yet)
4. Manually add the new AltTab.app to Accessibility in Privacy & Security
5. Open the new AltTab.app
