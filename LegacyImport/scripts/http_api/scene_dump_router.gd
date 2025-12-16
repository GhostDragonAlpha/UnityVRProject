extends "res://addons/godottpd/http_router.gd"
class_name SceneDumpRouter

## HTTP Router for dumping the current scene tree
## Provides a JSON representation of the node hierarchy for AI inspection

const SecurityConfig = preload("res://scripts/http_api/security_config.gd")

func _init():
	var get_handler = func(request: HttpRequest, response: GodottpdResponse) -> bool:
		# Auth check
		if not SecurityConfig.validate_auth(request):
			response.send(401, JSON.stringify(SecurityConfig.create_auth_error_response()))
			return true

		var tree = Engine.get_main_loop() as SceneTree
		if not tree or not tree.current_scene:
			response.send(404, JSON.stringify({"error": "No active scene"}))
			return true

		var dump = _dump_node(tree.current_scene)
		response.send(200, JSON.stringify(dump))
		return true

	super("/scene/dump", {'get': get_handler})

func _dump_node(node: Node) -> Dictionary:
	var data = {
		"name": node.name,
		"type": node.get_class(),
		"path": str(node.get_path()),
		"visible": true,
		"children": []
	}

	# Capture specific properties based on type
	if node is Node3D:
		data["visible"] = node.visible
		data["global_position"] = _vec3_to_dict(node.global_position)
		data["global_rotation_deg"] = _vec3_to_dict(node.global_rotation_degrees)
	elif node is CanvasItem:
		data["visible"] = node.visible
	
	if node is Camera3D:
		data["current"] = node.current
		data["fov"] = node.fov
	
	if node is Light3D:
		data["energy"] = node.light_energy
		data["color"] = _color_to_dict(node.light_color)

	# Recursively dump children
	for child in node.get_children():
		data["children"].append(_dump_node(child))

	return data

func _vec3_to_dict(v: Vector3) -> Dictionary:
	return {"x": v.x, "y": v.y, "z": v.z}

func _color_to_dict(c: Color) -> Dictionary:
	return {"r": c.r, "g": c.g, "b": c.b, "a": c.a}
