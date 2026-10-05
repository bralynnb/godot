# The Strangest Flea Market — native Godot port

Godot 4.4.1, GDScript, Compatibility renderer. Open project.godot and run Main.tscn. Export using the Web preset. No JavaScript game execution or embedded HTML game.

## Implemented
- Native isometric rendering using item geometry extracted from the supplied HTML catalog (86 definitions; 58 contain exportable original geometry).
- Apartment, hall, lobby, street, market and subway scenes.
- Keyboard movement, AStarGrid2D click navigation, solid furniture, zoom and four view rotations.
- Native character name/color menu, interaction menus, inventory, key and subway pass.
- Furniture purchase, timed delivery, placement, rotation, storage and half-price sale.
- Sleep, food, shower, TV toggle, paid sweeping activity and need meters.
- Native PointLight2D lighting, curtains and light switch; native optional CRT shader.
- Native JSON saves in user://tsfm-native-v1.json, separate from browser HTML saves.
- Godot boot splash disabled.

## Scope and known gaps
This is a first playable native port, not a complete feature-equivalent conversion of the 15,600-line source.
The street network and rooms are simplified. Original pixel shaders, NPC simulation, relationships, pets, the full career/trading economy, radios/music, editable scene geometry, advanced lighting occlusion, miniature games, original audio, and imported HTML saves are not converted. Only the base catalog is extracted; later dynamically registered items are not included. Wall-mounted placement and stacking objects on surfaces remain to be ported. The CRT shader is a lightweight native effect, not the complete Guest/ReShade pipeline. No networking/account system is added.

## Controls
WASD/arrows walk; click walk; E use; I/Tab pockets; Q/R rotate view; R rotates furniture during placement; wheel zoom; V walls; F fullscreen; Escape closes/cancels.

## Validation
Godot headless import and runtime checks; meaningful checks for catalog, navigation, collision, scene switching, placement, save/load and paid activity. Browser visual verification is not available in this environment.
