---
name: arma-setup
description: Install, launch and set up the Arma browser on a Mac - download or build it, start it without taking the screen, put the `arma` command on the PATH, make Spaces, choose the default engine and search, import from another browser, install extensions, and keep it updated. Use when someone is getting Arma running for the first time, moving to it from another browser, or configuring a fresh install.
---

# Set up Arma

Arma is a Mac browser with a sidebar of tabs, Spaces that keep accounts apart, and two
engines, Chromium and WebKit. It needs Apple silicon and macOS 15.2 or later.

## Install

1. Download the latest **Installer** disk image from
   <https://github.com/devops-senpai/Arma/releases/latest>.
2. Open it and drag Arma onto **Applications**. Keep it there: the updater expects one
   stable place.

Arma is signed and notarized, so it opens like any Mac app. To build from source instead,
follow "Build Arma" in the repository README.

Downloading and installing software is the person's decision. Ask before you download the
installer for them.

## Start it

```sh
open -a Arma                                      # in front
open -g --env CREST_BACKGROUND_LAUNCH=1 -a Arma   # behind the app in use
```

The first launch shows **Arma Setup**: pick a look, bring data in from another browser,
and choose a default browser. A person does this part; it cannot be answered from the
terminal.

## Put the `arma` command on the PATH

In Arma, open the command palette (**Command-L**), type `@cli`, and choose the install
row. It links the command into `~/.local/bin` or `~/bin`. To do it by hand:

```sh
mkdir -p ~/.local/bin
ln -s /Applications/Arma.app/Contents/Helpers/arma ~/.local/bin/arma
```

Everything below works without the link, by calling
`/Applications/Arma.app/Contents/Helpers/arma` in full. Check that it reaches the app:

```sh
arma space list
```

## Spaces: one per account boundary

A Space is a separate browsing profile: its own sign-ins, cookies, history, passwords,
extensions and tabs. The same site can be signed in to different accounts in Work and
Personal. Set up one Space per boundary the person keeps, such as Work and Personal.

- **Add a Space**: Settings (**Command-,**), then **+** beside the Spaces heading.
- **Sub-Spaces** share one Space's sign-ins, history, passwords and extensions while each
  keeps its own tabs and look. Right-click a Space in Settings and choose New Sub-Space.
- The order matters: **Control-1** through **Control-9** pick Spaces by position.

Spaces are made in Settings. From the terminal you can read and switch them:

```sh
arma space list
arma space switch Work
```

## Settings from the terminal

```sh
arma settings list                    # every key, its value, what it accepts, where it is in Settings
arma settings list --section engines
arma settings get engines.default
arma settings set engines.default webkit
arma settings reset engines.default
```

The choices most installs want to make:

| Key | What it decides |
| --- | --- |
| `engines.default` | Chromium or WebKit for new pages |
| `general.startup.when-opens` | open the last active tab, or the Start Page |
| `general.startup.default-space` | the Space a new window starts in |
| `search.default-engine`, `search.private-engine` | where the command palette searches |
| `appearance.mode` | light, dark, or follow the system |
| `appearance.sidebar-side` | the sidebar on the left or right |
| `links.external.open-in` | where a link from another app lands |
| `general.translation.offer`, `general.translation.automatic` | page translation |
| `space.browsing.archive-tabs` | how long a Space keeps unpinned tabs before archiving them |
| `space.privacy.keep-history` | how long a Space keeps history |

Keys that start with `space.` belong to one Space: add `--space <name>`. Read
`arma settings list` for the values each key accepts rather than guessing them.

## Engines

New pages open in Chromium unless the default says otherwise. Each engine keeps its own
cookies for a Space, so a sign-in in one does not carry to the other.

```sh
arma site engine netflix.com webkit      # always open this site in WebKit
arma site engine example.com default     # remove the rule
arma tab engine current webkit           # move one page
```

Chromium runs Chrome Web Store extensions. WebKit has Reader and plays FairPlay video.

## Bring data in

- **During setup, or later**: Settings › Advanced › **Import from Another Browser…**
  opens a review of what each browser offers: Arc, Zen, Chrome and other Chromium
  browsers, Safari, Firefox. The person chooses what arrives and into which Space.
- **From a file**:

```sh
arma settings export ~/Desktop/arma-backup.json     # Spaces, settings, tabs, history
arma settings export ~/Desktop/bookmarks.html --format bookmarks
arma settings import ~/Desktop/arma-backup.json --yes   # adds after what is there; replaces nothing
```

A browser-data file holds no passwords, cookies or extensions.

## Extensions

```sh
arma extension install <web-store-id-or-address> --space Work   # the person reviews it in Arma
arma extension list --space Work
arma extension disable <extension> ; arma extension remove <extension>
```

An install from the Chrome Web Store finishes only after the person reviews it in Arma.

## Look and feel

```sh
arma theme list
arma theme use "Catppuccin Mocha" --space Work
arma settings set appearance.mode dark
```

See the `arma-themes` skill to make a theme.

## Updates

Arma checks for signed updates about once an hour and shows the answer in a card at the
bottom of the sidebar. Type `@update` in the command palette to check now. Settings ›
About chooses the channel and turns automatic checks on or off.

## Check the install

```sh
arma space list                          # Spaces answer
arma settings get engines.default        # settings answer
arma tab open https://example.com --space <space> --background
arma tab list --space <space>            # the tab is there
```

Close the test tab when done: `arma tab close <id>`.
