# Fireside — interactive Godot room

Play: https://cozy-godot-fireplace.bralynn.chatgpt.site

A real Godot 4.4.1 voxel room with four walls, nighttime window lighting, animated fire and a controllable resident.

## Controls
- WASD: walk with furniture and wall collision.
- Click an object: select a specific book, candle, plant or furnishing.
- Drag: orbit; right-drag or Shift-drag: pan; scroll: zoom.
- F: switch between room view and first person. Mouse looks around in first person; click selects the item under the crosshair.
- Escape: release the mouse to use buttons in first person; click the room to capture it again.
- E: pick up the selected small object or sit in the selected chair/sofa.
- Space: stand up. Sit/Stand buttons are also available.
- Push/Pull: move the selected nearby object in 24 cm increments, subject to space.
- Q/R or Rotate buttons: rotate a nearby selected item by 15 degrees.
- I: open inventory. Select a stored item and Place to put it in front of you, or select a nearby table/bookcase first to place it on top.
- Walls: cycles Auto, Hidden, All. Auto hides the two walls closest to the overhead camera; first person shows the whole enclosure. Hidden walls still prevent walking out of the room.

Small plants, individual books and candles go into inventory. Furniture stays in the room and can be pushed, pulled and rotated. Items supported by a table or bookcase move with it. The fireplace stays fixed. Standing up finds a clear adjacent spot.

Inventory, object positions, rotations, player position and fire state are saved in this browser's Godot user storage. They are device-local; clearing site storage removes them. There are no NPCs, network play or cloud saves.

## Source
Import `project.godot` into Godot 4.4.1 and run it. `room.gd` builds the original geometry and fire. `interactive.gd` adds the resident, collisions, UI, inventory and wall cutaways. All geometry is generated at runtime.

## Build
Install matching Godot Web templates, then:
```
godot --headless --path . --export-release Web
python3 prepare_web.py
```
Serve `dist/` over HTTP(S) in a current WebGL 2 browser. The browser decompresses the compressed WASM engine; no cross-origin isolation or worker threads are required.

## Checks
```
godot --headless --path . -- --test-room
```
Checks four-wall camera cutaways, all-wall hiding, first-person enclosure, picking a specific book through the open bookcase, inventory pickup/placement, sitting/standing and furniture transforms/bounds. Native OpenGL screenshots verify both opposite room angles and first person.
