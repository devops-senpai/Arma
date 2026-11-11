# `arma` command reference

Every section's actions, as `arma <section> help` prints them. The running app is the
source of truth: when a command here fails, run `arma <section> help` and use what it says.

```text
usage: arma <section> <action> [options]

Manage the running Arma from the terminal.

  space       List Spaces, show one, or switch the front window to one
  tab         List, open, close, move, pin and save tabs, and pick their engine
  window      List, move, resize, tile, minimize and zoom Arma's windows
  folder      List, create, rename, move, delete and color folders, and file tabs in them
  split       Show tabs side by side in Split View, and change or end a split
  command     List and run the menu and command palette's commands
  extension   List, install, remove, turn on and off Chromium and Servo extensions
  history     Search, list, delete from and clear each Space's history
  archive     Search, restore, delete from and clear the tabs each Space archived
  download    List downloads, open or reveal their files, cancel, retry and clear them
  page        Read, capture, script and act inside a tab's page (Settings › Agents turns it on)
  automation  Let Playwright, Puppeteer, Selenium and others drive Arma's Chromium tabs
  settings    Read and change settings, and export or import browser data
  site        List and change per-website engine rules and permissions, or clear a site
  theme       Make, edit and pick the themes that color Arma's windows
  crest       Shape and color a Space's own crest or icon
  passwords   Unlock a Space's saved passwords for an hour, then list, read, add, change or delete them
  mcp         Serve Arma's tools to a coding agent over MCP

Every section takes --json to print its result as JSON.
Run arma <section> help for a section's actions.
```

## arma space

```text
usage: arma space <action> [options]

  list                    every Space; * marks the one the front window shows
  show [<space>]          a Space's pinned, saved and open tabs and its folders
  switch <space>          show <space> in the front window

A Space is named by its name (any case) or its identifier.
```

## arma tab

```text
usage: arma tab <action> [options]

  list [--space <s>] [--folder <path>] [--loaded]
                           tabs with their id, placement, folder, engine and
                           whether their page is loaded, in the sidebar's order
  open <url> [--space <s>] [--engine chromium|webkit|servo] [--background]
             [--pinned | --saved | --folder <path>] [--title <title>] [<place>]
                           open a new tab; with no --space it opens in a Quick
                           Window, where its Space menu picks the Space
  close <tab>              close a tab (a pinned or saved tab's page is put away)
  show <tab>               bring a tab forward
  reload <tab> [--hard]    reload, skipping the cache with --hard
  go <tab> <url>           load <url> in the tab
  engine <tab> <engine>    move the tab's page to chromium, webkit or servo
  move <tab> [--space <s>] [--folder <path>] [<place>]
                           move a tab to another Space, into a folder, or to
                           another place in its list
  pin <tab> | save <tab> | unpin <tab> [<place>]
                           pin, save, or make it an open tab again
  duplicate <tab>          open a copy beside it
  rename <tab> [<title>]   rename, or go back to the page's title
  reopen                   reopen the tab closed last

A tab is current (the front window's), its id, or the start of its id from
arma tab list. A folder path joins folder names with /, such as Work/Clients.
A <place> is --before <row>, --after <row> or --at <n>, where a row is a tab
or a folder in the same list and <n> counts its rows from 1; without one the
tab goes last.
```

## arma folder

```text
usage: arma folder <action> [options]

  list [--space <s>]       folders as a tree, in the saved and open sections,
                           with the tabs each holds
  create <name> [--space <s>] [--in <path>] [--open] [<place>]
                           make a folder, inside <path> when given; saved,
                           or in the open tabs with --open
  rename <path> <name> [--space <s>]
                           rename a folder
  move <path> [--space <s>] [--in <path> | --top] [--saved | --open] [<place>]
                           move a folder, with everything in it, inside another
                           folder or to the top level, to the saved or open
                           tabs, or to another place among its neighbours
  delete <path> [--space <s>]
                           delete a folder; its tabs stay in its section and
                           the folders inside it move up one level
  add <tab>... --to <path> [--space <s>] [<place>]
                           file tabs into a folder
  open <path> | close <path> [--space <s>]
                           expand or collapse a folder in the sidebar
  color <path> <#hex|default> [--space <s>]
                           give a folder its own color, or its Space's again

A folder path joins folder names with /, such as Work/Clients; one name is
enough when no other folder has it. Without --space, the front window's
Space. A tab is current, its id, or the start of its id from arma tab list.
A <place> is --before <row>, --after <row> or --at <n>, where a row is a tab
or a folder in the same list and <n> counts its rows from 1; without one the
folder or tabs go last.
```

