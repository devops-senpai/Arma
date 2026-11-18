#!/usr/bin/env python3
"""Draw Arma's app icons into Crest's icon files.

The mark is the Honor banner in Brand/AppIcons/ArmaHonor.svg. The default icon
flies it as designed; each palette variant recolors the banner with the
palette's color, on a light tint of that color in both appearances.

Every output keeps the name Crest gives it (Crest.icon, CrestWinter.icon,
CrestWinterPreview, CrestWinterDockLight and so on), so the asset catalog
settings, the icon picker and the Dock tile find Arma's art where they look
for Crest's, and no Crest file is renamed or removed. Each .icon gets
Assets/ArmaMark.svg and an icon.json that draws only it; the previews and
Dock images are rewritten in place as the PNGs Crest's image sets list.
Run it after changing the banner or a palette color."""
import json
import re
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent
ICON_ROOT = ROOT / "CrestShared/Resources/CrestIcon"
PREVIEWS = ROOT / "CrestShared/Resources/AppIconPreviews.xcassets"
BANNER = ROOT / "Brand/AppIcons/ArmaHonor.svg"
BANNER_FILL = "#313244"

BASE = ("Crest", BANNER_FILL)
VARIANTS = [
    ("CrestWinter", "#3B82F6"), ("CrestLion", "#D97706"), ("CrestStorm", "#475569"),
    ("CrestDragon", "#DC2626"), ("CrestMeadow", "#16A34A"), ("CrestIron", "#71717A"),
    ("CrestRiver", "#0E7490"), ("CrestSun", "#F59E0B"), ("CrestVigil", "#7C3AED"),
]

# How tall the banner stands on the 1024-point icon canvas. Icon Composer's
# squircle still clears its corners at this size.
BANNER_HEIGHT = 799

# Draws an SVG file into a square PNG of the given side, as the icon picker's
# preview image sets hold them.
RENDER_PREVIEW = """
import AppKit
let arguments = CommandLine.arguments
guard arguments.count == 4, let side = Int(arguments[3]),
    let image = NSImage(contentsOf: URL(fileURLWithPath: arguments[1])),
    let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: side, pixelsHigh: side, bitsPerSample: 8, samplesPerPixel: 4,
        hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)
else { fatalError("Expected an SVG, an output path and a side") }
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
image.draw(in: NSRect(x: 0, y: 0, width: side, height: side))
NSGraphicsContext.restoreGraphicsState()
guard let png = bitmap.representation(using: .png, properties: [:]) else { fatalError("Could not encode") }
try png.write(to: URL(fileURLWithPath: arguments[2]))
"""


def write_json(path, value):
    path.write_text(json.dumps(value, indent=2) + "\n")


def rgb(color):
    return tuple(int(color[i:i + 2], 16) / 255 for i in (1, 3, 5))


def hex_color(channels):
    return "#" + "".join(f"{round(c * 255):02X}" for c in channels)


def tint(color, amount=0.82):
    """`color` mixed toward white: the field the banner flies on."""
    return hex_color(c + (1 - c) * amount for c in rgb(color))


def banner_inner(color):
    text = BANNER.read_text()
    inner = re.search(r"<svg[^>]*>(.*)</svg>", text, re.S).group(1)
    return inner.replace(f'fill="{BANNER_FILL}"', f'fill="{color}"')


def view_box():
    """The banner file's viewBox: x, y, width, height."""
    text = BANNER.read_text()
    return [float(v) for v in re.search(r'viewBox="([^"]+)"', text).group(1).split()]


def placed(inner):
    """The banner's drawing, scaled to stand `BANNER_HEIGHT` tall and centered."""
    x, y, w, h = view_box()
    scale = BANNER_HEIGHT / h
    tx, ty = (1024 - w * scale) / 2 - x * scale, (1024 - h * scale) / 2 - y * scale
    return f'<g transform="translate({tx:.2f} {ty:.2f}) scale({scale:.4f})">{inner}</g>'


