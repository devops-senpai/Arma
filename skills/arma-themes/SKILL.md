---
name: arma-themes
description: Make, edit, share and apply Arma themes, and shape a Space's crest or icon, from the terminal or a theme file. Use when asked to create a theme for Arma, recolor a Space's sidebar, folders or command palette, give a theme a dark look, port a color scheme such as Catppuccin or Nord to Arma, or export and import theme files.
---

# Arma themes

A **theme** colors a window: the sidebar background and its pattern, the sidebar's text,
folders, and the command palette. Themes live in a library (Settings › Themes on Mac), and
each Space wears one. Editing a theme changes every Space that wears it.

A Space's **crest** (or icon) is separate. It keeps its own colors whatever theme the Space
wears, and `arma crest` shapes it.

Arma must be open. Agents and page control can stay off: themes need neither. If `arma` is
not on the PATH, use `/Applications/Arma.app/Contents/Helpers/arma`.

## The quick way: flags

```sh
arma theme list                                   # the library; * marks the shown Space's theme
arma theme new Dusk --background "#1b1f2a,#3a2f5b" --style gradient --angle 135 \
     --sidebar-text "#e6e9ef" --folder-color "#7a8bb0"
arma theme use Dusk --space Work                  # have a Space wear it
arma theme edit Dusk --palette-dark "#101218" --palette-dark-opacity 0.7
arma theme edit --space Work --dark --background "#101218,#3a2f5b"   # the dark look of Work's theme
```

`--background` takes one to three colors: background, accent, pattern. The accent colors
selected tabs, pins, the address field and the Space picker. Run `arma theme help` for
every look option.

## The complete way: a theme file

A theme file is JSON with one section per part of the look. A file names only the parts it
changes; everything else keeps the plain look.

```json
{
  "name": "Dusk",
  "background": {
    "colors": ["#1b1f2a", "#cba6f7", "#45475a"],
    "style": "banner",
    "pattern": "solid",
    "angle": 45,
    "intensity": 1,
    "readabilityFade": 0,
    "texture": false,
    "textColor": "light",
    "sidebarText": "#e6e9ef",
    "sidebarSecondaryText": "#a6adc8"
  },
  "icon": { "color": "#cba6f7" },
  "folders": {
    "color": "#fab387",
    "backColor": "#9297ba",
    "outlineColor": "default",
    "highlightColor": "#fab387",
    "highlightOpacity": 0.4,
    "intensity": 0.25
  },
  "commandPalette": {
    "light": { "tint": "#ffffff", "opacity": 0.5, "text": "#1e1e2e" },
    "dark":  { "tint": "#1e1e2e", "opacity": 0.92, "text": "#cdd6f4" }
  }
}
```

| Field | Takes |
| --- | --- |
| `background.colors` | one to three colors: background, accent, pattern |
| `background.style` | `banner` (a flat field with a pattern) or `gradient` |
| `background.pattern` | `solid`, `split`, `bands`, `diagonal`, `chevron`, `quartered`, `stripes`, `checkered`, `lozenges` |
| `background.angle` | degrees, the gradient's direction |
| `background.intensity`, `readabilityFade` | 0 to 1 |
| `background.textColor` | `automatic`, `light`, `dark`, `system` |
| `background.sidebarText`, `sidebarSecondaryText` | a color, or `default` |
| `folders.*Color` | a color, or `default` |
| `folders.highlightOpacity`, `folders.intensity` | 0 to 1 |
| `commandPalette.light` / `.dark` | `tint`, `opacity` (0 is glass alone, 1 is solid), `text` |

Colors are `#RRGGBB` or `#RRGGBBAA`. The word `default` lets a chosen color go.

```sh
arma theme import ./dusk.json                  # save the file as a theme
arma theme import ./dusk.json --name "Dusk 2"  # under another name
arma theme edit Dusk --from-file ./dusk.json   # apply a file over a theme that exists
arma theme show Dusk > ./dusk.json             # a theme back out as a file, to share
```

The fastest start is an existing theme: `arma theme show "Catppuccin Mocha" > base.json`,
change the colors, import it under a new name.

## A dark look

A theme can carry a second look that Spaces wear while Arma's windows are dark.

```sh
arma theme edit Dusk --dark --background "#0f1117,#8aadf4"      # edit the dark look with flags
arma theme edit Dusk --dark --from-file ./dusk-dark.json        # or apply a second file as it
arma theme edit Dusk --unpair-dark                              # back to one look; the dark look stays in the theme, off
```

In a file, a top-level `"dark"` object holding the same sections does the same, and
`"darkLook": false` keeps it there turned off (left out, a `dark` object is worn). Editing
the dark look with `--dark` turns it back on.

## Start over on one part

```sh
arma theme reset folders Dusk                    # also background, icon, command-palette, all
arma theme reset command-palette --space Work --dark
```

## The crest

```sh
arma crest show --space Work      # its parts and colors, and every name each part takes
arma crest set --space Work --shape banner --emblem crane \
     --field-color "#1d2a44" --emblem-color "#f4f1ea"
arma crest set --space Work --style icon --symbol leaf.fill --icon-color "#a6e3a1"
arma crest set --space Work --style icon --emoji "🦊"
arma crest shuffle --space Work   # new parts and colors
```

`arma crest show` lists the shapes, fields, bands, emblems, borders and finishes this
version knows. Read it rather than guessing a name.

## Make a theme that reads well

1. Pick the background first, then check text against it: set `textColor` to `light` on a
   dark background and `dark` on a light one, or name `sidebarText` exactly.
2. Give `sidebarSecondaryText` less contrast than `sidebarText`. It colors quieter text
   such as New Tab and the address field's prompt.
3. Keep the accent distinct from the background: it marks the selected tab.
4. Set the command palette for both `light` and `dark`, with a `text` color that reads on
   each tint. An opacity near 0.9 keeps text legible over a busy page.
5. Apply it to a Space and look: `arma theme use <name> --space <space>`. Changes show in
   the running app at once, so adjust with `arma theme edit` and look again.

## Rules

- `arma theme delete` refuses a theme a Space still wears. Move those Spaces to another
  theme first.
- Editing a theme changes every Space using it. To change one Space alone, duplicate the
  theme (`arma theme duplicate <theme> --name <new>`), have the Space use the copy, and
  edit that.
- A theme never changes a crest's colors, and a crest's colors color nothing else.
