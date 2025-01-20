# Godot-DarkRadiant Template Project

This is a template Godot 4.3 project set up to use with the DarkRadiant map editor, using a slightly [modified version](https://github.com/Skaruts/func_godot_plugin/tree/dark_radiant_support) of the [FuncGodot](https://github.com/func-godot/func_godot_plugin) plugin.

It's not usable yet. The geometry and 3D models seem to import fine, but there are problems importing brush textures that I couldn't figure out how to fix. It works mostly fine with Quake3 format (not the "alternate" one), except when brush faces are slanted. The Doom3 format has even more problems with textures.

###### Note: As this is a WIP, it includes some TrenchBroom and NetRadiantCustom related maps and configurations that I've been using to compare results. They can be ignored or deleted.

The game type config included inside `_darkradiant_game_config`, adds support for `png` textures. You need to put it in your DarkRadiant folder, along with the other game configs. Unlike other map editors, this is the only thing that goes into the editor's folder. All editor assets used by your projects goes in their respective folders along with the game assets.

In the case of Godot projects, the project path should be the path to where all the assets are (textures, models, etc). In the case of this project, it's the `assets` folder.

I added some experimental support for `func_statics`. It's very rough, but it's a start. The `model` paths in DR will always point to the editor-models, so the import code must replace them with the actual game-models or scenes. For now you need to specify the existing models and the path conversions in `func_static.gd`.


## Important notes on DarkRadiant

DR works in certain ways we should keep in mind, and some things are even hardcoded, so in order to make better use of it, we must go along with it.

- when exporting a map, DR doesn't remember the last format that was used, so exporting Quake3 format is a bit annoying. This is why I attempted to add Doom3 support, and ideally that's what I'd prefer to get fixed. To use Doom3 format, set the `Map Format` to `Doom3` in the `Map Settings` of your `FuncGodotMap` nodes.

- DR doesn't save the project path along with the Game Type configuration, so there's no point creating multiple game configs. This is a non-issue for Dark Mod mappers, but it's inconvenient for Godot users. If you have multiple projects, you'll have to set the project path manually whenever you switch project.

- DR uses `.def` and `.mtr` files, instead of `.fgd`, which are currently not supported by the plugin, so, currently, you'll have to create the definitions by hand.
	- you still need to define your entities in FuncGodot's fgd resources. Just don't use their functionality of exporting an `.fgd` file.

- properties that are string values cannot be empty strings in DR. The usual convention is to use a `-` to represent "no-value". Your import code should account for that, if necessary.

- colors are always represented with floats, so they must contain decimal numbers in order for FuncGodot to recognize that they are floats. I.e., never do `1 0 1`, always do `1.0 0.0 1.0` (or just use the color picker, which does it for you).

- you need separate 3D models for DR and your game, since DR uses a different 3D orientation, and only works with `.obj`, `.lwo` or `.ase` formats.

- to get DR's default filters to work, a couple things are mandatory:
	- tool textures, like `skip`, `clips`, `triggers`, etc, must go in `textures/common` folder
	- `skip` must be named `caulk`, for the `caulk` filter to work (`caulk` is the Doom3 equivalent to `skip`)

- the right-click option to `Surround with Monsterclip` requires that a `monster_clip` texture exists.
	- this will not turn the clip brush into an entity, though. It only conveniently creates a brush with the appropriate texture. For Godot purposes clips must be turned into entities, so you can control the physics layers they operate on, for blocking different things. For that reason, you should also leave the `Clip Texture` field empty, in your `FuncGodotMapSettings` file.

- assuming the game path points to the `assets` folder, in order for DR to work with your assets properly:
	- textures should go in the `textures` folder, so that the default filters work.
	- entity definitions (`.def`) must go in the `def` folder
	- materials (`.mtr`) must go in the `materials` folder
	- sounds may have to go in the `sounds` folder (TODO: confirm this)
	- editor-models must go in the `models` folder. As these are not game models, you can optionally put a `.gdignore` file in it, or remember to exclude them when exporting your game.
		- material names in Blender should match the file paths of the textures used by the models (eg: "textures/models/car5"). Beware that Blender material names have a character limit, so don't make your material paths too long.
		- it's probably better to keep game-models in a separate folder
	- the `maps` folder can be named whatever you like.
	- editor-prefabs should go in the `prefabs` folder (with a .gdignore in it)

- when mapping for anything that isn't Dark Mod, don't ever use the `Model Scaler` tool on the side bar, as it can crash DR. Moreover, as soon as you use it, it will create a copy of the model in `.../maps/map_specific/model_name.lwo` that you then need to delete.

- don't use patches or curves, as they're not yet supported by the plugins.


## On DR gizmos and shortcuts

DR provides some useful right-click shortcuts and gizmos for editing lights and sound ranges. They can be used outside of Dark Mod mapping, with some requirements.

- the shortcut `right-click -> Create Speaker` requires defining an entity with classname `speaker`. This will also enable using the sound gizmos on this entity.
- the shortcut `right-click -> Create Light` requires defining an entity with classname `light` (should be a basic `OmniLight`, in Godot terms).

- for the sound gizmos to work properly, it's also required that the entity includes the property `s_shader`. That property is the name of the sound file that this speaker should play. Two other properties must be included:
	- `s_mindistance` and/or `s_maxdistance`. When you click and drag the gizmos, they change the values of those properties. You can define one or both of them, as you please. In Dark Mod, `s_maxdistance` is the radius within which the sound fades with distance, and `s_mindistance` is the radius within which the sound is always played at full volume.

- for the light gizmos to work, you must include `"editor_light"  "1"` in the light entity definition. The light range in Dark Mod is a `vector3`, so the gizmo is a bounding box, but it can still be worked with (i.e., in the import code, use only the `x` value of the vector).
	- using light gizmos will automatically set two other properties to the light:
		- `light_radius`, which is changed by the range gizmo, and you can use it for your light range. You can set an adequate default value for the range in the definition. If you don't, DR will default it to 320. This value is in DR units, so you should divide it by the map's `inverse_scale_factor` when importing.
		- `light_center`, which is useless in Godot, and you can either ignore it or re-purpose it. It can also be edited with a gizmo.

- There are also gizmos for projected lights, but I'm not sure they can be used.

- I'm also not sure if the `Light Inspector` window is useful outside of Dark Mod mapping. You can use it to choose the light's color and brightness, as long as your color property is named `_color` (with an underscore), but that's about it.
