# The Strangest Flea Market — NYC, 1985

Godot 4.4.1 living-world prototype adapted from the prior Sakura scene to TSFM lore. A dense blue-hour Manhattan market with tenements, stoops, fire escapes, subway entrances, stalls and a restricted portal checkpoint. The map is a generated illustrated background; residents and effects are independent game objects.

## Play
Open project.godot in Godot 4.4.1+ and press F5. The live browser edition uses the same Godot scene.

- Click a street to walk; click a named vendor to walk there and talk.
- WASD / arrows: walk inside the street and aisle network.
- E: talk nearby. I: wallet/inventory. H: hide all HUD overlays.
- Drag: pan. Wheel / + / -: zoom. F: follow your character.
- 0.7x / Home: initial wide view. Space: pause. Esc: close panels.
- Fullscreen button enters fullscreen; the canvas already fills the browser viewport.

Starts at 0.7 camera zoom. Camera bounds and minimum zoom cover the viewport at every size, with no exposed map margins. A very wide viewport can require a higher cover zoom. 2400 × 1600 world, illustrated art detail rather than infinite-detail zoom.

## Living world
64 independently roaming residents, including humans, aliens, androids and rabbitlike visitors. Piper is a dachshund newspaper vendor. Stella is a Rottweiler in a rain suit selling cakes. Meepo and Harley run trinkets and potions. Buddy-Bot handles resident services. Token exchange and portal security explain the rules. Vendors idle and pace at their counters; bird sentinels watch rooftops. Animated portal specks, vent steam and optional city ambience.

## First Shift
A new short playable story written for this prototype: accept Piper's newspaper delivery, bring it to Stella, take her cake to Meepo & Harley, then return their signed receipt to Piper for 25 tokens. The wallet starts with 100 tokens, resident ID, apartment key and subway pass. Buying cake costs five tokens. Progress saves locally through Godot user storage (browser persistence depends on browser permissions); no account or server save.

## Lore used
June 19, 1984 satellite contact; NYC becomes an interstellar market, 1985 setting; work to reside; Earth currency invalid inside market; tokens and barter; nonhumans and market goods restricted to NYC; Earth on probation and humans barred from outbound portals; rooftop bird sentinels and android patrols; theft causes banishment; no lethal weapons or invasive/toxic/stolen goods. Dialogue and the delivery errand are new adaptation writing, not quotations from preexisting canon.

## Scope
The scene is an exploration prototype. No enterable buildings, multiplayer, vehicles, full economy or actual transit. Foreground occlusion remains approximate because stall canopies and railings are part of the background art. Named characters are stylized procedural pixel sprites, not exact portrait likenesses.

## Build
Godot 4.4.1 --headless --path . --export-release Web
python prepare_web.py
The helper compresses the WASM engine and installs a browser streaming-decompression loader. Serve web/ over HTTP; modern browser with WebGL2 and DecompressionStream required. dist/ is the hosted copy.

## Art
Built-in image generation prompt: wide isometric pixel-art NYC interstellar market, 1985, blue hour; brick tenements, fire escapes, rooftop water towers, subway entrances, old bodegas, strange stalls, exchange booth and portal checkpoint; edge-to-edge terrain, no people, vehicles or UI. Asset: assets/tsfm-1985.png. This replaces the garden setting while preserving the living-scene game approach.

Godot engine: https://github.com/godotengine/godot — MIT license: https://godotengine.org/license/
