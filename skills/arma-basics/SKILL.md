---
name: arma-basics
description: How the Arma browser is organized and used day to day - Spaces, pinned, saved and open tabs, folders, the command palette, Peek and Quick Windows, Split View, the two engines, and the default keyboard shortcuts. Use when explaining Arma to someone, answering "how do I do X in Arma", or before acting in Arma so the terms in the CLI and Settings make sense.
---

# How Arma works

Arma has one window with a sidebar. The sidebar shows one **Space** at a time; everything
below is that Space's.

## The sidebar, top to bottom

| Part | What it is |
| --- | --- |
| Address field | Shows the page's site. Click it, or press **Command-L**, for the command palette. |
| **Pinned** tabs | A grid of icons for sites kept close: mail, calendar, a dashboard. |
| The Space's name and crest | Its menu edits the Space. |
| **Saved** tabs and folders | Lasting pages, each with a home address it can return to. |
| **Open** tabs | Ordinary pages, below the divider. They can be cleared or archived. |
| Space picker | Switch Spaces at the bottom. |

A tab is one of three kinds, and the CLI says which in `arma tab list`:

- **open**: temporary. Closing it, clearing open tabs, or the Space's cleanup sends it to
  the **Archive**, where it can be restored.
- **saved**: lasting, optionally in a folder. Closing it puts its page away and keeps the
  tab.
- **pinned**: lasting, shown as an icon.

Folders hold saved or open tabs and can nest. A folder path joins names with `/`.

## Spaces

A Space is a separate browsing profile, not only a group of tabs: its own sign-ins,
cookies, history, passwords, permissions, extensions and look. Work and Personal can be
signed in to the same site as different people.

- Switch with the picker, **Option-Command-Left/Right**, or **Control-1** to **Control-9**.
- Moving a tab to another Space moves the tab, not its sign-in.
- **Sub-Spaces** share one Space's sign-ins and history while keeping their own tabs.
- A **private window** (**Shift-Command-N**) keeps nothing.
- Deleting a Space deletes its tabs, history, passwords and website data.

## The command palette

**Command-L** opens one field that does everything: go to an address, search, switch to a
tab, reopen history, run a command, open a settings page.

- **Return** runs the first row. **Command-Return** opens in a background tab,
  **Shift-Command-Return** a new tab, **Shift-Return** Split View, **Option-Return** a
  Quick Window.
- Type a provider's shortcut and **Tab** to search it: `g` Google, `ddg` DuckDuckGo,
  `yt` YouTube, `w` Wikipedia, `claude` and other assistants.
- Type a scope and **Space** to narrow: `@tabs`, `@history`, `@saved`, `@actions`,
  `@spaces`, `@themes`.
- Tool scopes act: `@extensions`, `@engine`, `@developer`, `@cli`, `@update`, `@passwords`.
- Type a command's name or initials, such as "split" or "tsv" for Toggle Split View.
- Type arithmetic, such as `24 * 7`; **Return** copies the answer.

## Ways to open a link

| Surface | What it is | How |
| --- | --- | --- |
| New tab | A normal open tab | **Command-click** a link |
| **Peek** | A preview over the page; close it or promote it to a tab | Drag a link, or the modifier set in Settings › Links. **Command-W** closes, **Command-O** promotes |
| **Quick Window** | A temporary window for a link from another app, or to see a link under another Space's account | **Option-Shift-Command-N**, or right-click a link and choose a Space under Open Link in |
| **Split View** | Two to four live pages side by side or stacked | Drag a tab onto an edge of the page, or right-click a link and choose Open Link in Split View |
| New window | A window of its own for one tab | Drag a tab out, or right-click and choose Open in New Window |

## Engines

Arma runs pages on **Chromium** by default and can run any page or site on **WebKit**, the
engine behind Safari. Chromium runs Chrome Web Store extensions. WebKit has Reader and
plays FairPlay video, so Netflix and similar open there. Each engine keeps its own cookies
for a Space. **Page › Open Page in WebKit** moves one page; Site Controls › **Opens in**
sets it for a whole site.

## Shortcuts worth knowing

| Action | Keys |
| --- | --- |
| Command palette | Command-L |
| New tab | Command-T |
| Close tab | Command-W |
| Reopen closed tab | Shift-Command-T |
| Pin or unpin | Command-D |
| Archive tab | Command-E |
| Clear open tabs | Shift-Command-K |
| Most recent tab (hold to see the list) | Control-Tab |
| Previous / next tab | Option-Command-Up / Down |
| Tab 1 to 9 | Command-1 to Command-9 |
| Previous / next Space | Option-Command-Left / Right |
| Show or hide sidebar | Command-S |
| History | Command-Y |
| Downloads | Shift-Command-J |
| Find in page | Command-F |
| Translation toolbar | Shift-Command-L |
| Capture page | Shift-Command-2 |
| Copy page link / as Markdown | Shift-Command-C / Option-Shift-Command-C |
| Settings | Command-, |
| Web Inspector | Option-Command-I |

Settings › Shortcuts changes any of them and shows conflicts. Commands without keys are
still in the menus and the palette.

## Where things live in Settings

General, Tabs, Search, Appearance, Themes, Links, Engines, Shortcuts, Sync, Privacy, Ad
Blocking, then one page per Space (Appearance, Browsing, Privacy, Passwords, Extensions),
then Agents, Automation, Advanced, About.

## Recovering things

- A closed tab: **Shift-Command-T**, or the Archive (the box at the bottom of the
  sidebar), or `arma archive list` and `arma archive restore <entry>`.
- A page visited before: **Command-Y**, `@history` in the palette, or `arma history search`.
- A download: **Shift-Command-J**, or `arma download list`.

## Doing it from the terminal

Nearly everything above has a command. See the `arma-cli` skill; the short version:

```sh
arma space list
arma tab list
arma tab open <url> --space <space> --background
arma command run "<any menu command>"
```
