<div align="center">
  <img src="Brand/Arma.png" width="160" alt="Arma's logo: a white bird on a navy guidon with a red stripe and a gold laurel">
  <h1>Arma</h1>
  <p><strong>An open source browser for Mac, iPhone, and iPad.</strong></p>
  <p>Built with SwiftUI, running Chromium and WebKit on Mac, with separate Spaces for different parts of your life.</p>
  <p><a href="https://github.com/devops-senpai/Arma/releases/latest"><strong>Download Arma for Mac</strong></a> · Apple silicon, macOS 15.2 or later</p>
  <p>
    <a href="https://github.com/devops-senpai/Arma/actions/workflows/ci.yml"><img alt="Build Arma" src="https://github.com/devops-senpai/Arma/actions/workflows/ci.yml/badge.svg"></a>
    <a href="LICENSE"><img alt="MPL-2.0 license" src="https://img.shields.io/badge/license-MPL--2.0-315f93"></a>
  </p>
  <img src="Brand/Readme/collage.jpg" alt="Arma windows fanned out: Arc Sky, Catppuccin Latte, a four-page Split View, Catppuccin Macchiato and JellyFish">
</div>

Arma is a fork of [Crest](https://github.com/pauljoda/Crest) by Paul Davis.
It carries Crest's main branch plus fixes, speedups and features that are
not upstream. Arma is not affiliated with or endorsed by Crest or Paul
Davis. The
user guides live in this repository under `HelpCenter/docs/`.

## A quick tour

### Themes

Arma ships with themes for every kind of person: **Arc Sky** and **Arc Blush** for anyone
coming from Arc, and **Catppuccin** Latte, Latte / Mocha, Macchiato, Mocha
and Frappé for coders. Arma starts in Catppuccin Latte. Any theme can also put a picture of your own behind the
tabs; **JellyFish** ships as an example of one. Setup offers them
beside the **Heraldic** and **Modern** looks, and Settings › Themes edits every
color, the dark look and the background picture, with a live preview of the
window and its command palette.

| | |
|---|---|
| ![Arc Sky](Brand/Readme/theme-arc-sky.jpg) | ![Arc Blush](Brand/Readme/theme-arc-blush.jpg) |
| **Arc Sky** | **Arc Blush** |
| ![Catppuccin Latte](Brand/Readme/theme-catppuccin-latte.jpg) | ![Catppuccin Latte / Mocha](Brand/Readme/theme-catppuccin-latte-mocha.jpg) |
| **Catppuccin Latte** | **Catppuccin Latte / Mocha** |
| ![Catppuccin Macchiato](Brand/Readme/theme-catppuccin-macchiato.jpg) | ![Catppuccin Mocha](Brand/Readme/theme-catppuccin-mocha.jpg) |
| **Catppuccin Macchiato** | **Catppuccin Mocha** |
| ![Catppuccin Frappé](Brand/Readme/theme-catppuccin-frappe.jpg) | ![JellyFish, with a picture behind the tabs](Brand/Readme/theme-jellyfish.jpg) |
| **Catppuccin Frappé** | **A picture of your own** (JellyFish) |

![Settings › Themes editing Arc Blush: the theme list, a live preview of the window and its command palette, the sidebar's colors and its pattern](Brand/Readme/settings-themes-arc-blush.jpg)

![Settings › Themes editing Catppuccin Macchiato: the theme list, a live preview, and the sidebar's pattern, colors, intensity and text](Brand/Readme/settings-themes-macchiato.jpg)

⌘Z and ⇧⌘Z on the Themes page undo and redo your edits.

A Space picks its theme; its crest stays its own. The Crest Studio shapes it,
starting from Arma's own **Guidon**, its bird and the Crane.

![A Space's Appearance settings: its theme, its crest large with its colors, and the Crest Studio's shapes](Brand/Readme/crest-studio.jpg)

Setup starts with the look: the Heraldic and Modern looks, or any theme Arma
ships. Then each Space gets its crest, from a starting house through its
shape, field, band, emblem, border and finish.

| | |
|---|---|
| ![Setup's Pick your look page: Heraldic, Modern and every theme Arma ships](Brand/Readme/setup-pick-your-look.jpg) | ![Setup's Make it yours page: the Space's crest and its shape, field, band, emblem, border and finish](Brand/Readme/setup-make-it-yours.jpg) |
| **Pick your look** | **Make it yours** |

### Split View, tiled

Keep up to four live pages in one view: side by side, stacked, or in a grid.
Drop a tab on an edge of a page to tile it there, or pick an arrangement from
the split's menu, and drag the bars between pages either way.

| | |
|---|---|
| ![Three pages side by side](Brand/Readme/split-three.jpg) | ![Four pages in a grid](Brand/Readme/split-grid.jpg) |
| **Three across** | **Four in a grid** |

### A window of its own, and the way back

Right-click a tab and choose **Open in New Window** to open it in a window of
its own; the tab stays in the main window, unloaded, so closing the new window
by mistake loses nothing. Dragging a tab out of the window moves it, and **Open
Link in New Window** on a page does the same for a link. That window lists only
its own tabs, so its sidebar says how to get back: **Return to Main Window**
moves every tab back into the Space's main window, each to the folder or
section it left, replacing the unloaded tab it came from, and closes the
window.

<p align="center">
  <img src="Brand/Readme/return-to-main-window.jpg" width="720" alt="A window holding one tab, with Return to Main Window under the Space's name in its sidebar">
</p>

### Three engines: Chromium, WebKit and Servo

> [!WARNING]
> **Servo is temporarily disabled.** It crashed the browser too often, so
> releases leave it out until it is stable. Tabs, website rules and defaults
> set to Servo open in Chromium meanwhile. The Servo examples below work again
> once it returns.

Every page runs in the engine you choose: **Chromium** (the default, with
Chrome Web Store extensions), **WebKit** (Reader, translation, FairPlay video)
or **Servo**, the independent engine written in Rust. Set a default in
Settings › Engines, give a website its own engine, or move one page:

```sh
arma site engine youtube.com webkit          # YouTube always opens in WebKit
arma site engine servo.org servo             # servo.org opens in Servo
arma tab open https://example.com --engine servo
arma site list                               # every site with its own engine
```

To move one tab, list the tabs, take its ID from the first column, and give
that ID to `arma tab engine`:

```console
$ arma tab list --space Work
ID        SPACE  WHERE   FOLDER  ENGINE    TITLE
6c1124f0  Work   open    -       webkit    Jellyfish - Wikipedia
7194b03d  Work   open    -       servo     Servo, the embeddable web engine
29c94624  Work   open    -       chromium  devops-senpai/Arma

$ arma tab engine 6c11 chromium              # the first few characters are enough
```

### Passwords

Each Space's Passwords settings choose how often showing or copying a saved
password asks you to authenticate, how long the Save password? prompt stays,
whether private windows suggest passwords and the command line may read them,
its saved passwords, each with an email, notes, a category and whether it
covers the site's subdomains, and the websites it never offers to save on.

![Settings › Passwords: Use Arma Passwords, Sync with iCloud Keychain, Ask to authenticate, Close save prompt after, private windows, command-line access, the saved passwords with their subdomains, and Never Save Passwords On with Include subdomains](Brand/Readme/settings-passwords.jpg)

Add Password keeps a website's email, username and password together with a
category and up to 2 KB of notes, and Generate, here or on a sign-up page,
makes a password to the length and kinds of character you choose.

![New Password: website, Include subdomains, category, email, username, password with Generate, and notes up to 2,048 bytes](Brand/Readme/passwords-add-generate.jpg)

Type `@passwords` in the command palette, pick a login, and copy its username,
password or website, fill it into the page, or open the site.

![The command palette inside a saved login: Copy Username, Copy Password, Copy Website, Fill on This Page and Open Website](Brand/Readme/palette-passwords.jpg)

From the terminal, unlock one Space's passwords with Touch ID or your Mac
password once its Passwords settings allow command-line access. The session
lasts an hour at most and ends when you lock it, quit Arma, or the Mac sleeps
or locks:

```sh
eval "$(arma passwords unlock --space Work)"     # asks for Touch ID, sets ARMA_SESSION
arma passwords list --category Work
arma passwords get password gitlab.com | pbcopy
arma passwords create example.com --username me@example.com --generate --length 24
pbpaste | arma passwords edit example.com --password-stdin
arma passwords lock
```

### Command palette `@` actions

Type an `@` scope in the command palette and press **Space** or **Tab** to
search or act within it. Arma adds seven scopes to the five Crest has, and
keeps all of Crest's:

| Type | What it offers | In |
|---|---|---|
| `@passwords` | The Space's saved logins by site and username. **Return** on one shows Copy Username, Copy Password (after you authenticate, and the clipboard clears it after 60 seconds), Copy Website, Fill on This Page and Open Website; **Escape** goes back. The first row opens the Space's Passwords settings, and the next pauses or resumes Arma's password prompts on the tab on screen. | Arma only |
| `@themes` | Your saved themes; pick one to dress the Space on screen. | Arma only |
| `@extensions` | Chromium's extensions page, the Chrome Web Store, and each Space's extension settings. | Arma only |
| `@engine` | Move the page to another engine, or always open its site there. | Arma only |
| `@developer` | The page's Web Inspector and developer toolbar. | Arma only |
| `@cli` | Install the `arma` command in `~/.local/bin` or `~/bin`, or copy the line to run yourself. | Arma only |
| `@update` | Check for a new version of Arma; the answer shows in the sidebar. | Arma only |
| `@tabs` | The Space's open tabs. | Arma and Crest |
| `@saved` | Pinned and saved tabs. | Arma and Crest |
| `@history` | Pages you visited in the Space. | Arma and Crest |
| `@actions` | Browser commands, such as New Tab, Split View or Settings. | Arma and Crest |
| `@spaces` | Your Spaces, to switch to one. | Arma and Crest |

![The command palette in the @themes scope, listing every saved theme to put on the Space](Brand/Readme/palette-themes.jpg)

### The `arma` command line

`arma` lives inside the app (`/Applications/Arma.app/Contents/Helpers/arma`)
and drives the running browser. Every command takes `--json` for scripts.

![arma --help in a terminal, listing every section the command line manages, passwords included](Brand/Readme/terminal-arma-help.jpg)

```sh
arma space list                              # Spaces; * marks the one shown
arma space switch Work
arma tab open https://news.ycombinator.com --space Work
arma tab list --space Work                   # each tab's <tab-id>, placement, engine
arma split create <tab-id> <tab-id> <tab-id> # three tabs in one Split View
arma split arrange <tab-id> grid             # two-across, three-across, grid …
arma archive search invoice --since 2w        # closed tabs, ready to restore
arma archive restore <entry>
arma theme list                              # saved themes; * the shown Space's
arma theme use "Arc Sky" --space Personal
arma theme edit "Catppuccin Macchiato" --folder-color "#a581ff"
arma crest set --shape guidon --band pale --emblem sparrow --border laurel
arma window tile left
arma settings set appearance.mode dark
arma page <tab-id> text                      # read a page (Settings › Agents)
eval "$(arma passwords unlock --space Work)"  # Touch ID, then an hour of access
arma passwords list --site github.com
arma passwords get password github.com | pbcopy
```

A `<tab-id>` is the start of an ID from `arma tab list`, four characters or
more, such as `6c11`; `current` names the tab the front window shows.

Run `arma help`, or `arma <section> help`, for every section: space, tab,
window, folder, split, command, page, extension, history, download,
settings, site, automation, theme, crest and passwords. `arma passwords`
reaches only a Space that allows it in Settings › Space › Passwords ›
Allow command-line access.

### Testing frameworks

Settings › Automation (or `arma automation`) lets Playwright, Puppeteer,
Selenium, WebdriverIO, Katalon and TestCafe drive Arma's Chromium tabs over a
local DevTools port, limited to one Space's profile or an empty Ephemeral one,
and to the tabs they open or existing tabs too. The page shows the setup for
each tool.

![Settings › Automation: allow testing frameworks, the profile and tabs they reach, the port, and setup for Playwright, Puppeteer, Selenium, WebdriverIO, Katalon and TestCafe](Brand/Readme/settings-automation.jpg)

```sh
arma automation on --profile Work --tabs opened --port 9222
arma automation restart
```

```js
// Playwright
import { chromium } from "playwright-core";
const browser = await chromium.connectOverCDP("http://127.0.0.1:9222");
const page = await browser.contexts()[0].newPage();
await page.goto("https://example.com");
```

```js
// Puppeteer
import puppeteer from "puppeteer-core";
const browser = await puppeteer.connect({ browserURL: "http://127.0.0.1:9222", defaultViewport: null });
const page = await browser.newPage();
await page.goto("https://example.com");
await browser.disconnect(); // browser.close() would quit Arma
```

```python
# Selenium, with ChromeDriver matching Arma's Chromium
from selenium import webdriver
options = webdriver.ChromeOptions()
options.debugger_address = "127.0.0.1:9222"
driver = webdriver.Chrome(options=options)
driver.get("https://example.com")
```

## What Arma adds

Everything below is in Arma and not in upstream Crest.

### Features

- **Themes.** Settings › Themes keeps a library of themes: make, duplicate, rename, delete, import and export them, and edit each one's colors, dark look and background picture, with a live preview of the window and command palette, and ⌘Z undoes an edit; a change updates every Space wearing it. Themes go further than upstream's Appearance page: folder colors, backs, outlines and a highlight color and opacity for open folders, sidebar text and a secondary text color, the command palette's tint, opacity and text, and the background, text, secondary text, accent and button colors of popovers such as Site Controls, each with its own dark look. A background picture sits behind the sidebar and window, placed, sized, repeated, tinted and blurred as you like, with a translucent backing behind tabs so they stay legible. Arma ships Arc Sky, Arc Blush, Catppuccin Latte / Mocha, Macchiato, Mocha and Frappé, JellyFish and Textured, offered beside Heraldic and Modern on setup's Pick your look page, and Heraldic and Modern as themes too. A Space picks its theme beside its crest, from the Themes list, or with `@themes` in the command palette, and its crest keeps its own colors. New Spaces start with Arma's own gold and red Guidon crest, and the Crest Studio offers the Guidon, its bird and the Crane first.
- **Extensive CLI.** `arma` controls the running browser from the terminal: Spaces, tabs (open in a chosen engine, pinned, saved, in a folder or at a place in the list, with a title of your own; move, pin, save, rename), windows (move, resize, tile), folders (create, move, file tabs, each at a chosen place), Split View, any menu command, extensions, history, the archive of closed tabs (search, restore, delete, clear), downloads, settings (get, set, export, import), site rules, themes and crests, and saved passwords (`arma passwords`, after a Touch ID unlock that lasts an hour at most), with `--json` for scripts. Theme and crest changes show in the running app right away. `arma page` reads and drives a page (text, snapshot, screenshot, click, type, JavaScript) once Settings › Agents › Command-line page control is on.
- **Tiled Split View.** Drop a tab on the top or bottom edge of a page to stack it there, on the outer edge of the split to give it the full height or width, or on the middle of a page to swap the two; make quadrants from any of these. The split's menu has ready-made arrangements for two, three and four pages, a tab's menu can pick its card up to move with the pointer (⇧⌘-drag does the same), and the bars between pages drag either way; each window keeps the sizes.
- **Open in New Window.** Right-click a tab and choose Open in New Window to open it in a window of its own while the tab stays, unloaded, in the main window, or right-click a link on a page and choose Open Link in New Window to open it in one.
- **Return to Main Window.** A window that holds only its own tabs, such as one a tab was dragged or opened into, shows Return to Main Window at the top of its sidebar: one click moves all of its tabs back into the Space's normal window and closes it, and a tab that was pinned, saved or in a folder goes back to where it was, so nothing looks lost.
- **Picks up where you left off.** Arma opens the tab you were on when it last closed unless you choose Show Start Page in Settings › General › Startup.
- **Arc-style window dragging.** Press and drag anywhere in the top 120 points of a page where nothing takes a click to move the window, as Arc does; links, buttons, fields and text you can select there still work, and a click without moving still reaches the page. The drag is macOS's own, so pushing the window against a screen edge tiles it.
- **Show the background tab.** The Opened in Background Tab notice stays up longer, waits while your pointer rests on it, and offers Show Tab, which takes you to the tab it opened, switching Space if you moved on. A click anywhere on a notice with a button now reaches the notice, never the page under it.
- **Start Page comes back.** Closing a Space's last open page shows the Start Page instead of an empty window; closing the Start Page itself still puts it away.
- **Light by default.** New installs start in Light mode, and unloaded tabs aren't dimmed unless you turn that on.
- **Password prompt you control.** The password bubble under a login field appears only when the Space has a password for the site. The Save password? prompt sits at the top right, where you can correct the username and password, keep Include subdomains, Save, or choose Never for This Site; it closes on its own after a time you set (10 seconds unless you change it), waits while your pointer rests on it and starts over when it leaves, and stops counting down once you start typing. A sign-in that asks for the username on one page and the password on the next saves both, even across the site's subdomains. Ask to authenticate chooses whether showing or copying a saved password asks each time, every 15 minutes, or not at all (the default); changing it asks you to authenticate first, and exporting always asks.
- **Saved passwords you can add and edit.** Each Space's Passwords tab adds a password for any website and edits a saved one: its email, username, password, a category (or a new one) and up to 2 KB of notes such as recovery codes, kept in the Keychain and synced with iCloud Keychain like the password. Include subdomains lets a password fill every address under its site, never those of a public suffix such as github.io. Search finds passwords by category or email, `@passwords` finds logins by category, and Manage Passwords in a page's site controls opens the site's saved passwords, or a new one for it. Never Save Passwords On lists the websites the prompt never appears on, each with Include subdomains, at the bottom of the tab.
- **Password generator and private windows.** Generate, when you add or edit a password or sign up on a page, makes one to the length (16 unless you change it) and kinds of character you choose, and each Space chooses whether private windows suggest its passwords; they never save one.
- **Palette tool scopes.** Type `@extensions` to open Chromium's extensions (and Servo's, in a build that includes Servo), `@engine` to move the page, or always open its site, in another engine, `@developer` for the page's developer tools, and `@cli` to install the `arma` command in `~/.local/bin` or `~/bin`, or copy the line to run yourself, `@update` to check for a new version, and `@passwords` to find a saved login of the Space on screen and copy its username, password or website, fill it into the page or open the site.
- **Automation for testing frameworks.** Settings › Automation (or `arma automation`) lets Playwright, Puppeteer, Selenium, WebdriverIO, Katalon and TestCafe drive Arma's Chromium tabs over a local DevTools port, limited to one profile or an empty Ephemeral one, and to the tabs they open or existing tabs too, with copyable setup for each tool.
- **Updates from this repository.** Check for Updates installs Arma's own signed, notarized releases from GitHub, and a hidden sidebar rolls out to show the answer until you click elsewhere.
- **Arma's own Chromium.** Arma builds its own Chromium engine: its pages are `arma://` (such as `arma://extensions`), and the Chrome Web Store offers Add to Arma. Saved `crest://` addresses still open.
- **Runs on macOS 15.** Arma for Mac needs macOS 15.2 or later, where upstream needs macOS 26.1. On macOS 15, glass surfaces are drawn with a system material, and a page is translated when you ask rather than on its own.
- **Servo engine** (temporarily disabled in releases: it crashed the browser too often). Pages can run on Servo, the independent engine written in Rust, as a third engine beside Chromium and WebKit: pick it as the default engine, set it for a website, or move a page with Open Page in Servo. Install Firefox add-ons whose page scripts and styles Servo can run from Settings › Engines.

### Performance

- Closing, deleting or moving a large selection of tabs finishes without a pause in Spaces with lots of tabs.
- The command palette keeps up as you type in Spaces with lots of tabs.
- Switching to the most recent tab answers right away in Spaces with lots of tabs.
- Keeping a window's recent tabs current checks them against the Space once instead of searching every tab for each.
- Closing and moving tabs stays quick in Spaces with many folders.
- The sidebar stays responsive with many pages loaded: a tab's row looks up only its own page.
- Renaming or navigating a tab no longer checks every open tab's saved icon.
- Following a link in a Space with a long history no longer rebuilds every visited link on the page.
- Opening a tab whose page was unloaded no longer waits for other tabs' states to finish saving.
- Saving device records writes each list through one prepared statement instead of one per row.
- Moving the pointer over pages does less work while no link preview is waiting to appear.
- The blurred page previews behind a locked Space appear sooner.
- Each Mac window brings its pages up to date once per session change instead of repeating the tab icon and password passes.
- The Now Playing widget decodes its artwork once per image instead of on every redraw.
- A page a coding agent watches records each message and request without copying everything it already kept.
- The Space previews on the setup pages ask the core to resolve the draft only when it changes.
- On iPhone and iPad, each open page's state is saved once as the app leaves the foreground instead of twice.

### Bug fixes

- Sites stay signed in when Arma quits and reopens: Chromium Spaces bring back the session cookies a sign-in like GitLab's uses, as Chrome's Continue where you left off does.
- Coding agents reading a page's network requests no longer see sign-in headers a site spells its own way, such as X-CSRFToken, X-Auth-Token or an API key header.
- Importing a password file with an oversized field is refused at once instead of stalling the app.
- Closing a tab a coding agent was watching frees the console messages and network requests kept for it.
- The sidebar keeps its rows when the window enters or leaves full screen or changes size while scrolled; a list at its end stays at its end.
- What's New in Settings lists the newest changes instead of the ones whose names sort last.
- A tab an extension closes during an engine switch stays closed instead of coming back empty.
- New tabs opened from a link, the palette, history or a local document load once instead of twice.
- Clicking a command palette row right after typing opens it, and the arrow keys move the selection once results arrive.
- Switching Spaces in Passwords settings while the previous list was still loading no longer blanks the new list.
- Notifications from background websites and extensions keep appearing after many have been dismissed.
- On iPhone, Undo in Crest Studio steps back one change at a time.
- On iPad, a page's alerts, sign-in prompts and export sheets appear in the window that shows the page.
- On iPad, a site's location request no longer waits forever when Settings opens beside the app.
- On iPad, a closed window lets go of its pages, so its memory comes back and a restored window opens its tabs.
- Dragging the bar between Split View pages no longer leaves a white band under Chromium pages until they reload.
- In a Quick Window's address editor, a click or drag places the cursor or selects part of the address instead of leaving the whole address selected.

## A browser with boundaries

Most browsers put every login, tab, and distraction into one long-lived container. Arma begins with **Spaces** instead. Give work, home, research, or a private session its own banner; Arma gives each one its own cookies, website data, history, archive, tabs, credentials, settings, and sync identity.

Switching Spaces changes more than the color of the window. It changes the browsing context.

When several Spaces should share one set of sign-ins, make them **Sub-Spaces**: each keeps its own tabs and look while the group shares cookies, history, passwords, and extensions. [Read the Sub-Spaces guide.](HelpCenter/docs/spaces/sub-spaces.md)

## Three engines on Mac

Arma for Mac opens pages in **Chromium** by default. Its engine is Chromium
with Arma's privacy changes, which keep your browsing, form and account data
away from Google, and runs Chrome Web Store extensions. Any website or page can
open in **WebKit** instead, which adds Reader, whole-page translation, and
FairPlay video. Chromium leaves protected video to
WebKit: Netflix, Disney+, Max and Prime Video open in WebKit, and any other
page that asks for Widevine or PlayReady video, itself or from a frame of its
own site, switches to WebKit automatically, respecting any unsaved-changes
prompt before moving it. A page can also run in **Servo**, the
independent engine written in Rust, once it returns: it is temporarily disabled
because it crashed the browser too often. Choose the default engine and
per-website rules in **Settings → Engines**, or with `arma site engine`. iPhone and iPad use WebKit. The
[engine guide](HelpCenter/docs/browsing/engines.md) lists what each engine
supports.

## Crest Studio and Appearance

**Crest Studio** puts each Space's crest on that Space's own sidebar background. Start from a template, then step through shape, field, band, emblem, border, finish and sidebar, choosing from previews of your own crest. Every part of the crest and the sidebar has its own color, named by what it paints. Use heraldic artwork, emoji, monograms, or a searchable SF Symbols picker, and Shuffle and Undo freely.

**Appearance** lets you dock the sidebar on either edge, go borderless, adjust tab shape and scale, choose a pin layout, and tune tab and address-field colors, or let them follow each Space's accent. Start with a preset, see changes live, and reset individual settings. Choose an app icon palette, folder colors and icons, and a default page zoom from 50% to 300%.

## Browsing features

- **A sidebar with structure.** Pins for everyday sites, saved tabs with a home URL, nested folders for projects, and current tabs for what you are doing now. Select tabs, Split Views, and folders together to organize them in one step.
- **Split View.** Keep two to four live pages in a group. Resize columns on Mac and iPad; move through focused cards on iPhone.
- **Peek.** Preview a link above the current page, then close it or keep it as a tab. On Mac, drag a link into a live Peek. On iPhone and iPad, native link and image menus keep touch actions close by.
- **Quick Window on Mac.** Open a link from another app using the right Space’s signed-in session. Promote it to a regular tab when it deserves to stay. Link Routing sends matching external links to their chosen Space.
- **Shared windows on Mac.** Open another window onto the same Spaces and tabs, with its own selection. Use a disposable Blank Window for temporary tabs with your Space’s signed-in session, or create one by dragging a tab outside the window.
- **Search and commands.** Open a URL, search the web, find tabs and history in your Space, or run a command from one field. Choose custom search engines and optional suggestions. Mac shortcuts can be rebound.
- **Getting Started.** Learn tabs, pins, and folders in an interactive browser tab, with Split View practice on Mac.

## Page tools

| Capability | What it does |
| --- | --- |
| On-device translation | On iPhone, iPad, and WebKit pages, detect a page’s language, translate it, or show the original. On Chromium pages, translate selected text. Optional automatic translation uses downloaded languages. Apple may ask to download additional languages. |
| Reader and page tools | Read supported articles with fewer distractions on WebKit pages, find text, adjust zoom, share links, copy Markdown links, print, and export PDF or web archives where supported. |
| Extensions on Mac | Install Chrome Web Store extensions in each Space. They run on Chromium pages, with popups and tab-specific side panels. [Compatibility varies.](HelpCenter/docs/extensions/compatibility.md) |
| Developer tools on Mac | Preview phone, desktop, and custom viewport sizes; capture pages; open Chromium DevTools or Web Inspector for the page's engine. The toolbar appears on localhost, or on any site with **Shift-Command-I**. |
| Media | Control eligible active media from the sidebar. On Mac, keep supported videos visible with Picture in Picture, including optional automatic PiP. |
| Downloads and uploads | Follow download progress and revisit files in Downloads. Pause and resume Chromium transfers when the server supports recovery. On iPhone and iPad, upload through Photos, camera, or Files. |

## Privacy and sync

**Private Spaces** use temporary website storage and stay out of normal history, restoration, and sync. They can require device authentication and relock when Arma leaves the foreground. **Arma Passwords** keeps origin- and Space-matched credentials in the system Keychain, with authentication for sensitive access.

Site permissions are controlled per Space. Built-in ad and tracker blocking covers every page, in WebKit and Chromium, on Mac, iPhone, and iPad, and applies to every Space alike: choose Off, Balanced, or Strict in **Settings → Ad Blocking**, and turn it off for a site that doesn't work with it from the page's actions. Closed and cleaned-up tabs go to a recoverable Archive, subject to your retention settings. **Keep Loaded** protects a page from ordinary unloading when its live state matters.

Optional **iCloud sync** carries durable Spaces, tabs, folders, Split View groups, appearance, history, and Archive between devices. Password values stay out of CloudKit; eligible passwords can use iCloud Keychain separately. Start a browser import on Mac, review each destination Space, or export a portable archive.

Read the [Space isolation guide](HelpCenter/docs/spaces/spaces-and-isolation.md) and [sync guide](HelpCenter/docs/spaces/sync-across-devices.md) for the boundaries and controls. _Placeholder: Arma has no published privacy policy yet._

## Get Arma

Download the latest **Installer** disk image from
[Releases](https://github.com/devops-senpai/Arma/releases/latest), open it, and drag
Arma onto **Applications**. Arma for Mac needs Apple silicon and macOS 15.2 or
later.

Arma is signed with a Developer ID and notarized by Apple, so it opens
like any other Mac app. Once installed it keeps itself up to date: it looks
for new releases on its own, and **Arma › Check for Updates…** or `@update`
in the command palette looks now.

You can also build it from source as described below; the Mac app runs
Chromium when a prebuilt engine is packaged in, and WebKit alone otherwise.

## Built as an Apple-platform app

Arma's browser state and rules live in a portable core written in C# and compiled with NativeAOT. The apps are written in Swift and SwiftUI: shared features live in `CrestShared`, and each platform owns its windows, engine hosting, commands, and adaptive presentation. On Mac, pages render in Chromium by default or in WebKit; iPhone and iPad use WebKit.

```text
CrestCore/       Portable core: session, sync, pages, and browser rules
CrestContracts/  C ABI header and ABI checks for the core library
CrestEngines/    Chromium host overlay, patches, and engine binding
CrestShared/     Domain, application, infrastructure, features, design system
CrestMac/        macOS app and platform-specific presentation
CrestMobile/     iPhone and iPad app and platform-specific presentation
```

Read [the architecture overview](Documentation/ARCHITECTURE.md) for Space isolation, persistence, credentials, synchronization, and the engine boundary.

## Build Arma

Requirements:

- Apple silicon Mac
- Xcode with macOS and iOS SDKs supporting the 26.1 deployment targets
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)
- .NET SDK pinned by `CrestCore/global.json`, installable with `Scripts/control-plane/install-dotnet.sh`

```bash
git clone https://github.com/devops-senpai/Arma.git
cd Arma
Scripts/bootstrap.sh
open Crest.xcodeproj
```

Xcode builds and embeds the self-contained .NET core for Mac, iOS, and Simulator. Its intermediate files stay in Derived Data; the installed app does not require a .NET runtime. The `Crest` scheme builds the Mac app with WebKit only; a Chromium build adds a prebuilt engine, described in the [Chromium engine README](CrestEngines/Chromium/README.md). See the [control-plane build workflow](Documentation/Architecture/ControlPlane.md#build-workflow) for isolated review builds and Chromium packaging.

`project.yml` is the source of truth for targets and build settings. Run `xcodegen generate` after changing source roots, targets, or project configuration.

## Validate a change

```bash
Scripts/validate-identity.sh
Scripts/validate.sh
Scripts/validate-cache-hygiene.sh
```

Run the relevant behavioral tests and repository checks. Review visual, layout, and static-copy changes in the real app, Simulator, or browser.

## Relationship to Crest

Arma tracks Crest's `main` and merges it in regularly; its own
changes stay here. Use
[GitHub Issues](https://github.com/devops-senpai/Arma/issues) for bugs.

### Repository and tooling

- The patch version is derived from history and each release note is its own file, so branches stop conflicting on every merge.
- `Scripts/sync-upstream.sh` merges upstream Crest in one step and leaves only real code conflicts to a person.
- `Taskfile.yml` and `Documentation/ForkRunbook.md`: `task sync` keeps history as upstream plus one commit per change, `task release` and `task notarize` build, sign and notarize a release, and `task publish` puts it on GitHub and in the signed update feeds with secrets from sops.
- `task engine:build` builds Arma's Chromium engine on a Mac, through ccache so a rebuild after a sync takes minutes, and `task engine:publish` publishes it for releases.
- `ROUTING.md` and a `CONTEXT.md` in every folder that groups work tell a contributor or an agent what to read for each kind of change.
- `Documentation/Renaming.md` lists every place a product name lives.
- `Brand/` holds the banner artwork; `Scripts/generate-app-icon-palettes.py` turns one banner into the app icon, its palette variants, picker previews and Dock images.
- The version bump check runs statically, the CI whitespace gate works, and stray files no longer change the engine key.

## AI usage

AI tools assist with Arma's development, audits, testing and
documentation. Every generated change is reviewed and validated before it is
committed. Any change an AI tool helps produce follows the
[`crest-contribution` skill](.agents/skills/crest-contribution/SKILL.md), which
carries the C# and Swift style, the architecture and UI rules, and the test
policy.

## License and brand

Arma's source code is available under the [Mozilla Public License 2.0](LICENSE),
as Crest's is. The source is open for inspection, modification, and commercial
use under that license. The Crest name, app icon, logos, and official
distribution identity belong to Paul Davis and are reserved as described in
[TRADEMARKS.md](TRADEMARKS.md). Arma is a separate, unofficial project.
Third-party notices are collected in
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
