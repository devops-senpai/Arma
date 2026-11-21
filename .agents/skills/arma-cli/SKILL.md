---
name: arma-cli
description: Drive the running Arma browser from the terminal with the `arma` command - list, open, move, pin and close tabs, manage Spaces, folders, Split View and windows, run any menu command, read and change settings, set per-site engines and permissions, and search history, the archive and downloads. Use whenever a task means doing something in Arma that a person would do by clicking, or reading Arma's state from a script.
---

# The `arma` command

`arma` talks to the Arma app that is already open on this Mac. It changes what the person
sees right away, in their real Spaces and tabs. It does nothing when Arma is closed.

## Find the command

```sh
command -v arma || alias arma=/Applications/Arma.app/Contents/Helpers/arma
```

The helper ships inside the app. A person puts it on the PATH by typing `@cli` in Arma's
command palette, which links it into `~/.local/bin` or `~/bin`. In a script, call the full
path so it works either way.

If the answer is `Arma isn't running`, start it without taking the screen:

```sh
open -g --env CREST_BACKGROUND_LAUNCH=1 -a Arma
```

## How every command is shaped

```text
arma <section> <action> [arguments] [options]
arma <section> help          # that section's actions, always current
arma <section> ... --json    # the same result as JSON, for scripts
```

Read [reference.md](reference.md) for every section's actions and options. The rules that
hold everywhere:

- **A tab** is `current` (the front window's tab), its id from `arma tab list`, or the start
  of that id. Ids are stable while the tab lives; list again after closing or reopening.
- **A Space** is its name in any case, or its id. Without `--space`, most commands use the
  Space the front window shows.
- **A folder** is a path of names joined with `/`, such as `Work/Clients`. One name is
  enough when no other folder has it.
- **A place** is `--before <row>`, `--after <row>` or `--at <n>`, where a row is a tab or a
  folder in the same list and `n` counts from 1. Without one, the item goes last.
- **Colors** are `#RRGGBB` or `#RRGGBBAA`.
- JSON wraps its list in an object named for it: `arma tab list --json` prints
  `{"tabs": [...]}`, `arma space list --json` prints `{"spaces": [...]}`.

## Look before you act

```sh
arma space list                 # every Space; * marks the one on screen
arma space show Work            # its pinned, saved and open tabs and folders
arma tab list --space Work      # ids, placement, folder, engine, in sidebar order
arma window list                # windows front to back
arma command list --search tab  # menu and palette commands, and whether they can run now
```

## Open tabs where you mean to

`arma tab open <url>` **without `--space` opens a Quick Window**, a temporary window, not a
tab in the sidebar. Name the Space to get a real tab:

```sh
arma tab open https://example.com --space Work                 # an open tab, shown
arma tab open https://example.com --space Work --background    # without leaving the current tab
arma tab open https://example.com --space Work --pinned
arma tab open https://example.com --space Work --folder Clients/Acme --title "Acme portal"
```

Leave the engine out unless the task needs one: the page then opens on the engine the
person set for that site (`arma site engine`), or on their default (`engines.default`).
`--engine` names one for this tab only; it needs `--space`:

```sh
arma tab open https://example.com --space Work --background                  # the site's or default engine
arma tab open https://example.com --space Work --background --engine webkit  # this tab on WebKit
arma tab engine <id> chromium                                                # move a tab that is already open
```

In Arma before 0.8.277, `--engine` on `tab open` left the tab on the default engine; there,
open it and then `arma tab engine <id> webkit`.

`--background` is the polite default when a person is using the browser: it never pulls
them off the page they are reading.

## Common actions

```sh
arma tab show <tab>                      # bring a tab forward
arma tab go <tab> <url>                  # load another address in it
arma tab move <tab> --space Personal     # to another Space (its sign-ins do not come along)
arma tab pin <tab> ; arma tab save <tab> ; arma tab unpin <tab>
arma tab close <tab> ; arma tab reopen   # reopen brings back the tab closed last
arma folder create Clients --space Work
arma folder add <tab> <tab> --to Clients
arma split create <tab> <tab>            # side by side; --rows stacks them
arma split arrange <tab> grid
arma window tile left                    # the front window; also right, top, full, corners
arma command run "Show Downloads"        # any menu or palette command, by id or title
arma settings get engines.default
arma settings set appearance.mode dark
arma site engine netflix.com webkit      # a per-website engine rule
arma history search "invoice 2026" --since 7d --limit 20
arma archive restore <entry>             # a tab that was closed or archived
```

## Things that need a switch first

| Command | Needs |
| --- | --- |
| `arma page ...` (read and act inside a page) | Settings › Agents › Command-line page control |
| `arma passwords ...` | Settings › Space › Passwords › Allow command-line access, then `arma passwords unlock` |
| `arma automation ...` (Playwright and others) | `arma automation on`, then `arma automation restart` |

See the `arma-agent-browsing` skill for pages and automation.

## Take care

- Every command acts on the person's real browser. Closing, clearing and deleting are
  real. `history clear`, `archive clear` and `settings import` refuse without `--yes`:
  pass it only when the person asked for that.
- `arma tab close` on a pinned or saved tab puts its page away and keeps the tab.
  Deleting a folder keeps its tabs.
- Do not move, close or reload tabs the person did not ask about. Open your own tab,
  work in it, and close it when done.
- An id that matches no tab, or the start of two, is an error. List again and use more
  of the id.
