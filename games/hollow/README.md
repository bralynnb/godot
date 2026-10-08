# Hollow — A Quiet Descent

A real Godot 4.5 project: three connected isometric dungeon rooms using the supplied animated character. No combat, enemies, inventory, or objectives. Just walk, explore, and enjoy the ambience.

## Run in Godot

Open `project.godot` in Godot 4.5 and press F6/F5. The project uses the Compatibility renderer.

## Controls

- WASD or arrow keys: walk in eight directions.
- Mouse wheel or +/-: zoom. Z: overview.
- L: toggle live lighting. R: toggle specular floor response.
- Escape: pause/resume.
- M: mute/unmute.
- F: fullscreen in the desktop game. The browser version also has a fullscreen button.
- Touch: drag anywhere on the game to walk. Release to stop.

Exit the entry vault through the opening along the lower-right edge. Walk around the cistern and take the small doorway in the back-right wall to the moon chamber. Every connection works in both directions.

## Implementation

- Angled 2:1 isometric floor projection, raised back walls, and cutaway front walls.
- 960 × 540 logical canvas, nearest-filtered pixel textures.
- Screen-relative controls: right moves right on screen. Collision uses unprojected floor coordinates; the character stays upright and unstretched.
- All 64 supplied GIF frames extracted into six views; views are selected and mirrored for eight-direction movement. Original appearance is retained; no generative redraw.
- CharacterBody2D foot collision, normalized diagonal input, short acceleration/deceleration, animation driven by actual travel.
- Real PointLight2D torchlight with gentle flicker, cool ambient light and moonlight.
- Higgsfield-generated unlit entry vault, separate pillar and iron-sconce sprites. No flames, light pools, window beams, or floor glare baked into the entry background.
- Live PointLight2D lighting, occluders, projected height shadows, animated flame geometry and optional specular material response. Normal/specular maps describe surfaces only.
- Procedural subsidiary rooms, animated water highlights, dust and looping ambient audio.
- Three rooms with short fade transitions. No third-party game framework.

## Web export

Install the Godot 4.5 export templates and use the Web preset (thread support off). Standard exports can be served from any static HTTP host; `file://` does not work. The included hosted build compresses the unmodified official Godot 4.5 WASM runtime and expands it in the browser with DecompressionStream. It needs a modern browser with WebGL2.

The `dist` folder is generated output; source assets and scripts are in `assets`, `scripts`, and `scenes`.

## Asset notes

The character was supplied by the user; no additional ownership or redistribution rights are asserted. The Godot engine is MIT licensed; its license and third-party copyright notices are included.

## Verification

Godot 4.5 was used to import and run the project. Automated movement checks verified all four room transitions, north wall collision, cistern collision, stop-on-release, and reachability of all three rooms. Native rendered screenshots were inspected for all room layouts.
