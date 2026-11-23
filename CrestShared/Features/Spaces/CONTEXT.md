# CrestShared/Features/Spaces

How a Space looks and is picked: its branding (banner, crest, identity
artwork, textures), the Crest Studio that composes a crest step by step
(`Components/Forge/`), the branding editor, the inline name field, and the
Space selectors (menu picker, chip rail, icon picker) other features reuse.

## Goal

One Space identity drawn the same wherever it appears, edited in one studio
on every shell.

## Contents

| Path | What it is |
| --- | --- |
| `Components/BrowserSpaceBranding/` | Banner background and the banner, crest, identity and shape views |
| `Components/BrowserSpaceBrandingEditor/Studio/` | The Crest Studio's controls, emblem picker and the folder, command palette, popover and text color sections the Forge shows |
| `Components/Forge/` | `BrowserCrestForge` and the Crest Studio stage beside the live sidebar |
| `Components/BrowserSpaceThemes/` | What the Forge shows for a theme: `BrowserThemeForgeSubject` and `BrowserSpaceThemeFileActions`, the theme stage preview and the background image section |
| `Components/BrowserSpaceBackdrop/` | A Space's background image on this device: `BrowserSpaceBackdropStore` and `BrowserSpaceBackdropLayer` |
| `Components/CrestSpaceSelector/` | Space menu picker, chip rail and icon picker |
| `Components/` (files) | Inline Space name, the customization picker, the touch appearance workspace for setup |
| `Models/` | Studio steps, branding values such as gradient-angle direction, and `BrowserDefaultSpaceLook` (the theme new Spaces wear) |
| `Services/BrowserSpaceBranding/` | Rendering a Space symbol to artwork |
| `Support/` | Heraldry and branding presentation, tab icon accent colors, `SpaceModel` tab lists, the branding preview fixture |

## Depends on

The core's `SpaceModel` and branding values through
`CrestShared/Infrastructure/Core/`, `DesignSystem/`, `Sidebar/` (switcher
layout), `Settings/` (appearance previews and pane chrome). Used by
`Sidebar/` (header and switcher), `Settings/` (Space sections),
`Onboarding/` (manual setup), `Credentials/` and `TransientBrowsing/` (Space
identity), `Browser/` (banner backdrop), the Space editors in
`CrestMac/Features/Settings/` and `CrestMobile/Features/Settings/`, and
`CrestMac/Features/Onboarding/`.

## Rules

- Spaces live in the core; Swift edits them through intents (skill, "Architecture").
- A Space is the privacy boundary; what it owns is listed in `Documentation/ARCHITECTURE.md`, "Space isolation".
- Colours come from the Crest tokens and template house palettes, never system rainbow colours (skill, "Windows and UI").
- Previews reuse the feature's fixture, `CrestShared/Features/Spaces/Support/BrowserSpaceBrandingPreviewFixture.swift`, with fixed identities and dates (`Documentation/RepositoryGuardrails.md`, "Feature organization").

## Read next

`Documentation/ARCHITECTURE.md` ("Space isolation"), then `Sidebar/` for
where a Space is shown and `Settings/` for where it is edited.