## arma split

```text
usage: arma split <action> [options]

  list [--space <s>]       splits with their layout and tabs
  create <tab> <tab> [<tab>...] [--rows]
                           show the tabs together in a new Split View, in
                           columns, or in stacked rows with --rows
  add <tab> --to <tab>     add a tab to the split the other tab is in
  remove <tab>             take a tab out of its split
  break <tab>              end the split the tab is in; its tabs stay
  arrange <tab> <layout>   lay out the tab's split, such as two-across,
                           two-stacked, three-across, grid or four-stacked

A tab is current, its id, or the start of its id from arma tab list. The
tabs of a split share one Space; the front window shows that Space to
change it.
```

## arma window

```text
usage: arma window <action> [<window>] [options]

  list                          windows front to back: number, Space, frame, screen
  focus [<window>]              bring a window forward
  move [<window>] <x> <y> [--screen <n>]
                                put the top-left corner at x, y points from the
                                screen's top left (screen 1 is the main screen)
  resize [<window>] <width> <height>
  tile [<window>] <region>      left, right, top, bottom, top-left, top-right,
                                bottom-left, bottom-right or full
  center | minimize | restore | zoom | fullscreen [<window>]
  open [--space <s>]            open a new window
  close [<window>]

A window is its number from arma window list, front (the default) or its id.
```

## arma command

```text
usage: arma command <action> [options]

  list [--search <text>]   the commands, with their id and whether the front
                           window can run them now
  run <command>            run a command in the front window, as the menu or
                           palette would

A command is its id, such as new-tab, or its title, such as "New Tab", in
any case.
```

## arma page

```text
usage: arma page <tab> <action> [options]

  info                       address, title, engine, loading and zoom
  text [--max <chars>]       the page's readable text, as Markdown
  snapshot                   the page as an outline whose elements carry uids
  screenshot [--out <file.png>] [--full] [--uid <uid>]
                             capture what the page shows, all of it with --full,
                             or one element; prints the PNG's path
  eval <js> | --file <path>  run an expression, or statements that return a value,
                             in the page; prints the result as JSON
  click <uid> | <x>,<y> [--double]
  hover <uid> | <x>,<y>      a uid from snapshot, or a point in CSS pixels from
                             the page's top left
  type <text>                type into the focused element
  fill <uid> <text>          replace a field's text, or pick a menu's option
  key <key> [--modifiers cmd,shift,option,control]
                             press a key such as Enter, Escape, ArrowDown or a
  scroll <dx> <dy> | --to top|bottom
  wait --text <t> | --url <part> [--timeout <seconds>] | --seconds <n>
  dialog accept|dismiss [--text <reply>]
                             answer the page's alert, confirm or prompt
  console [--since <n>]      console messages Arma kept, after sequence n
  network [--since <n>]      network requests Arma kept, after sequence n

A tab is current (the front window's), its id, or the start of its id from
arma tab list. Turn on Settings › Agents › Command-line page control first.
```

## arma settings

```text
usage: arma settings <action> [options]

  list [--section <name>] [--space <s>]
                           every setting: key, value, allowed values and
                           where it is in Settings
  get <key> [--space <s>]  one setting's value
  set <key> <value> [--space <s>]
                           change a setting
  reset <key> [--space <s>]
                           put a setting back to its default
  export <file> [--format browser-data|bookmarks] [--force]
                           write the Spaces, their settings, tabs and history
                           (or the bookmarks) to <file>; --force replaces it
  import <file> --yes      add the Spaces, tabs and history of a browser-data
                           file after your own; it replaces nothing

A section is the first part of a key, such as general, tabs, links, search,
engines, appearance, agents or space. Keys that start with space. belong to
one Space: --space names it, or the front window's Space is used.
```

## arma site

