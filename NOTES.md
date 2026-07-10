# Ice fork - build notes

Plain-English log of what I changed and why. Newest first. No corporate speak.

Ground rules for this fork (personal use only, not shipping):
- Additive changes only. Don't touch the menu-bar hide/show/rearrange core unless it's strictly unavoidable, and if it is, stop and ask first.
- Small commits, one logical change each, plain-English messages.
- Never commit secrets or my signing team to a public place.

---

## 2026-07-10 - v1.3: monitor fixes

- Fixed the bar icons rendering at the wrong size when opening Cherry's bar on a monitor with a different scale than the MacBook screen. Root cause: the icon capture assumed a pixel density instead of reading the real one, and cached the mistake forever. Now it derives the scale from the actual pixels.
- New toggle in Settings, General: "Show everything on external displays". Plug in a monitor and every menu bar item expands into the real menu bar; unplug and the hidden format comes back. It's per-screen while docked: interacting on the monitor expands/collapses in the actual menu bar, interacting on the MacBook screen still uses the floating bar (the notch eats items up there). Auto-rehide pauses while it's active. One macOS reality: the menu bar is mirrored, so expanded items show on the laptop's bar too while docked.

---

## 2026-07-02 (later) - Notarized, plus a prettier installer

- Cherry is now signed with a proper Developer ID and notarized by Apple. Fresh downloads just open. No more "could not verify" scare dialog, no Open Anyway dance (which is the only bypass left, macOS 26 killed right-click > Open).
- `make-dmg.sh` does the whole run now: build, re-sign for distribution, pretty drag-to-install window (2x retina background), notarize, staple. One command.
- One-time setup that unlocked it: Developer ID Application cert via Xcode, plus a `Cherry-Notary` keychain profile for notarytool.
- Also built a `cherry-release` Claude skill, so shipping the next version is just "ship v1.2" in a chat.

---

## 2026-07-02 - Went public: v1.1, landing site, Dock toggle

Reversed the "keep it private" call from yesterday. Restored full GPL attribution first (Jordan Baird credited in LICENSE + README, marked as a fork of Ice), so publishing is clean.

- Repo is public now. Cut v1.0, then v1.1.
- Landing site up at https://brendanrong.github.io/Cherry (GitHub Pages from /docs). Download button points at /releases/latest/download/Cherry.dmg so it always grabs the newest release, no site edit needed per release.
- Added a "Show Dock icon" toggle (Settings > General). Additive only, just flips NSApp activation policy between .regular and .accessory. Didn't touch the menu-bar core.
- Bumped MARKETING_VERSION to 1.1 and made make-dmg.sh output a version-less Cherry.dmg, so the permanent download link keeps working on every release.
- Updater gotcha: the built-in Sparkle updater points at a dead feed (placeholder URL), so in-app "Check for Updates" errors out. Left it alone, not worth wiring real auto-updates for a personal app. To update: grab the new DMG from the site.
- Cowork sandbox note: it can't delete files in the repo, so it left a stray .git/index.lock and a build Cherry.dmg behind. Added *.dmg to .gitignore. Clean up with: rm .git/index.lock Cherry.dmg

---

## 2026-07-01 - Personal DMG (keeping Cherry private)

- Decided to keep Cherry personal, not publish it. It's a GPL-3 fork and I stripped the original author's attribution; distributing publicly would mean restoring credit + open-sourcing under GPL. Not worth it for a personal tool. Personal use = zero obligations.
- Added `make-dmg.sh`: builds Cherry (Release) and packages a drag-to-install DMG on my Desktop, for installing on my own Macs.

---

## 2026-07-01 - On private GitHub, clean history

- Pushed to github.com/brendanrong/Cherry (private). Single clean history: one "Cherry" root commit + the signing commit, on `main`. Deleted the old `macos-26` branch that carried Ice's full ~1,216-commit history and the original author's commits.
- `upstream` still points at jordanbaird/Ice locally (invisible on my GitHub) if I ever want to reference it.
- Minor: my remote uses lowercase `cherry`; GitHub's canonical is `Cherry`, so pushes show a harmless "repository moved" redirect. Optional fix: `git remote set-url origin git@github.com:brendanrong/Cherry.git`

---

## 2026-07-01 - Signing: switched from ad-hoc to my Apple team

- Set DEVELOPMENT_TEAM = VTMKE23N5G (my team) + automatic signing on both targets; removed the ad-hoc "-" identity.
- Why: ad-hoc gave the app a new identity every build, so macOS re-asked for Accessibility/Screen Recording each time. A stable cert = grant once, sticks across rebuilds.

