## SceneInspectorSimple - Minimal working scene inspector
extends Node

func get_scene_report() -> Dictionary:
	var report = {}
	report["test"] = "hello"
	report["timestamp"] = Time.get_ticks_msec()

	# Try to get player info
	var player = get_tree().root.find_child("WalkingController", true, false)
	if not player:
		player = get_tree().root.find_child("Player", true, false)

	if player:
		report["player_found"] = true
		report["player_name"] = player.name
		report["player_position"] = [
			player.global_position.x,
			player.global_position.y,
			player.global_position.z
		]

		if player.has("velocity"):
			var vel = player.velocity
			report["player_velocity"] = [vel.x, vel.y, vel.z]

		if player.has_method("is_on_floor"):
			report["player_on_floor"] = player.is_on_floor()

		if player.has("current_gravity"):
			report["player_gravity"] = player.current_gravity

		if player.has("gravity_direction"):
			var gdir = player.gravity_direction
			report["gravity_dir"] = [gdir.x, gdir.y, gdir.z]
	else:
		report["player_found"] = false

	# Camera
	var camera = get_viewport().get_camera_3d()
	if camera:
		report["camera_pos"] = [
			camera.global_position.x,
			camera.global_position.y,
			camera.global_position.z
		]
	else:
		report["camera_found"] = false

	# Count meshes
	var mesh_count = 0
	_count_meshes(get_tree().root, mesh_count)
	report["mesh_count"] = mesh_count

	return report

func _count_meshes(node: Node, count: int) -> int:
	if node is MeshInstance3D and node.visible:
		count += 1

	for child in node.get_children():
		count = _count_meshes(child, count)

	return count