```text
usage: arma site <action> [options]

  list [--space <s>]       sites with an engine rule or a kept permission
  engine <site> chromium|webkit|servo|default
                           open <site> in an engine; default removes the rule
  permission <site> <permission> allow|block|ask [--space <s>]
                           answer a permission for <site>; ask forgets the answer
  clear <site> [--space <s>] [--data]
                           forget <site>'s engine rule and its permissions;
                           --data also removes its cookies, storage and cache

A site is a host, such as example.com, or an address, such as
https://example.com:8443. Engine rules apply in every Space; permissions and
data belong to one Space: --space names it, or the front window's is used.

Permissions: camera, microphone, camera-and-microphone, location,
notifications, popups, automatic-downloads, external-applications,
screen-sharing.
```

## arma theme

```text
usage: arma theme <action> [options]

  list                          saved themes, the Spaces using each; * marks the
                                shown Space's
  show <theme>                  a theme as a theme file (JSON); save it with > file
  new <name> [--from-space <space>] [--from-file <path>] [look options]
                                save a theme, from a Space's look, a file, or plain
  duplicate <theme> [--name <name>]
  rename <theme> <name>
  delete <theme>                delete a theme no Space uses
  import <path> [--name <name>] save a theme file as a theme
  edit [<theme>] [--space <space>] [--dark] [--unpair-dark] [--from-file <path>]
       [look options]           change a theme, or the one a Space uses, and every
                                Space using it; --dark edits its dark look, and
                                --unpair-dark turns the dark look off, keeping it
  reset <section>... [<theme>] [--space <space>] [--dark]
                                put background, icon, folders, command-palette or
                                all back to the plain look
  use <theme> [--space <space>] have a Space, or the shown one, use a theme

Look options:
  --background <hex>[,<hex>[,<hex>]]   background, accent and pattern colors
  --style banner|gradient
  --pattern <name>              solid, split, bands, diagonal, chevron, quartered,
                                stripes, checkered or lozenges
  --angle <degrees>             the gradient's direction
  --intensity <0-1>             how strongly the colors show
  --fade <0-1>                  the readability fade behind the controls
  --texture on|off
  --text automatic|light|dark|system
  --sidebar-text <hex>|default  the one color the sidebar's text reads in
  --sidebar-secondary-text <hex>|default
                                the sidebar's quieter text, such as New Tab
  --folder-color <hex>|default
  --folder-back-color <hex>|default
  --folder-outline-color <hex>|default
  --folder-highlight-color <hex>|default
                        the tint of an open, hovered or chosen folder's rows
  --folder-highlight-opacity <0-1>
  --palette-light <hex>|default  --palette-light-opacity <0-1>  --palette-light-text <hex>|default
  --palette-dark <hex>|default   --palette-dark-opacity <0-1>   --palette-dark-text <hex>|default

A theme is named by its name (any case). Colors are #RRGGBB or #RRGGBBAA. A Space's
crest and icon are not part of its theme: shape and color them with arma crest.
```

## arma crest

```text
usage: arma crest <action> [options]

  show [--space <space>]        a Space's crest or icon, and its colors
  set [--space <space>] [options]
                                change a Space's crest or icon
  shuffle [--space <space>]     new parts and colors for a Space's crest

Without --space, the Space the front window shows.

Options:
  --style crest|icon            a heraldic crest, or a symbol or emoji alone
  --shape <name>                the crest's plate, such as shield, circle or seal
  --field <name>                how the field divides, such as plain or quarterly
  --band <name>                 the band across it, such as none, pale or fess
  --emblem <name>               the crest's figure, such as dragon, lion or rose
  --border <name>               the trim, such as none, line or laurel
  --finish flat|sheen|embossed
  --symbol <sf-symbol>          the icon's SF Symbol, such as leaf.fill
  --emoji <emoji>               the icon's emoji

  --field-color <hex>   --second-field-color <hex>   --band-color <hex>
  --emblem-color <hex>  --border-color <hex>         --edge-color <hex>
  --icon-color <hex>            the icon's color

arma crest show lists every name each part takes. The crest's colors are the
Space's own: no theme changes them, and they color nothing else in the window.
```

## arma extension

```text
usage: arma extension <action> [options]

  list [--space <s>] [--engine chromium|servo]
                           extensions with their id, version, engine, whether
                           they are on, and the Spaces they are in
  install <source> [--space <s>]
                           a Chrome Web Store id or listing address installs into
                           the Space (the front window's by default) once you
                           review it in Arma; an .xpi or an unpacked extension's
                           folder installs into Servo
  remove <extension> [--space <s>]
                           remove it from the Space, or from every Space
  enable <extension> [--space <s>] | disable <extension> [--space <s>]
                           turn a Chromium extension on or off
  info <extension>         what it is, asks for and where it runs

An extension is its id, the start of its id, or its name in any case.
```

