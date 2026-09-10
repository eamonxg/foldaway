# Foldaway DMG background

Ready-to-use installation backgrounds with empty app and Applications positions. The artwork includes no app icon or folder icon.

| File | Size | Purpose |
| --- | --- | --- |
| `background.png` | 660 × 400, 72 DPI | Final 1x background |
| `background@2x.png` | 1320 × 800, 144 DPI | Final Retina background |
| `background.tiff` | 1x + 2x representations | Recommended Finder background |
| `background-no-text.png` | 660 × 400 | Artwork without instruction |
| `background-no-text@2x.png` | 1320 × 800 | Retina artwork without instruction |
| `source-generated.png` | Original generated size | Preserved generated artwork |
| `layout.json` | JSON | Finder positions, typography, and export metadata |

Use a 660 × 400 Finder canvas with 96-point real icons centered at **(180, 160)** and **(480, 160)**. These top-left-origin coordinates cover the shallow recesses, whose artwork centers are approximately (185, 160) and (475, 160).

The single instruction, **Drag Foldaway to Applications**, is typeset after generation with the macOS system font (`NSFont.systemFont`, SF Pro, 14 pt medium), centered at **(330, 330)**. The resolved system font name is recorded in `layout.json`.

Regenerate from the repository root on macOS:

```sh
swift scripts/export-dmg-background.swift
```

To use a different source and destination:

```sh
swift scripts/export-dmg-background.swift /absolute/path/source.png /absolute/path/output-directory
```

These are artwork assets only; the existing app and DMG build flow is unchanged.
