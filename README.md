# AltTab

Fork of [AltTab](https://alt-tab-macos.netlify.app/) with custom tweaks.

### git patch workflow

High-level: keep `master` a mirror of `upstream/master`, and put all personal patches on `saurabh-patches` branch that is rebased on top of master

Make all changes on the `saurabh-patches` branch and push to that branch like normal.

For keeping in sync with upstream:
1. `git switch master`
2. `git fetch upstream`
3. `git reset --hard upstream/master`
4. `git push --force-with-lease origin master`
5. `git switch saurabh-patches`
6. `git rebase upstream/master`
7. `git push --force-with-lease origin saurabh-patches`

Note: never merge `upstream/master` into `master` or `saurabh-patches`. This prevents issues when the upstream repo force-pushes to commits that were already merged.

### Fixing TCC permissions when doing local dev
1. Delete existing AltTab.app binary
2. Remove TCC record from Privacy & Security and then also run `sudo tccutil reset All com.lwouis.alt-tab-macos`
3. Copy the new AltTab.app into /Applications (but don't open it yet)
4. Manually add the new AltTab.app to Accessibility in Privacy & Security
5. Open the new AltTab.app

