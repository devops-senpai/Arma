# How Arma names itself

Arma is Crest with its own name, identifier, icon and update feed. It changes
as few of Crest's lines as it can, so syncing with upstream needs no hand
work: Crest's file, type, target and module names stay, its source strings stay
as Crest wrote them, and the name comes from configuration and a build phase.
This page lists where each name lives.

## What is a name here

| Thing | Value | Where |
| --- | --- | --- |
| Product name | `Arma` | `PRODUCT_NAME` of the Mac and mobile app targets and the two `TEST_HOST` paths in `project.yml`; `CFBundleDisplayName` and `CFBundleName` in `CrestMac/Configuration/Crest-Info.plist` and `CrestMobile/Configuration/CrestMobile-Info.plist`; `ProductIdentity.name` |
| Bundle identifier | `com.senpaimedia.arma` | `bundleIdPrefix` and every `*_BUNDLE_IDENTIFIER` in `project.yml`; `ProductIdentity.bundleIdentifier` (the Keychain namespace follows it); `Config/DeveloperIDExportOptions.plist`; the packaged identifiers in `Scripts/control-plane/package-chromium-host.py` and `package-apple-core.py`; `Scripts/validate-identity.sh` |
| iCloud container and keychain group | `iCloud.com.senpaimedia.arma` | the four entitlements files and both Info.plists |
| Data folder | `~/Library/Application Support/Arma` | follows `ProductIdentity.name`; `CrestAgents/AgentSocketLocation.swift` names the same folder for the agent socket |
| Apple team | `U5WBZPZ4X7` | `project.yml`, `Config/DeveloperIDExportOptions.plist`, `Scripts/install-local-macos-release.sh` |
| Update feed and key | `raw.githubusercontent.com/devops-senpai/Arma/updates/…` | `SUFeedURL` and `SUPublicEDKey` in `Crest-Info.plist`, `BrowserSoftwareUpdateChannel.swift`, `CrestTests/BrowserSoftwareUpdateTests.swift` |
| Repository links | `github.com/devops-senpai/Arma` | `BrowserAboutInformation.swift` (feedback, issues, import requests, roadmap), `Scripts/install-local-macos-release.sh` |
| Terminal and agent helper | `Contents/Helpers/arma` | the helper target's `PRODUCT_NAME` in `project.yml`, `BrowserAgentsSettingsPane.swift`, `BrowserAgentPeer.swift`, `package-chromium-host.py`, and the MCP `serverInfo` in `AgentHelperEndpoint.swift` |
| Engine pages | `arma://` | the Chromium engine binding and overlay (`feat(chromium)`); changing it changes the engine key |

Identifiers stay Crest's whatever the product is called: modules and targets
(`Crest`, `CrestShared`, `CrestMac`…), `Crest.xcodeproj`, `Crest-Info.plist`,
log subsystems, queue labels, content-world and notification names, defaults
keys and persisted format identifiers such as
`com.pauldavis.crest.browser-data`. They are not copy, and renaming them makes
upstream merges conflict.

## Interface strings

Crest's interface strings are keys in `CrestShared/Resources/Localizable.xcstrings`.
The Brand strings build phase of the Mac app, the iOS app and the Chromium host
framework (`project.yml`'s app templates) runs `Scripts/fork/brand-strings.py`
after the resources are copied. For every catalog key that names Crest, and
every key the target's compiler extracted that the catalog has not caught up
with, it writes the key into each language's compiled `Localizable.strings` (and
rewrites `.stringsdict`) with Arma in place of Crest. Keys stay Crest's, so the
Arabic translations stay attached and Crest's new strings are covered without a
change here.

"Crest" is also heraldry: a Space wears a crest, drawn in Crest Studio. The
script's `HERALDRY` phrases keep the word: the bare **Crest** icon style,
**Crest Studio** and its step, **Layered Crest**, **Edit Crest…**,
**Crest colors**, **Crest preview**, the **Crest branding** preview,
**Make Crest your own** and **Choose Crest under Emblem**. Add a phrase there
when Crest adds another heraldic string.

Strings that never pass through localization keep Crest unless Arma edits them
in place. Arma does so only where a person sees them in the app: the default
icon's title in the icon pickers, the default browser status, the setup and
Getting Started wordmarks, the update and dialog messages, password and sync
errors, and the names of exported files. Messages written for agents (MCP tool
descriptions and failures) keep Crest's words.

Check a build with
`python3 Scripts/fork/brand-strings.py --check <app>/Contents/Resources`.

## Icon

`Scripts/fork/generate-arma-icons.py` draws Arma's banner
(`Brand/AppIcons/ArmaHonor.svg`) in one color per palette into Crest's own icon
files: each `CrestShared/Resources/CrestIcon/Crest*.icon` gets
`Assets/ArmaMark.svg` and an `icon.json` that draws it, and each
`Crest*Preview`, `Crest*DockLight` and `Crest*DockDark` image set in
`AppIconPreviews.xcassets` gets its PNGs redrawn in place. Crest's names,
image sets and asset-catalog settings stay, so nothing that loads an icon
changes. Run it after changing the banner or a color; it needs Icon Composer's
`ictool` from the installed Xcode. The start page mark (`CrestStartPageMark`)
shows `AppIconPreviews.xcassets/ArmaMark.imageset`, a tight crop of
`Brand/Arma.svg`.

## Heraldry and setup

Arma's own arms live beside Crest's in the core: `SpaceHouse.Arma`, the
`CrestBackplate.Flag` guidon, the `Sparrow` and `Crane` charges and the Arma
and Macchiato tinctures, appended so stored names keep their meaning. New
Spaces wear `SpaceHouse.NewSpaceLook`, Arma's crest over their accent's house
colors. Galleries offer Arma's house, guidon and birds first
(`SpaceHouse+Arma.swift`, `CrestSymbol.selectable`). Setup plays on
`BrowserOnboardingArmaBackdrop`, and its welcome shows Arma's mark in
`SpaceBranding.armaWelcome`.
