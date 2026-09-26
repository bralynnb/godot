# BLINK — Wester Drumlins

A playable first-person PS1-style fan-game prototype in **Godot 4.4.1**.
Open `project.godot`, let the assets import, then press F6/F5 (F5 runs the game).

## Scope

A condensed twelve-chapter adaptation of Doctor Who: Blink, with explorable low-poly environments, original generated textures and atmospheric audio, ordered evidence interactions, observation-based Angel encounters, and checkpoint saves. This is a prototype with simplified sets and summary text. It does **not** reproduce every shot, scene, line, actor performance or puzzle from the television episode. The broadcast footage, soundtrack and actor likenesses are not included. The game is PS1-style; it is not a PlayStation disc image.

## Play

- WASD: walk. Mouse or arrow keys: look.
- E: interact with the current objective when nearby and facing it.
- Enter / E: advance text. Escape: pause.
- F: flashlight. B: manual blink. Automatic blink occurs after 13 seconds.
- J: recent evidence. G: guided mode (objective marker and slower Angels).
- R: restart current chapter; Enter confirms, Escape cancels.

Main menu: Begin Story or Continue Checkpoint. Progress is saved at chapter starts to Godot's `user://blink-save.json`. Reading text and opening the journal pause the world. There is no combat.

The Angels are active in chapters 9 and 10. Four body sample points, camera-frustum checks and physics rays determine observation. Walls obstruct gaze. Looking at an Angel freezes its position. Blink or look away and it advances. Contact returns you to the chapter checkpoint. The final tableau is permanently frozen.

## Chapter route / walkthrough

The objective appears at the top. Press G for an in-world marker.

1. House: approach the loose paper at the far left wall; peel, photograph, inspect the window.
2. Flat: inspect the television; speak to Kathy.
3. House: compare the window; answer the visitor; return to Kathy; retrieve the statue's key.
4. Garden: read the letter on the table; visit the headstone.
5. Shop: speak to Larry; inspect the screen; collect the list.
6. Impound: speak to Billy; inspect the box; approach the exit; return to the box's former position.
7. Hospital: speak to Billy; examine the list; approach the window.
8. House: play the recording; speak to Larry; finish the recording.
9. House: try the front door (right rear); reach the cellar door (left rear). Back away from the Angel.
10. Cellar: approach the police box while keeping the statues in view. E uses the key.
11. TARDIS: insert the disc at the console; inspect the final tableau.
12. Shop: collect the folder; find the Doctor near the entrance to finish.

## Build and test

Godot 4.4.1, matching export templates:

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . -- --smoke
godot --headless --path . --export-release "Windows Desktop" /absolute/output/Blink.exe
godot --headless --path . --export-release "Web" /absolute/output/index.html
```

Windows executable embeds its PCK. Web export requires an HTTP server, WebGL 2 and a keyboard/mouse; it cannot be opened by double-clicking an HTML file. No multiplayer, hosting service or runtime network connection is required for the Windows build.

## Architecture

- `scripts/story.gd`: ordered chapter definitions, summaries and objectives.
- `scripts/world.gd`: independent meshes, materials, collision, scenery and Angels.
- `scripts/main.gd`: player, UI, progression, checkpoints, interaction and gaze AI.
- `assets`: original procedural 64px textures and looping ambient sound.

Godot physics controls the player. Angels use local straight-line movement with wall obstruction, not a complete navigation mesh. The torch is aesthetic; ambient light allows observation without it. Companion observation, the episode's thrown-rock event, animated cinematic transitions, 1920/1969 playable flashbacks, voice acting, and exact architectural matching remain future work. Keys/DVDs are represented by sequential progression, not a freely combinable inventory. Room transitions occur through the story panels. This distinction is intentional and should remain explicit when describing this prototype.

## Verification

Automated smoke tests exercise every chapter's interaction chain and target reachability, plus Angel observation, blink release, movement and wall occlusion. A Chromium WebGL test verifies menu, start, movement and first interaction. Windows export was generated successfully; Windows-native execution was not tested in this Linux environment.

## Sources and credits

Story reference: [Doctor Who — Blink](https://www.doctorwho.tv/stories/blink), [Sally Sparrow](https://www.doctorwho.tv/characters/sally-sparrow), [Weeping Angels](https://www.doctorwho.tv/characters/weeping-angels), and [episode guide](https://doctorwhoworlduk.com/ns3ep10).

Doctor Who, its characters and episode belong to their respective rights holders. Episode written by Steven Moffat. Unofficial fan prototype. Original project code, geometry, textures and sound created for this build. Godot Engine is MIT-licensed; engine license is included with the Windows download.