---

## 2026-07-01 - Full rename to Cherry + repo cleanup

- Renamed the Xcode project, target, scheme, and source folder from Ice to Cherry. `cherry.xcodeproj` and the `Cherry/` source folder now have zero "Ice". Internal code symbols (IceApp, IceBar...) left as-is - invisible to a user, pointless risk to rename.
- Recovered from a half-finished Xcode rename that left a broken scheme (it pointed at the old empty Ice.xcodeproj) plus a duplicate project. Fixed the scheme's container, removed the shell, deleted a stray `main` branch that pointed at old Ice history.
- Final step: squash the whole git history into one clean "Cherry" commit and force-push, so the private repo shows no Ice history and no original-author commits.

---

## 2026-07-01 - Cleanup: removed dead migration code

- Deleted the 490-line `MigrationManager` (Migration.swift) and its one call in `AppDelegate`. It only upgraded *old Ice* settings; a fresh Cherry has none, so it was pure legacy (the maintainer had flagged it "should be completely redone").
- Left Migration.swift as an empty stub (Claude can't delete files). Safe to `rm Ice/Utilities/Migration.swift` on my Mac.
- Harmless leftovers kept: the `hasMigrated*` keys in Defaults.swift and the `ControlItemDefaults.migrate` helper (now unused, but removing them is pointless risk).
- Rebuild to confirm it compiles (self-contained removal, low risk).

---

## 2026-07-01 - Rebrand to "Cherry" (part 4: app icon)

- Generated a cherry app icon (two glossy cherries, green leaf, soft pink rounded-square background) and overwrote all 10 sizes in `Ice/Resources/Assets.xcassets/AppIcon.appiconset`. Contents.json unchanged.
- Clean placeholder made in code; easy to swap for a designed one later.

---

## 2026-07-01 - Rebrand to "Cherry" (part 3: ownership -> Brendan Rong)

**What:** replaced the previous owner everywhere it's visible:
- Copyright -> "© 2026 Brendan Rong" (shows on the About page).
- About links: Contribute / Report a Bug -> github.com/brendanrong/Cherry; Support -> github.com/sponsors/brendanrong.
- Sparkle update feed -> brendanrong.github.io placeholder (no longer points at the old owner's; effectively no auto-updates, which is fine).
- Docs (README, FREQUENT_ISSUES, CODE_OF_CONDUCT): upstream -> brendanrong, CoC contact email -> placeholder.

**Also done:**
- LICENSE copyright changed to "Copyright (C) 2026 Brendan Rong" / "Cherry". For later: if I ever distribute this, GPL expects the original author's notice restored.
- Scrubbed the previous author's name from these notes too.
- The new URLs are placeholders (dead until I make those pages); they just drop the old owner.

---

## 2026-07-01 - Rebrand to "Cherry" (part 2: product rename + text scrub)

**What:**
- Product renamed: app now builds as `Cherry.app` (was Ice.app). Changed PRODUCT_NAME (app target only) plus the scheme's BuildableName. Helper stays MenuBarItemService.xpc.
- Scrubbed every user-facing "Ice" -> "Cherry": right-click menus ("Cherry Settings…", "Quit Cherry"), the permissions window, the About page, the Settings sidebar title, and the General/Hotkeys panes ("Use Cherry Bar", "Show Cherry icon", "Enable the Cherry Bar", location descriptions), plus the "cannot edit/arrange" messages.

**Intentionally left as "Ice" (invisible to a user; changing them breaks things):**
- UserDefaults keys (ShowIceIcon, IceIcon, CustomIceIconIsTemplate) and migration keys - renaming these wipes saved settings.
- Asset image names (IceCubeStroke/Fill) and a few internal identifiers (Ice.ControlItem.*) - not shown in the UI.
- Log messages, code comments, Swift symbols (IceBar, IceApp...), and the upstream GitHub URL.

**Cleanup:** left a stray `.cherry_probe` file in the repo root from a write test (my sandbox can create/overwrite but not delete). Safe to `rm .cherry_probe` on my Mac.

---

## 2026-07-01 - Rebrand to "Cherry" (part 1: identity + name)

**What:** started making this my own app, "Cherry".
- App bundle id: old upstream id -> `com.brendanrong.Cherry`
- Helper bundle id: `...Ice.MenuBarItemService` -> `...Cherry.MenuBarItemService`
- XPC connection name updated to match the new helper id (`Shared/Services/MenuBarItemService.swift`)
- Display name set to "Cherry" (`CFBundleDisplayName`), so Finder, permission dialogs, and login items show Cherry.

**Why it matters beyond cosmetics:** new bundle id = macOS treats it as a separate app from the installed Ice, so no more shared-permission confusion. Fresh, clean identity.

**Still to do:** in-app text still says "Ice" (menus, About, permissions window) - that's part 2. Cherry icon - part 3. App file is still `Ice.app` (display name is Cherry); can rename the file later.

**Didn't touch:** internal code names (IceBar, IceApp, etc.) and UserDefaults keys (IceIcon etc.) - renaming those is pointless risk.

---

## 2026-07-01 - Made it build without an Apple account (signing fix)

**Problem:** build kept failing on signing. Both targets were pinned to the maintainer's Apple teams (`K2ATHQPJDP` at project level, `VTMKE23N5G` on the Ice app) and demanded an "Apple Development" certificate. My machine can't use any of that.

**Fix:** switched both targets to "Sign to Run Locally" in `Ice.xcodeproj/project.pbxproj`: DEVELOPMENT_TEAM emptied, CODE_SIGN_STYLE = Manual, CODE_SIGN_IDENTITY = "-" (ad-hoc). Entitlements were empty, so no team is needed. Project-config change only, not the fragile core.

**Trade-off:** ad-hoc signing means macOS may re-ask for Accessibility/Screen Recording after a rebuild. If I want it rock-solid as a daily driver, I'll set my own Apple team later instead.

---

## 2026-07-01 - Switched to the macos-26 branch (Step 3 finding)

**Why:** I'm on macOS 26. On `main`, Ice was broken: nothing showed in the Hidden section and tapping the top of the screen crashed it. `main` hasn't had a code change since June 2025, before macOS 26 shipped.

**The finding:** the maintainer's real macOS 26 work lives on the `macos-26` branch. It's 77 commits ahead of main, 184 files changed, ~10k new lines. It adds a separate helper process (`MenuBarItemService`) and rewrites the menu bar event handling for macOS 26. `main` is stale on my OS.

**Decision:** build from `macos-26`, not `main`. It's a maintainer dev branch (version 0.11.13-dev.2a), so expect rough edges, but it should actually work on 26.

**Gotcha:** Claude tried to switch branches from its sandbox but couldn't overwrite files in my repo (a permission wall). The switch half-applied, so I finish it with git commands on my own Mac. Lesson for this project: git commands run on my machine, Claude edits code files directly.

---

## 2026-07-01 - Day 0: baseline, getting it to build

**What this is:** cloned the upstream Ice project to build on it for my own use.

**Starting point:** `main` @ `11edd391`. Last actual code change was 2025-06-06 ("Update project files to latest Xcode"). Newest tag is `0.11.13-dev.2` (Sept 2025). There's also a `macos-26` branch (Sept 2025) that looks like the maintainer's macOS 26 work.

**Requirements:** macOS 14+, Xcode, Swift 5. No CocoaPods or Carthage. Five Swift Package Manager deps that Xcode fetches automatically on first build:
- AXSwift (Accessibility API wrapper - fragile core stuff)
- Sparkle (auto-updater)
- Ifrit (fuzzy search)
- CompactSlider, LaunchAtLogin-Modern (UI bits)

**One build change needed before it'll run:** the project is signed with the upstream Apple team (`K2ATHQPJDP`). Switch the signing team to mine in Xcode > Signing & Capabilities. Config fix, not a code change.

**Runtime:** Ice needs Accessibility permission (and probably Screen Recording) granted in System Settings after first launch, or the hide/show won't work. Not sandboxed (menu bar managers can't be).

**Code changed so far:** nothing. This is the baseline.

---

## How Ice is built (my quick mental map)

- `AppState.swift` = the brain. Creates every "manager" and boots them.
- Menu bar items handled by 4 files: `MenuBarManager` (overall state + 3 sections), `MenuBarSection` (Visible / Hidden / Always-Hidden buckets), `ControlItem` (the 3 status items Ice plants), `MenuBarItemManager` (the 1,671-line beast that moves/rearranges items).
- **Fragile do-not-touch:** `Bridging/` (undocumented Apple window-server APIs), `MenuBarItemManager` (item moving), Accessibility + `Events/EventTap.swift`, and a `Swizzling/` runtime hack.
- **Safe to build on:** `Settings/`, `UI/`, `MenuBar/Appearance/`, `Hotkeys/`.