## arma history

```text
usage: arma history <action> [options]

  search <text> [--space <s>] [--limit <n>] [--since <age>]
                           entries whose address or title hold every word,
                           newest first; --since takes 30m, 12h, 7d or 2w
  list [--space <s>] [--limit <n>]
                           the newest entries
  delete <url> [--space <s>]
                           remove every visit to <url>, from every Space that has
                           it unless --space names one
  clear [--space <s>] [--range hour|day|week|month|all] --yes
                           remove what the Space (the front window's by default)
                           visited in the range, all of it by default

Without --space, search and list read every unlocked Space.
```

## arma archive

```text
usage: arma archive <action> [options]

  search <text> [--space <s>] [--reason <r>] [--limit <n>] [--since <age>]
                           archived tabs whose title or address hold every
                           word, newest first; --since takes 30m, 12h, 7d or 2w
  list [--space <s>] [--reason <r>] [--limit <n>]
                           the newest archived tabs
  restore <entry>          bring the tab back as an open tab, with its own
                           back and forward history, and show it
  delete <entry>           remove the tab from the archive for good
  clear [--space <s>] [--range hour|day|week|month|all] --yes
                           remove what the Space archived in the range, all
                           of it by default; every unlocked Space without --space

An entry is the archived tab's id, or the start of it, from arma archive list.
--reason takes closed, automatic, synced or quickWindow.
Without --space, search and list read every unlocked Space.
```

## arma download

```text
usage: arma download <action> [options]

  list                     downloads with their id, state, progress, size and Space
  open <download>          open a finished download's file
  reveal <download>        show a finished download's file in Finder
  cancel <download>        stop a download while it runs
  retry <download>         download again one the site's choices blocked
  clear                    remove every download that ended from the list;
                           the files stay

A download is its id, or the start of its id from arma download list.
```

## arma passwords

```text
usage: arma passwords <action> [options]

  unlock [--space <s>] [--minutes <n>] [--raw]
                           unlock a Space's passwords for the terminal, with Touch ID
                           or your Mac password, for an hour (or fewer minutes); prints
                           export ARMA_SESSION="...", or the key alone with --raw
  lock [--all]             end this session, or every session
  status                   which Spaces allow the terminal, and this session
  list [--search <q>] [--site <host>] [--category <c>]
                           the session's passwords, without their secrets
  get password|username|email|notes|item <site|id> [--username <u>]
                           one field of a saved password, or all of it with item
  create <site> --username <u> (--password-stdin | --generate)
         [--email <e>] [--category <c>] [--subdomains] [--notes-file <path>]
                           save a new password
  edit <site|id> [--username <u>] [--new-username <u>] [--email <e>] [--category <c>]
       [--subdomains | --no-subdomains] [--password-stdin | --generate] [--notes-file <path>]
                           change a saved password
  delete <site|id> [--username <u>]
                           delete a saved password
  generate [--length <n>] [--no-lowercase] [--no-uppercase] [--no-numbers] [--no-symbols]
                           make a password with the Space's generator; no session needed

Every action but unlock, status and generate needs a session: run
eval "$(arma passwords unlock --space Work)" and the key is kept in
ARMA_SESSION for this shell, or pass --session <key>. A session reaches one
Space and lasts an hour at most; it ends sooner with lock, when Arma quits,
or when the Mac sleeps or locks. The Space must allow it: Settings › Space ›
Passwords › Allow command-line access.

A password is read from standard input with --password-stdin, never from the
command's words, so it stays out of your shell's history.
```

## arma automation

```text
usage: arma automation <action> [options]

  status                 whether automation is on, what it reaches, and how to connect
  on [--profile <space|ephemeral>] [--tabs opened|all] [--port <n>]
                         let testing frameworks connect, after Arma restarts
  off                    close the port, after Arma restarts
  set [--profile …] [--tabs …] [--port …]
                         change what it reaches without turning it on or off
  restart                quit and reopen Arma so the settings take effect

--profile names a Space whose profile tools drive, or ephemeral for an empty
profile that is forgotten when Arma quits. --tabs opened lets tools see only
the tabs they open; all lets them see the profile's existing tabs too.
```