def mark_svg(color):
    return (
        '<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">\n'
        f"  {placed(banner_inner(color))}\n</svg>\n"
    )


def preview_svg(color):
    return (
        '<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">\n'
        f'  <rect x="0" y="0" width="1024" height="1024" rx="232" fill="{tint(color)}"/>\n'
        f"  {placed(banner_inner(color))}\n</svg>\n"
    )


def icon_document(color):
    red, green, blue = rgb(tint(color))
    field = {"automatic-gradient": f"extended-srgb:{red:.5f},{green:.5f},{blue:.5f},1.00000"}
    return {
        "fill-specializations": [{"value": field}, {"appearance": "dark", "value": field}],
        "groups": [{
            "layers": [{
                "fill-specializations": [
                    {"value": "none"}, {"appearance": "dark", "value": "none"}, {"appearance": "tinted", "value": "none"},
                ],
                "image-name": "ArmaMark.svg",
                "name": "ArmaMark",
            }],
            "name": "Arma Layers",
            "shadow": {"kind": "neutral", "opacity": 0.6},
            "translucency": {"enabled": True, "value": 0.2},
        }],
        "supported-platforms": {"circles": ["watchOS"], "squares": "shared"},
    }


def main():
    developer = Path(subprocess.check_output(["xcode-select", "-p"], text=True).strip())
    exporter = developer.parent / "Applications/Icon Composer.app/Contents/Executables/ictool"
    with tempfile.TemporaryDirectory(prefix="arma-icon-export-") as temporary:
        working = Path(temporary)
        padding_tool = working / "pad-mac-app-icon"
        preview_tool = working / "render-preview"
        (working / "render-preview.swift").write_text(RENDER_PREVIEW)
        subprocess.run(["xcrun", "swiftc", str(ROOT / "Scripts/pad-mac-app-icon.swift"), "-o", str(padding_tool)],
                       check=True)
        subprocess.run(["xcrun", "swiftc", str(working / "render-preview.swift"), "-o", str(preview_tool)], check=True)
        for name, color in [BASE, *VARIANTS]:
            icon = ICON_ROOT / f"{name}.icon"
            (icon / "Assets").mkdir(parents=True, exist_ok=True)
            (icon / "Assets/ArmaMark.svg").write_text(mark_svg(color))
            write_json(icon / "icon.json", icon_document(color))
            # Crest's preview image sets list a 3x icon.png and icon-dark.png;
            # Arma's icon looks the same in both appearances.
            drawing = working / "preview.svg"
            drawing.write_text(preview_svg(color))
            for filename in ("icon.png", "icon-dark.png"):
                subprocess.run([str(preview_tool), str(drawing), str(PREVIEWS / f"{name}Preview.imageset" / filename),
                                "180"], check=True)
            # Complete Mac icons at 1x and 2x from Apple's renderer, for the
            # Dock and the picker. Clear and tinted come from Icon Services.
            for appearance, rendition in [("Light", "Default"), ("Dark", "Dark")]:
                target = PREVIEWS / f"{name}Dock{appearance}.imageset"
                for scale in (1, 2):
                    face = working / "face.png"
                    subprocess.run([str(exporter), str(icon), "--export-image", "--output-file", str(face),
                                    "--platform", "macOS", "--rendition", rendition,
                                    "--width", "412", "--height", "412", "--scale", str(scale)],
                                   check=True, stdout=subprocess.DEVNULL)
                    filename = "icon.png" if scale == 1 else "icon@2x.png"
                    subprocess.run([str(padding_tool), str(face), str(target / filename), str(512 * scale)], check=True)
    print(f"Drew Arma's icon into {1 + len(VARIANTS)} Crest icons, previews and Dock images "
          f"from {BANNER.relative_to(ROOT)}.")


if __name__ == "__main__":
    main()
