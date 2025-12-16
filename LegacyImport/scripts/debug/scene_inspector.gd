## SceneInspector - Reports full scene state for automated testing
## Provides detailed information about all objects, positions, and visibility
extends Node

## Report all scene objects with positions and states
func get_full_scene_report() -> Dictionary:
	var report = {
		"timestamp": Time.get_ticks_msec(),
		"scene_tree": {},
		"player": {},
		"vr_system": {},
		"celestial_bodies": [],
		"voxel_terrain": {},
		"visible_objects": [],
		"camera": {}
	}

	# Get root scene
	var root = get_tree().root
	var vr_main = root.get_node_or_null("VRMain")

	if vr_main:
		report["scene_tree"] = _inspect_node_recursive(vr_main, 0, 5)

	# Player information
	var player = get_tree().root.find_child("Player", true, false)
	if not player:
		player = get_tree().root.find_child("WalkingController", true, false)

	if player:
		report["player"] = _inspect_player(player)
	else:
		report["player"] = {"status": "NOT_FOUND"}

	# VR system
	var xr_origin = get_tree().root.find_child("XROrigin3D", true, false)
	if xr_origin:
		report["vr_system"] = _inspect_vr_system(xr_origin)
	else:
		report["vr_system"] = {"status": "NOT_FOUND"}

	# Camera
	var camera = get_viewport().get_camera_3d()
	if camera:
		report["camera"] = {
			"position": str(camera.global_position),
			"rotation": str(camera.global_rotation),
			"transform": str(camera.global_transform),
			"fov": camera.fov if camera.has("fov") else "N/A"
		}

	# Celestial bodies
	var celestial_bodies = get_tree().get_nodes_in_group("celestial_bodies")
	for body in celestial_bodies:
		report["celestial_bodies"].append(_inspect_celestial_body(body))

	# Check for CelestialBody instances not in group
	var all_nodes = _get_all_nodes(root)
	for node in all_nodes:
		if node is CelestialBody and not celestial_bodies.has(node):
			report["celestial_bodies"].append({
				"name": node.name,
				"type": "CelestialBody (not in group)",
				"position": str(node.global_position),
				"in_scene": node.is_inside_tree()
			})

	# Voxel terrain
	var coordinator = get_node_or_null("/root/PlanetarySurvivalCoordinator")
	if coordinator and coordinator.has("voxel_terrain") and coordinator.voxel_terrain:
		report["voxel_terrain"] = _inspect_voxel_terrain(coordinator.voxel_terrain)
	else:
		report["voxel_terrain"] = {"status": "NOT_FOUND"}

	# Visible objects (meshes in camera view)
	report["visible_objects"] = _get_visible_meshes()

	return report


func _inspect_player(player: Node) -> Dictionary:
	var info = {
		"name": player.name,
		"type": player.get_class(),
		"position": str(player.global_position),
		"rotation": str(player.global_rotation),
		"transform": str(player.global_transform),
		"is_active": false,
		"velocity": "N/A",
		"is_on_floor": false,
		"gravity_direction": "N/A",
		"current_gravity": "N/A",
		"jetpack_fuel": "N/A",
		"jetpack_active": false,
		"current_planet": "N/A"
	}

	# WalkingController specific info
	if player.has_method("is_walking_active"):
		info["is_active"] = player.is_walking_active() if player.has_method("is_walking_active") else player.is_active

	if player.has("velocity"):
		info["velocity"] = str(player.velocity)

	if player.has_method("is_on_floor"):
		info["is_on_floor"] = player.is_on_floor()

	if player.has("gravity_direction"):
		info["gravity_direction"] = str(player.gravity_direction)

	if player.has("current_gravity"):
		info["current_gravity"] = player.current_gravity

	if player.has_method("get_jetpack_fuel"):
		info["jetpack_fuel"] = player.get_jetpack_fuel()
		info["jetpack_active"] = player.is_jetpack_firing()

	if player.has("current_planet"):
		if player.current_planet:
			info["current_planet"] = player.current_planet.name
		else:
			info["current_planet"] = "NULL"

	return info


func _inspect_vr_system(xr_origin: Node) -> Dictionary:
	var info = {
		"origin_position": str(xr_origin.global_position),
		"origin_rotation": str(xr_origin.global_rotation),
		"camera": "NOT_FOUND",
		"left_controller": "NOT_FOUND",
		"right_controller": "NOT_FOUND"
	}

	var camera = xr_origin.find_child("XRCamera3D", false, false)
	if camera:
		info["camera"] = {
			"position": str(camera.global_position),
			"rotation": str(camera.global_rotation)
		}

	var left = xr_origin.find_child("LeftController", false, false)
	if left:
		info["left_controller"] = {
			"position": str(left.global_position),
			"rotation": str(left.global_rotation)
		}

	var right = xr_origin.find_child("RightController", false, false)
	if right:
		info["right_controller"] = {
			"position": str(right.global_position),
			"rotation": str(right.global_rotation)
		}

	return info


func _inspect_celestial_body(body: Node) -> Dictionary:
	var info = {
		"name": body.name,
		"type": "CelestialBody",
		"position": str(body.global_position),
		"in_scene_tree": body.is_inside_tree(),
		"visible": body.visible if body.has("visible") else "N/A",
		"radius": "N/A",
		"mass": "N/A"
	}

	if body.has("radius"):
		info["radius"] = body.radius

	if body.has("mass"):
		info["mass"] = body.mass

	if body.has("body_name"):
		info["body_name"] = body.body_name

	return info


func _inspect_voxel_terrain(terrain: Node) -> Dictionary:
	var info = {
		"chunk_count": 0,
		"dirty_chunks": 0,
		"chunks": []
	}

	if terrain.has("chunks"):
		info["chunk_count"] = terrain.chunks.size()

		# Report first 10 chunks
		var count = 0
		for chunk_pos in terrain.chunks.keys():
			if count >= 10:
				break
			var chunk = terrain.chunks[chunk_pos]
			info["chunks"].append({
				"position": str(chunk_pos),
				"is_dirty": chunk.is_dirty if chunk.has("is_dirty") else false,
				"has_mesh": chunk.mesh_instance != null if chunk.has("mesh_instance") else false
			})
			count += 1

	if terrain.has("dirty_chunks"):
		info["dirty_chunks"] = terrain.dirty_chunks.size()

	return info


func _get_visible_meshes() -> Array:
	var meshes = []
	var camera = get_viewport().get_camera_3d()
	if not camera:
		return meshes

	var all_meshes = get_tree().get_nodes_in_group("meshes")

	# Also find MeshInstance3D nodes
	var root = get_tree().root
	var all_nodes = _get_all_nodes(root)
	for node in all_nodes:
		if node is MeshInstance3D and node.visible:
			meshes.append({
				"name": node.name,
				"position": str(node.global_position),
				"mesh_type": node.mesh.get_class() if node.mesh else "NULL"
			})

	return meshes


func _inspect_node_recursive(node: Node, depth: int, max_depth: int) -> Dictionary:
	if depth > max_depth:
		return {"truncated": true}

	var info = {
		"name": node.name,
		"type": node.get_class(),
		"children": []
	}

	# Add position for Node3D
	if node is Node3D:
		info["position"] = str(node.global_position)
		info["rotation"] = str(node.global_rotation)
		info["visible"] = node.visible

	# Add children
	for child in node.get_children():
		info["children"].append(_inspect_node_recursive(child, depth + 1, max_depth))

	return info


func _get_all_nodes(node: Node) -> Array:
	var nodes = [node]
	for child in node.get_children():
		nodes.append_array(_get_all_nodes(child))
	return nodes
