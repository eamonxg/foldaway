# Foldaway branding v1 prompts

App icon and DMG artwork generated with the built-in image generation tool. Production dimensions and system-font typography are exported with AppKit. Menu bar frames are deterministic vector artwork.

## App icon final transparent cutout

BACKGROUND REMOVAL / TRUE TRANSPARENT PNG.
Use case: background-extraction. The input is a macOS app icon over a grey checkerboard. Remove the entire grey checkerboard outside the squircle. REPLACE IT WITH ACTUAL TRANSPARENT ALPHA (RGBA PNG, alpha zero outside the icon). A drawn checkerboard is unacceptable. The output must contain no checkerboard pixels, no backdrop color, no shadow outside the rounded square. Keep the dark rounded-square plate and everything inside it unchanged. Keep smooth clean antialiased edges and generous empty transparent padding. No text or additional objects. This is an icon cutout for macOS, not a mockup.

## App icon edge cleanup revision

Use case: precise-object-edit.
Edit target: the attached Foldaway application icon. Fix ONLY the plate's outer edge cleanup.
Preserve the exact laptop, screen light gradient, top edge dissolving blur, graphite plate material, plate size, bevel, lighting and composition.
Remove ALL bright saturated blue/cyan/purple speckles, fringe, stray pixels, disconnected islands and bumps outside and along the squircle contour, particularly above the top rim near the center-right. The whole OUTSIDE of the squircle must be fully transparent alpha=0. The plate silhouette must be one smooth continuous Apple squircle with perfectly clean softly antialiased edges. No outside shadow. Keep the 10% transparent padding. No redesign, no text, no added objects. Output square PNG with genuine alpha transparency, preferably 1024x1024.

## App icon

Use case: logo-brand.
Asset type: production macOS application icon for Foldaway, square 1024x1024 PNG with genuine alpha transparency.
A macOS Big Sur-style app icon, squircle (Apple superellipse) rounded-rectangle plate with approximately 10% completely transparent padding on all four sides. Graphite-to-near-black vertical plate gradient (#262E45 at top to #0A0D14 at bottom), a soft top rim light and subtle inner bevel. Centered on the plate: a minimal, front-facing open MacBook rendered as a clean geometric glyph, tilted slightly back in shallow 3/4 perspective. Screen vertical gradient from warm lamp-light amber (#FCD6A3) at its BOTTOM hinge edge, through periwinkle blue-grey (#9EA9D1), to deep charcoal (#1A1C29) at its TOP far edge. The top far edge is visibly blurred and darkened, dissolving into the plate as if the display is folding away. A thin light-grey hinge bar under the screen with a soft specular highlight. Physically based soft studio lighting, gentle contact shadow under the laptop confined inside the plate, crisp anti-aliased plate edges. Premium Apple software icon aesthetic, minimal. No keyboard keys detail. The squircle must have REAL transparency outside it, not a simulated checkerboard and not a solid backdrop.
No text, no letters, no UI chrome, no watermark, no drop shadow outside the squircle, no cartoon style, no glossy 2010 skeuomorphism, no clutter.

## DMG background

Use case: ui-mockup.
Asset type: a finished background-only image for a macOS DMG installer, 1320x800 px landscape, exact aspect ratio 33:20, opaque, flat 2D.
Extremely minimal deep graphite background with a very soft vertical gradient (#141821 top to #0B0E14 bottom). Faint large-radius warm amber glow bleeding from upper-left, fading to cool blue-grey toward lower-right, echoing a screen dimming as laptop lid closes. Two EMPTY UNMARKED shallow circular recesses of equal size on one shared horizontal line at x=360 and x=960, y=350 (image pixel coordinates from top left), about 190 px diameter each. These are very subtle tonal depressions, not rings or placeholders with symbols. The recess areas must be completely empty and clean because real Finder icons will be overlaid later. Between the empty recesses at y=350, one single thin elegant right-pointing arrow from about x=570 to x=750, with a delicate 2px line and small chevron head, muted grey-white at 45% opacity and a subtle amber-to-blue gradient along its length. Generous uninterrupted blank space near the bottom for later typesetting. Very subtle fine-grain noise to prevent banding. Restrained native Apple software aesthetic.
Hard constraints: NO text, NO letters, NO app icon, NO laptop drawing, NO folder icon, NO Applications folder, NO logos, NO watermark, NO arrows other than the single thin one, NO window chrome, NO borders, NO perspective, NO 3D, NO busy patterns, NO gradient banding. This is ONLY the installer background. Do not draw the real icons that Finder will display.

## DMG placement revision

Use case: precise-object-edit. Edit target: the provided macOS DMG background.
Keep the same landscape aspect ratio, dark graphite base, fine grain texture, single right arrow, and blank lower half.
Fix just the placement and subtlety:
Move the LEFT EMPTY RECESS farther left to precisely 27.27% of full canvas width. Move the RIGHT EMPTY RECESS farther right to precisely 72.73% of full canvas width. Both centers at 43.75% of the canvas height. The horizontal distance between their centers must be 45.46% of canvas width; do not keep the existing more centrally clustered layout. Both circles same diameter, 14.4% of full canvas width. Recesses should be much subtler and shallower: reduce their contrast/rim visibility by 60%.
Keep the single thin right-pointing arrow horizontally centered at 50% width and vertically at 43.75% height, width 13.64% of canvas.
Reduce the warm amber glow in upper left by 65%, so it is faint and subdued rather than orange. Keep lower-right cool.
No text, no icons, no folder graphics, no laptop drawings, no labels, no logos, no window chrome. Empty recesses only. Prefer output exactly 1320x800 px.
