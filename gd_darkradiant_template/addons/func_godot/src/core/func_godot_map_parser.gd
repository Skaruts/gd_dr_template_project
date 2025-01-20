class_name FuncGodotMapParser extends RefCounted

var scope:= FuncGodotMapParser.ParseScope.FILE
var comment: bool = false
var entity_idx: int = -1
var brush_idx: int = -1
var face_idx: int = -1
var component_idx: int = 0
var d3_uv_component_idx: int = 0
var prop_key: String = ""
var current_property: String = ""
var valve_uvs: bool = false

var current_face: FuncGodotMapData.FuncGodotFace
var current_brush: FuncGodotMapData.FuncGodotBrush
var current_entity: FuncGodotMapData.FuncGodotEntity

var map_data: FuncGodotMapData
var _keep_tb_groups: bool = false
var _map_format: int = 0

func _init(in_map_data: FuncGodotMapData) -> void:
	map_data = in_map_data

func load_map(map_file: String, map_settings: FuncGodotMapSettings) -> bool:
	current_face = FuncGodotMapData.FuncGodotFace.new()
	current_brush = FuncGodotMapData.FuncGodotBrush.new()
	current_entity = FuncGodotMapData.FuncGodotEntity.new()

	scope = FuncGodotMapParser.ParseScope.FILE
	comment = false
	entity_idx = -1
	brush_idx = -1
	face_idx = -1
	component_idx = 0
	valve_uvs = false
	_keep_tb_groups = map_settings.use_trenchbroom_groups_hierarchy
	_map_format = map_settings.map_format

	var lines: PackedStringArray = []

	var map: FileAccess = FileAccess.open(map_file, FileAccess.READ)

	if map == null:
		printerr("Error: Failed to open map file (" + map_file + ")")
		return false

	if map_file.ends_with(".import"):
		while not map.eof_reached():
			var line: String = map.get_line()
			if line.begins_with("path"):
				map.close()
				line = line.replace("path=", "");
				line = line.replace('"', '')
				var map_data: String = (load(line) as QuakeMapFile).map_data
				if map_data.is_empty():
					printerr("Error: Failed to open map file (" + line + ")")
					return false
				lines = map_data.split("\n")
				break
	else:
		while not map.eof_reached():
			var line: String = map.get_line()
			lines.append(line)

	for line in lines:
		if comment:
			comment = false
		var tokens := split_string(line, [" ", "\t"], true)
		for s in tokens:
			token(s)

	return true

func split_string(s: String, delimeters: Array[String], allow_empty: bool = true) -> Array[String]:
	var parts: Array[String] = []

	var start := 0
	var i := 0

	while i < s.length():
		if s[i] in delimeters:
			if allow_empty or start < i:
				parts.push_back(s.substr(start, i - start))
			start = i + 1
		i += 1

	if allow_empty or start < i:
		parts.push_back(s.substr(start, i - start))

	return parts

func set_scope(new_scope: FuncGodotMapParser.ParseScope) -> void:
	"""
	match new_scope:
		ParseScope.FILE:
			print("Switching to file scope.")
		ParseScope.ENTITY:
			print("Switching to entity " + str(entity_idx) + "scope")
		ParseScope.PROPERTY_VALUE:
			print("Switching to property value scope")
		ParseScope.BRUSH:
			print("Switching to brush " + str(brush_idx) + " scope")
		ParseScope.PLANE_0:
			print("Switching to face " + str(face_idx) + " plane 0 scope")
		ParseScope.PLANE_1:
			print("Switching to face " + str(face_idx) + " plane 1 scope")
		ParseScope.PLANE_2:
			print("Switching to face " + str(face_idx) + " plane 2 scope")
		ParseScope.TEXTURE:
			print("Switching to texture scope")
		ParseScope.U:
			print("Switching to U scope")
		ParseScope.V:
			print("Switching to V scope")
		ParseScope.VALVE_U:
			print("Switching to Valve U scope")
		ParseScope.VALVE_V:
			print("Switching to Valve V scope")
		ParseScope.ROT:
			print("Switching to rotation scope")
		ParseScope.U_SCALE:
			print("Switching to U scale scope")
		ParseScope.V_SCALE:
			print("Switching to V scale scope")
	"""
	scope = new_scope

