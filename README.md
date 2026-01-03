<div align = center>

# AltTab

Fork of [AltTab](https://alt-tab-macos.netlify.app/) with custom tweaks.

**AltTab** brings the power of Windows alt-tab to macOS

[Official website](https://alt-tab-macos.netlify.app/)<br/><sub>15K stars</sub> | [Download](https://github.com/lwouis/alt-tab-macos/releases/download/v9.0.0/AltTab-9.0.0.zip)<br/><sub>6.8M downloads</sub>
-|-

<div align="right">
  <p>Project supported by</p>
  <a href="https://jb.gg/OpenSource">
    <img src="docs/public/demo/jetbrains.svg" alt="Jetbrains" width="149" height="32">
  </a>
</div>

</div>

### Fixing TCC permissions when doing local dev
1. Delete existing AltTab.app binary
2. Remove TCC record from Privacy & Security and then also run `sudo tccutil reset Accessibility com.lwouis.alt-tab-macos`
3. Copy the new AltTab.app into /Applications (but don't open it yet)
4. Manually add the new AltTab.app to Accessibility in Privacy & Security
5. Open the new AltTab.app
