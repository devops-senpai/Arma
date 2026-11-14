---
name: arma-power-user
description: Recipes for getting more out of the Arma browser - organize a messy Space into folders, build Split View layouts, tile windows, route sites to an engine, manage permissions and site data, script saved passwords, tidy history, the archive and downloads, back up and move a setup, and chain `arma` commands in shell scripts. Use when someone wants to reorganize, automate or bulk-change their Arma setup rather than do one simple action.
---

# Arma for power users

These recipes use the `arma` command (see the `arma-cli` skill for its rules). They change
the person's real browser. Read state first, say what you will change, then change it.

```sh
command -v arma || alias arma=/Applications/Arma.app/Contents/Helpers/arma
```

## Script with JSON

Every section takes `--json`. The list sits under a key named for it.

```sh
arma tab list --space Work --json | jq -r '.tabs[] | [.id, .title] | @tsv'
arma space list --json | jq -r '.spaces[].name'
```

Print one record first (`| jq '.tabs[0]'`) to see the fields this version gives, then
write the filter. Ids can be shortened to their start when that is unambiguous.

## Organize a Space into folders

```sh
arma space show Work                                 # see what is there
arma folder create Clients --space Work              # saved; add --open for the open tabs
arma folder create Acme --space Work --in Clients    # nested: Clients/Acme
arma folder add <tab> <tab> <tab> --to Clients/Acme --space Work
arma folder color Clients "#7a8bb0" --space Work
arma folder close Clients --space Work               # collapse it in the sidebar
```

To file by site, list the tabs as JSON, group their ids by host, and run one
`arma folder add` per group. Show the person the grouping before you file anything.

Deleting a folder keeps its tabs: `arma folder delete <path>` leaves them in the section
and moves folders inside it up a level.

## Place things exactly

Any command that takes a `<place>` puts the item where you say:

```sh
arma tab move <tab> --before <other-tab>
arma tab open https://example.com --space Work --saved --at 1
arma folder move Clients --top --after Inbox
arma tab pin <tab> --at 2
```

## Split View layouts

```sh
arma split create <tab> <tab>                 # two columns
arma split create <tab> <tab> <tab> --rows    # stacked
arma split add <tab> --to <tab-in-the-split>
arma split arrange <tab> grid                 # also two-across, two-stacked, three-across, four-stacked
arma split remove <tab>                       # take one out
arma split break <tab>                        # end the split; the tabs stay
```

A split holds two to four tabs of one Space. `arma split help` names the layouts.

## Arrange windows

```sh
arma window list
arma window tile left                # right, top, bottom, the four corners, full
arma window move 100 80 --screen 2
arma window resize 1440 900
arma window open --space Personal    # another window onto a Space
```

A new window is something the person sees appear. Open one only when asked.

## Send sites to the right engine

```sh
arma site list                              # sites with a rule or a kept permission
arma site engine figma.com chromium
arma site engine netflix.com webkit         # FairPlay video plays in WebKit
arma site engine example.com default        # remove the rule
arma tab engine current webkit              # just this page
```

A rule covers one host: `example.com` does not cover `app.example.com`. Each engine keeps
its own cookies, so a site moved to the other engine needs signing in again there.

## Permissions and site data

```sh
arma site permission meet.google.com camera-and-microphone allow --space Work
arma site permission example.com notifications block
arma site permission example.com location ask      # forget the answer
arma site clear example.com --space Work           # its rule and permissions
arma site clear example.com --space Work --data    # and its cookies, storage and cache
```

`--data` signs the person out of that site in that Space. Confirm first.

## Run anything the menus can

```sh
arma command list --search reader     # ids, titles, and whether each can run now
arma command run toggle-reader-mode
arma command run "Copy Page Link as Markdown"
arma command run capture-page
```

Commands run in the front window, on its current tab.

## Saved passwords from the terminal

The Space must allow it (Settings › Space › Passwords › Allow command-line access), and
each session needs the person's Touch ID or Mac password.

```sh
eval "$(arma passwords unlock --space Work)"      # keeps the key in ARMA_SESSION, an hour at most
arma passwords list --site github.com
arma passwords get username github.com
arma passwords get password github.com | pbcopy   # never print a password into a log
arma passwords create example.com --username me@example.com --generate
printf '%s' "$NEW" | arma passwords edit example.com --password-stdin
arma passwords lock
```

A password is read from standard input, never from the command's words, so it stays out of
shell history. Never echo a password, write it to a file, or put it in a commit. Lock the
session when done.

## History, archive and downloads

```sh
arma history search "invoice" --since 7d --limit 20
arma history delete https://example.com/page       # every visit to one address
arma archive search "pricing" --reason closed
arma archive restore <entry>                       # back as an open tab, with its history
arma download list
arma download reveal <download>
arma download clear                                # the list only; files stay
```

`history clear` and `archive clear` need `--yes` and cannot be undone. Use them only when
the person asked, and name the Space and range you are about to clear.

## Clean up a crowded Space

1. `arma tab list --space <space> --json` and count open tabs by host and age.
2. Offer a plan: which to file into folders, which to save, which to close.
3. Close what the person agreed to. Closed open tabs go to the Archive and can be
   restored, so this is recoverable.
4. Set the Space to tidy itself:
   `arma settings set space.browsing.archive-tabs after-7-days --space <space>`.

## Back up or move a setup

```sh
arma settings export ~/Documents/arma-backup.json            # Spaces, settings, tabs, history
arma settings export ~/Documents/bookmarks.html --format bookmarks
arma theme show "My Theme" > ~/Documents/my-theme.json       # one file per theme
arma settings import ~/Documents/arma-backup.json --yes      # on the other Mac; adds, replaces nothing
arma theme import ~/Documents/my-theme.json
```

The backup holds no passwords, cookies, website storage, permissions or extensions.
Passwords export separately, from Settings › Space › Passwords, and that file is plain
text: treat it as a secret.

## Settings worth changing

```sh
arma settings list                         # every key, value, allowed values and where it lives
arma settings set tabs.split.focus-follows-mouse on
arma settings set links.peek.modifier option
arma settings set links.external.open-in most-recent-space
arma settings set links.remember-space-by-site on
arma settings set search.default-engine duck-duck-go
arma settings set space.privacy.keep-history ninety-days --space Work
```

Read the allowed values from `arma settings list` before setting a key. `arma settings
reset <key>` puts one back.

## Palette habits to teach

- `@tabs`, `@history`, `@saved`, `@actions`, `@spaces`, `@themes` and **Space** narrow the
  results to one kind.
- A provider shortcut and **Tab** searches that site or asks that assistant.
- **Option-Return** opens a result in a Quick Window; **Shift-Return** in Split View.
- **Control-Tab**, held, shows recent tabs to step through.
- **Shift-Delete** on a history result removes it.

## Before any bulk change

- Read first and show the plan.
- Prefer moves that can be undone: closing an open tab can, clearing history cannot.
- Change one Space at a time and name it with `--space`.
- Leave the tab and Space the person was on in front when you finish:
  `arma tab show <tab>`.
