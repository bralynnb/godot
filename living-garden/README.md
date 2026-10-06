# Sakura — A Living Garden

A Godot 4.4.1 scene built from the supplied pagoda landscape reference. The art was adapted with image generation; the landscape is an illustrated background, with independently simulated visitors, boats, petals, birds, and a water shader.

## Play
- Open project.godot in Godot 4.4.1 or later and press F6/F5.
- Windows: extract the supplied Windows build and run Sakura.exe.
- Browser: serve the web directory over HTTP, or use the hosted link.

Click paths to walk. WASD/arrows move within paths. Drag to pan, wheel or +/- to zoom (up to 8x). Home/Overview fits the whole garden. F/Follow tracks your visitor (gold pointer). Space pauses. E near the west end of the central red bridge transfers to the west riverbank and back. Discover five landmarks. Clouds, dusk, ambience and fullscreen have buttons.

52 visitors choose routes and pause at destinations; all figures are simulation objects. Nine boats and their passengers move on authored river routes. Three boat designs, directional pixel walkers, birds, drifting petals, water ripples and optional synthesized ambient sound.

## Scope
This is an exploratory living-world prototype. Background terrain/buildings are illustrated, not editable tiles. Zoom magnifies existing pixel detail. No building interiors, economy, multiplayer or save system. The east upper promenade is currently visitor-only; ferry reaches the west upper bank. Bridge railings and some foliage are baked into the background, so foreground occlusion is approximate. Desktop mouse/keyboard controls are the tested target.

## Art prompt
Built-in image generation edited the supplied reference: preserve pagoda, paths, bridges, trees, cliffs and shoreline; remove all people, boats and clouds; reconstruct terrain behind them, keep pixel-art composition and palette. Image is included at assets/garden.png.

## Engine
Godot: https://github.com/godotengine/godot — MIT license, https://godotengine.org/license/
