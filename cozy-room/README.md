# Fireside — a real Godot 4.4.1 room

A self-contained 3D voxel reading room inspired by the supplied reference. All furnishings, books, plants, window, rug and fireplace are geometry built in `room.gd`. No external assets or dependencies.

## Play
https://cozy-godot-fireplace.bralynn.chatgpt.site

- Left drag: orbit.
- Right drag or Shift + left drag: pan.
- Mouse wheel: zoom.
- Touch: one finger orbits, two fingers pan and pinch to zoom.
- Buttons reset the view, switch day/night, toggle the fire or enter fullscreen.
- Escape exits fullscreen.

The fire is an animated stylized effect with emissive flame meshes, rising embers, glowing logs and a flickering shadow-casting point light. It is not a fluid simulation. Single-threaded Compatibility renderer supports WebGL 2 without cross-origin isolation.

## Edit
Import `project.godot` into Godot 4.4.1 and press F6/F5. The scene is generated at runtime; edit geometry and colors in `room.gd`.

## Export
Install the matching Godot Web export templates, then run:

```
godot --headless --path . --export-release Web
python3 prepare_web.py
```

Serve `dist/` over HTTP(S). Do not open the HTML as a local file. The small loader decompresses the gzipped WASM using the browser's DecompressionStream, keeping individual hosted assets below 25 MiB. Use a current WebGL 2 browser.
