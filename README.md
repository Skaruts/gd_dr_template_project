# Godot-DarkRadiant Template Project

This is a template Godot project set up to use with the DarkRadiant map editor, using a slightly [modified version](https://github.com/Skaruts/func_godot_plugin/tree/dark_radiant_support) of the [FuncGodot](https://github.com/func-godot/func_godot_plugin) plugin.

It's not usable yet. The geometry seems to import fine, and models as well, but there are problems importing brush textures that I can't figure out how to fix. It works mostly fine with Quake3 format (not the "alternate" one), except when brush faces are slanted. The Doom3 format has even more problems with textures.

###### Note: As this is a WIP, it includes some TrenchBroom and NetRadiantCustom related maps and configurations that I've been using to compare results. They can be ignored or deleted.


The game type config included inside `_darkradiant_game_config`, adds support for `png` textures. You need to put it in your DarkRadiant folder, along with the other game configs. Unlike other map editors, this is the only thing that goes into the editor's folder. All editor assets used by your projects goes in their respective folders along with the game assets.

In the case of Godot projects, the project path should be the path to where all the assets are (textures, models, etc). In the case of this project, it's the `assets` folder.

I added some experimental support for `func_statics`. It's very rough, but it's a start. The `model` paths in DR will always point to the editor-models, so the import code must replace them with the actual game-models. For now you need to specify the existing models in `func_static.gd`.


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