func token(buf_str: String) -> void:
	if comment:
		return
	elif buf_str == "//":
		comment = true
		return

	match scope:
		FuncGodotMapParser.ParseScope.FILE:
			if buf_str == "{":
				entity_idx += 1
				brush_idx = -1
				set_scope(FuncGodotMapParser.ParseScope.ENTITY)
		FuncGodotMapParser.ParseScope.ENTITY:
			if buf_str.begins_with('"'):
				prop_key = buf_str.substr(1)
				if prop_key.ends_with('"'):
					prop_key = prop_key.left(-1)
					set_scope(FuncGodotMapParser.ParseScope.PROPERTY_VALUE)
			elif buf_str == "{":
				# NOTE (Skaruts): maybe account for Q3 in this for future support for patches
				if  _map_format != FuncGodotMapData.FuncGodotMapFormat.QUAKE3 \
				and _map_format != FuncGodotMapData.FuncGodotMapFormat.DOOM3:
					brush_idx += 1
					face_idx = -1
					set_scope(FuncGodotMapParser.ParseScope.BRUSH)
				else:
					set_scope(FuncGodotMapParser.ParseScope.DEF)
			elif buf_str == "}":
				commit_entity()
				set_scope(FuncGodotMapParser.ParseScope.FILE)
		FuncGodotMapParser.ParseScope.PROPERTY_VALUE:
			var is_first = buf_str[0] == '"'
			var is_last = buf_str.right(1) == '"'

			if is_first:
				if current_property != "":
					current_property = ""

			if not is_last:
				current_property += buf_str + " "
			else:
				current_property += buf_str

			if is_last:
				current_entity.properties[prop_key] = current_property.substr(1, len(current_property) - 2)
				set_scope(FuncGodotMapParser.ParseScope.ENTITY)
		FuncGodotMapParser.ParseScope.BRUSH:
			if buf_str == "(":
				face_idx += 1
				component_idx = 0
				set_scope(FuncGodotMapParser.ParseScope.PLANE_0)
			elif buf_str == "}":
				commit_brush()
				set_scope(FuncGodotMapParser.ParseScope.ENTITY)
		FuncGodotMapParser.ParseScope.PLANE_0:
			if buf_str == ")":
				component_idx = 0
				set_scope(FuncGodotMapParser.ParseScope.PLANE_1)
			else:
				match component_idx:
					0:
						current_face.plane_points.v0.x = float(buf_str)
					1:
						current_face.plane_points.v0.y = float(buf_str)
					2:
						current_face.plane_points.v0.z = float(buf_str)

				component_idx += 1
		FuncGodotMapParser.ParseScope.PLANE_1:
			if buf_str != "(":
				if buf_str == ")":
					component_idx = 0
					set_scope(FuncGodotMapParser.ParseScope.PLANE_2)
				else:
					match component_idx:
						0:
							current_face.plane_points.v1.x = float(buf_str)
						1:
							current_face.plane_points.v1.y = float(buf_str)
						2:
							current_face.plane_points.v1.z = float(buf_str)

					component_idx += 1
		FuncGodotMapParser.ParseScope.PLANE_2:
			if buf_str != "(":
				if buf_str == ")":
					component_idx = 0
					set_scope(FuncGodotMapParser.ParseScope.TEXTURE)
				else:
					match component_idx:
						0:
							current_face.plane_points.v2.x = float(buf_str)
						1:
							current_face.plane_points.v2.y = float(buf_str)
						2:
							current_face.plane_points.v2.z = float(buf_str)

					component_idx += 1
		FuncGodotMapParser.ParseScope.TEXTURE:
			current_face.texture_idx = map_data.register_texture(buf_str)
			set_scope(FuncGodotMapParser.ParseScope.U)
		FuncGodotMapParser.ParseScope.U:
			if buf_str == "[":
				valve_uvs = true
				component_idx = 0
				set_scope(FuncGodotMapParser.ParseScope.VALVE_U)
			else:
				valve_uvs = false
				current_face.uv_standard.x = float(buf_str)
				set_scope(FuncGodotMapParser.ParseScope.V)
		FuncGodotMapParser.ParseScope.V:
				current_face.uv_standard.y = float(buf_str)
				set_scope(FuncGodotMapParser.ParseScope.ROT)
		FuncGodotMapParser.ParseScope.VALVE_U:
			if buf_str == "]":
				component_idx = 0
				set_scope(FuncGodotMapParser.ParseScope.VALVE_V)
			else:
				match component_idx:
					0:
						current_face.uv_valve.u.axis.x = float(buf_str)
					1:
						current_face.uv_valve.u.axis.y = float(buf_str)
					2:
						current_face.uv_valve.u.axis.z = float(buf_str)
					3:
						current_face.uv_valve.u.offset = float(buf_str)

				component_idx += 1
		FuncGodotMapParser.ParseScope.VALVE_V:
			if buf_str != "[":
				if buf_str == "]":
					set_scope(FuncGodotMapParser.ParseScope.ROT)
				else:
					match component_idx:
						0:
							current_face.uv_valve.v.axis.x = float(buf_str)
						1:
							current_face.uv_valve.v.axis.y = float(buf_str)
						2:
							current_face.uv_valve.v.axis.z = float(buf_str)
						3:
							current_face.uv_valve.v.offset = float(buf_str)

					component_idx += 1
		FuncGodotMapParser.ParseScope.ROT:
			current_face.uv_extra.rot = float(buf_str)
			set_scope(FuncGodotMapParser.ParseScope.U_SCALE)
		FuncGodotMapParser.ParseScope.U_SCALE:
			current_face.uv_extra.scale_x = float(buf_str)
			set_scope(FuncGodotMapParser.ParseScope.V_SCALE)
		FuncGodotMapParser.ParseScope.V_SCALE:
			current_face.uv_extra.scale_y = float(buf_str)
			commit_face()
			set_scope(FuncGodotMapParser.ParseScope.BRUSH)


		#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
		# NOTE (Skaruts):
		#   WIP Doom3 format support attempt below (starts in the ENTITY scope above)
		#
		#   NOTES / RESEARCH:
		#     brushDef3 format:
		#       (plane equation) ( ( xxscale xyscale xoffset ) ( yxscale yyscale yoffset ) ) "material"
		#
		#     (unlike other formats, the material path uses quotes "...", and
		#     includes the base textures folder)
		#
		#     more on Doom3 map format:
		#       https://modwiki.dhewm3.org/MAP_(file_format)
		#
		#     more on texture matrix
		#       https://web.archive.org/web/20080308170646/http://www.doom3world.org/phpbb2/viewtopic.php?t=16228
		FuncGodotMapParser.ParseScope.DEF:
			if   buf_str == "(":
					# if we find this here, it means we are actually in an
					# uninitialized BRUSH scope from Q1/Q3/220 formats
					brush_idx += 1
					face_idx = 0
					component_idx = 0
					set_scope(FuncGodotMapParser.ParseScope.PLANE_0)
			# elif buf_str == "patchDef2": set_scope(FuncGodotMapParser.ParseScope.PATCH_DEF2)
			elif buf_str == "brushDef3": set_scope(FuncGodotMapParser.ParseScope.D3_BRUSH_0)
			elif buf_str == "}":         set_scope(FuncGodotMapParser.ParseScope.ENTITY)

		# FuncGodotMapParser.ParseScope.PATCH_DEF2:

		FuncGodotMapParser.ParseScope.D3_BRUSH_0:
			if   buf_str == "{":
				brush_idx += 1
				face_idx = -1
				set_scope(FuncGodotMapParser.ParseScope.D3_BRUSH_1)
			elif buf_str == "}":
				set_scope(FuncGodotMapParser.ParseScope.DEF)
		FuncGodotMapParser.ParseScope.D3_BRUSH_1:
			if buf_str == "(":
				face_idx += 1
				component_idx = 0
				current_face.d3_brush = FuncGodotMapData.FuncGodotD3Brush.new()
				set_scope(FuncGodotMapParser.ParseScope.D3_PLANE)
			elif buf_str == "}":
				commit_brush()
				set_scope(FuncGodotMapParser.ParseScope.DEF)
		FuncGodotMapParser.ParseScope.D3_BRUSH_2:
			if   buf_str == "(": set_scope(FuncGodotMapParser.ParseScope.D3_UVS)
			elif buf_str == ")": set_scope(FuncGodotMapParser.ParseScope.D3_TEXTURE)
		FuncGodotMapParser.ParseScope.D3_TEXTURE:
			# find first '/' to exclude 'textures' folder from the string
			var idx := buf_str.find('/') + 1

			# exclude quotation marks
			var tex_name:String = buf_str.substr(idx, buf_str.length()-(idx+1))

			current_face.texture_idx = map_data.register_texture(tex_name)
			commit_face()
			set_scope(FuncGodotMapParser.ParseScope.D3_BRUSH_1)
		FuncGodotMapParser.ParseScope.D3_PLANE:
			if buf_str == ")":
				var p := current_face.d3_brush.plane

				var a := p.get_center()
				var n := p.normal
				var xn := Vector3(1,0,0)                # arbitrary cross vector
				if is_equal_approx(abs(n.dot(xn)), 1):  # if vectors are too aligned
					xn = Vector3(0,1,0)                 # use perpendicular to first arbitrary vector, so we know we're different enough

				var perp_vec := n.cross(xn)
				var b := a + perp_vec
				var c := a + perp_vec.rotated(n, PI/2) # rotate the found vector 90 degrees around the normal to get a different perpendicular vector

				current_face.plane_points.v0 = a
				current_face.plane_points.v1 = b
				current_face.plane_points.v2 = c

				# For some reason the final plane must be inverted here so FG can generate
				# geometry (even if the plane components were not initially inverted)
				# To invert it, give it the points in reverse order (eg. a,b,c),
				# or negate 'PI/2', or negate 'p.normal'

				# (this plane is for debug comparison only)
				# var final_plane := Plane(current_face.plane_points.v0, current_face.plane_points.v1, current_face.plane_points.v2)
				# printerr("%s\t%s\t%s" % [p == final_plane, p, final_plane])

				component_idx = 0
				d3_uv_component_idx = 0
				set_scope(FuncGodotMapParser.ParseScope.D3_BRUSH_2)
			else:
				# for some reason I need to invert the components here, or the map
				# will be upside down
				match component_idx:
					0: current_face.d3_brush.plane.x = -float(buf_str)
					1: current_face.d3_brush.plane.y = -float(buf_str)
					2: current_face.d3_brush.plane.z = -float(buf_str)
					3: current_face.d3_brush.plane.d = float(buf_str)

				component_idx += 1
		FuncGodotMapParser.ParseScope.D3_UVS:
			if buf_str == "(":
				if d3_uv_component_idx == 0:
					d3_uv_component_idx += 1
					component_idx = 0
					set_scope(FuncGodotMapParser.ParseScope.D3_X_COMPS)
				else:
					component_idx = 0
					set_scope(FuncGodotMapParser.ParseScope.D3_Y_COMPS)
			elif buf_str == ")":
				valve_uvs = false

				var transform := Transform2D()
				transform.x = current_face.d3_brush.x
				transform.y = current_face.d3_brush.y
				transform.origin = current_face.d3_brush.offset

				var uv:    Vector2 = transform.origin
				var rot:   float   = -rad_to_deg(transform.get_rotation())
				if is_zero_approx(abs(rot - round(rot))):
					rot = round(rot)

				var scale: Vector2 = transform.get_scale()

				# printerr("%20s\t%5s\t%20s\t%20s" % [uv, rot, scale, transform])#, current_face.d3_tex)

				current_face.uv_standard  = uv
				current_face.uv_extra.rot = rot
				current_face.uv_extra.scale_x = scale.x
				current_face.uv_extra.scale_y = scale.y

				set_scope(FuncGodotMapParser.ParseScope.D3_TEXTURE)
		FuncGodotMapParser.ParseScope.D3_X_COMPS:
			if buf_str == ")":
				set_scope(FuncGodotMapParser.ParseScope.D3_UVS)
			else:
				match component_idx:
					0: current_face.d3_brush.x.x = float(buf_str)
					1: current_face.d3_brush.x.y = float(buf_str)
					2: current_face.d3_brush.offset.x = float(buf_str)
				component_idx += 1

		FuncGodotMapParser.ParseScope.D3_Y_COMPS:
			if buf_str == ")":
				set_scope(FuncGodotMapParser.ParseScope.D3_UVS)
			else:
				match component_idx:
					0: current_face.d3_brush.y.x = float(buf_str)
					1: current_face.d3_brush.y.y = float(buf_str)
					2: current_face.d3_brush.offset.y = float(buf_str)
				component_idx += 1

		#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=







