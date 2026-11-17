---
title: Customize and arrange Spaces
description: Design a Space in Crest Studio, customize its folders, and choose its browsing and cleanup settings.
slug: /customize-spaces
keywords: [Crest Studio, Space Forge, theme, gradient, crest, emoji, monogram, folders, cleanup, reorder, Appearance, add Space, rename Space]
---

# Customize and arrange Spaces

Open a Space’s context menu to edit it, or open its page in Settings. On Mac, select the Space in the Settings sidebar; on iPhone and iPad, choose it in **Settings → Spaces**. A strong visual identity makes a profile boundary obvious before you type a password or open a work account.

## Choose an identity

Crest offers two presentation styles:

- **Banner** uses Crest Studio: begin with a template, then choose a shape, field division, pattern, trim, and heraldic artwork. Use independent colors for the parts of your design, or make an identity with an emoji, monogram, or searchable SF Symbol.
- **Gradient**, the last choice in Crest Studio's **Sidebar** step, blends one to three colors with direction, intensity, and optional texture.

The result appears in the Space picker and browser chrome on Mac, iPad, and iPhone.

Crest Studio is on the Space’s Appearance page. The crest sits on the Space’s own sidebar background, with its colors named by what they paint:

- **Crest:** Field, Second field, Band, Emblem, Border and Edge. A color for a part the crest doesn’t draw is dimmed.
- **Sidebar:** Background, Accent (selected tabs, pins, the address field and the Space picker) and Pattern.

Click or tap a color to choose one of the templates’ tinctures or a custom color. Below the crest, work through **Start from**, **Shape**, **Field**, **Band**, **Emblem**, **Border**, **Finish** and **Sidebar**; each step shows your crest with each choice applied. On iPhone, the steps are a list showing what each has chosen; tap one to open it. Choose **Icon** at the top of **Emblem** to use an SF Symbol or emoji instead of a crest. **Shuffle** suggests a new crest in the templates’ colors, and **Undo** steps back through your changes. **Reset Appearance** and **Artwork Credits** are in the **…** menu on the Space’s page.

## Customize folders

Choose folder color intensity and text color on the Space’s Appearance page. Individual folder menus let you set colors, search the full SF Symbols catalog, or choose emoji. You can show a custom icon on its own instead of the animated folder artwork. In **Settings → Appearance**, enable **Tint Folder Title** to use semibold titles in the folder’s color, adjusted for stronger contrast against light or dark sidebars.

## Share a theme

On Mac, use the export and import buttons under the theme list in **Settings → Themes** to save a theme as a file or add one someone shared. The `arma` tool inside Arma does the same from the terminal while Arma is open. It needs only Arma running; agents can stay off.

```sh
A=/Applications/Arma.app/Contents/Helpers/arma
$A theme list                                   # * marks the shown Space's theme
$A theme show Dusk > ~/Desktop/dusk.json        # a theme as a file
$A theme import ~/Desktop/dusk.json             # save a file as a theme
$A theme edit Dusk --folder-color "#7a8bb0" --palette-dark "#101218" --palette-dark-opacity 0.7
$A theme edit --space Work --dark --background "#101218,#3a2f5b"   # the theme Work uses, dark look
$A theme use Dusk --space Work
$A crest set --space Work --shape banner --emblem crane --field-color "#1d2a44" --emblem-color "#f4f1ea"
$A crest show --space Work                      # its parts, colors, and every name each part takes
```

`arma theme` makes, edits, resets and picks themes; `arma crest` shapes a Space's own crest or icon, whose colors no theme changes. To change one Space's look, edit the theme it uses with `arma theme edit --space <name>`, or give it another with `arma theme use`.

A theme file is JSON holding a Space's look by the names Arma gives its parts, and a theme can name only the parts it changes:

```json
{
  "version": 2,
  "name": "Dusk",
  "colors": ["#1b1f2a", "#3a2f5b"], "themeMode": "gradient", "gradientAngle": 135, "bannerStrength": 0.8,
  "symbolColor": "#ffd166", "folderColorIntensity": 0.3,
  "dress": {
    "text": { "color": "#e6e9ef" },
    "folders": { "color": "#7a8bb0", "backColor": "#5c6b8a", "outlineColor": "default" },
    "commandPalette": { "light": { "tint": "#ffffff", "opacity": 0.5 }, "dark": { "tint": "#101218", "opacity": 0.7, "textColor": "#cdd6f4" } }
  }
}
```

Colors are `#RRGGBB` or `#RRGGBBAA`; the word `default` lets a chosen color go. A `"dark"` object with the same members gives the Space its look for dark windows, `"darkLook": false` keeps that look in the file turned off, and `arma theme edit --dark --from-file` applies a second theme file as that look. Theme files from earlier versions still open. Run `arma theme help` and `arma crest help` to see every option.

## Customize the browser around your Spaces

Open **Settings → Appearance** for device-wide appearance: a left- or right-side sidebar, borderless pages, tab shape and scale, pinned-tab layout, address-field colors, and a default page zoom from **50% to 300%**. Selected tabs, pins, and the address field follow the current Space’s color; turn off **Follow Space accent** to pick a custom color instead. Presets and a live preview help you find a starting point; each changed setting has its own reset.

Choose an app icon palette here too. These controls change the browser on this device; a Space’s identity belongs to that Space and stays on its own Appearance page.

## Add and arrange Spaces

On Mac, click **+** next to the Spaces heading in the Settings sidebar to add a Space. Its Appearance page opens with the name ready to type. Right-click a Space there, or use the **…** menu on its page, to rename it, edit its crest, lock it, or delete it. Crest needs at least one Space. Choose **New Sub-Space** from the same menu for a Space that shares this one's sign-ins; see [Sub-Spaces](./sub-spaces.md).

Drag a Space in the picker to reorder it. In the Mac Settings sidebar, click the pencil next to the Spaces heading, drag Spaces by their handles, then click the checkmark; or right-click a Space and choose **Move Up** or **Move Down**. On iPhone and iPad, use the order controls in **Settings → Spaces**. Position matters for **Control-1** through **Control-9**, so put frequently used Spaces first. A group's Sub-Spaces stay together after their primary, and dragging the primary moves the whole group.

## Automatic cleanup

Each Space can archive unpinned current tabs after **12 hours, 24 hours, 7 days, or 30 days**, or keep them until you close them. On Mac, set this with **Archive current tabs** on the Space’s Browsing page, and choose **Archive Now** to run it right away. Cleanup moves tabs into the recoverable Archive; it does not silently erase them.

Pinned sites, saved tabs, folders, and tabs marked **Keep Loaded** have different roles from ordinary current tabs. Use a saved tab for something you intend to revisit, and Keep Loaded only when the live in-page state matters.