func commit_entity() -> void:
	if current_entity.properties.has('_tb_type') and map_data.entities.size() > 0:
		map_data.entities[0].brushes.append_array(current_entity.brushes)
		current_entity.brushes.clear()
		if !_keep_tb_groups:
			current_entity = FuncGodotMapData.FuncGodotEntity.new()
			return

	var new_entity:= FuncGodotMapData.FuncGodotEntity.new()
	new_entity.spawn_type = FuncGodotMapData.FuncGodotEntitySpawnType.ENTITY
	new_entity.properties = current_entity.properties
	new_entity.brushes = current_entity.brushes
	map_data.entities.append(new_entity)

	current_entity = FuncGodotMapData.FuncGodotEntity.new()

func commit_brush() -> void:
	current_entity.brushes.append(current_brush)
	current_brush = FuncGodotMapData.FuncGodotBrush.new()

func commit_face() -> void:
	var v0v1: Vector3 = current_face.plane_points.v1 - current_face.plane_points.v0
	var v1v2: Vector3 = current_face.plane_points.v2 - current_face.plane_points.v1
	current_face.plane_normal = v1v2.cross(v0v1).normalized()
	current_face.plane_dist = current_face.plane_normal.dot(current_face.plane_points.v0)
	current_face.is_valve_uv = valve_uvs

	current_brush.faces.append(current_face)
	current_face = FuncGodotMapData.FuncGodotFace.new()

# Nested
enum ParseScope{
	FILE,
	COMMENT,
	ENTITY,
	PROPERTY_VALUE,
	BRUSH,		# regular Q1/220 brush
	PLANE_0,
	PLANE_1,
	PLANE_2,
	TEXTURE,
	U,
	V,
	VALVE_U,
	VALVE_V,
	ROT,
	U_SCALE,
	V_SCALE,

	# NOTE (Skaruts): Doom3 format scopes
	DEF,
	D3_BRUSH_0, # Doom3 brush
	D3_BRUSH_1,
	D3_BRUSH_2,
	D3_PLANE,
	D3_UVS,
	D3_X_COMPS,
	D3_Y_COMPS,
	D3_TEXTURE,
	PATCH_DEF2, # patch (Quake3/Doom3)
}
