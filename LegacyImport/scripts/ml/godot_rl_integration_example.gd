extends Node
class_name RLEnvironmentController

## RL Environment Controller for Godot
##
## This script demonstrates how to integrate the Python RL training system
## with your Godot VR scene. Add this to your vr_locomotion_test scene.
##
## Features:
##   - Provides observation data to Python training script
##   - Receives and executes actions from RL agent
##   - Manages episode resets and termination
##   - Tracks episode state and rewards
##
## Integration with HTTP API:
##   - Extend HttpApiServer to add custom RL endpoints
##   - GET /rl/observation - Returns current observation
##   - POST /rl/action - Executes action from agent
##   - POST /rl/reset - Resets environment
##   - GET /rl/state - Returns episode state
##
## Usage:
##   1. Add this script to your training scene
##   2. Configure node references (camera, controllers, goal)
##   3. Register RL endpoints in HttpApiServer
##   4. Run training script from Python

## Node References (configure in editor)
@export var xr_camera: XRCamera3D
@export var left_controller: XRController3D
@export var right_controller: XRController3D
@export var character_body: CharacterBody3D
@export var goal_marker: Node3D

## Ray sensor configuration
@export var num_ray_sensors: int = 16
@export var ray_length: float = 5.0
@export var ray_vertical_angle: float = 0.0

## Episode tracking
var current_episode: int = 0
var current_step: int = 0
var episode_reward: float = 0.0
var episode_done: bool = false

## Observation tracking
var camera_velocity: Vector3 = Vector3.ZERO
var camera_angular_velocity: Vector3 = Vector3.ZERO
var last_camera_position: Vector3 = Vector3.ZERO
var last_camera_rotation: Quaternion = Quaternion.IDENTITY

## Action tracking
var current_action: Dictionary = {}
var last_action_time: float = 0.0

## Goal tracking
var goal_position: Vector3 = Vector3.ZERO
var initial_distance_to_goal: float = 0.0

## Episode info
var episode_info: Dictionary = {
	"collision": false,
	"goal_reached": false,
	"timeout": false,
	"fell": false,
	"comfort_score": 0.0
}

## Physics rate (should match project settings)
const PHYSICS_FPS: int = 90


func _ready():
	print("[RLEnvironment] Initializing RL Environment Controller")

	# Validate node references
	if not xr_camera:
		push_error("[RLEnvironment] XRCamera3D not assigned!")
		return

	# Initialize tracking
	if xr_camera:
		last_camera_position = xr_camera.global_position
		last_camera_rotation = xr_camera.quaternion

	# Spawn initial goal
	_spawn_random_goal()

	print("[RLEnvironment] Ready for training")


func _physics_process(delta: float):
	# Update velocities
	if xr_camera:
		var current_pos = xr_camera.global_position
		var current_rot = xr_camera.quaternion

		camera_velocity = (current_pos - last_camera_position) / delta
		camera_angular_velocity = _quaternion_to_angular_velocity(
			last_camera_rotation, current_rot, delta
		)

		last_camera_position = current_pos
		last_camera_rotation = current_rot

	# Check episode termination conditions
	_check_episode_done()

	# Increment step counter
	current_step += 1


## Get observation for RL agent
func get_observation() -> Dictionary:
	var obs = {}

	# Camera observations
	if xr_camera:
		obs["camera_position"] = _vector3_to_array(xr_camera.global_position)
		obs["camera_rotation"] = _quaternion_to_array(xr_camera.quaternion)
		obs["camera_velocity"] = _vector3_to_array(camera_velocity)
		obs["camera_angular_velocity"] = _vector3_to_array(camera_angular_velocity)
	else:
		obs["camera_position"] = [0.0, 0.0, 0.0]
		obs["camera_rotation"] = [0.0, 0.0, 0.0, 1.0]
		obs["camera_velocity"] = [0.0, 0.0, 0.0]
		obs["camera_angular_velocity"] = [0.0, 0.0, 0.0]

	# Ray sensors
	obs["ray_sensors"] = _get_ray_sensor_distances()

	# Controller observations
	if left_controller:
		obs["left_controller_position"] = _vector3_to_array(left_controller.global_position)
		obs["left_controller_velocity"] = [0.0, 0.0, 0.0]  # TODO: Calculate velocity
	else:
		obs["left_controller_position"] = [0.0, 0.0, 0.0]
		obs["left_controller_velocity"] = [0.0, 0.0, 0.0]

	if right_controller:
		obs["right_controller_position"] = _vector3_to_array(right_controller.global_position)
		obs["right_controller_velocity"] = [0.0, 0.0, 0.0]  # TODO: Calculate velocity
	else:
		obs["right_controller_position"] = [0.0, 0.0, 0.0]
		obs["right_controller_velocity"] = [0.0, 0.0, 0.0]

	# Goal observations
	var camera_pos = xr_camera.global_position if xr_camera else Vector3.ZERO
	var goal_relative = goal_position - camera_pos
	var goal_distance = goal_relative.length()
	var goal_direction = goal_relative.normalized() if goal_distance > 0.001 else Vector3.ZERO

	obs["goal_position"] = _vector3_to_array(goal_relative)
	obs["goal_distance"] = goal_distance
	obs["goal_direction"] = _vector3_to_array(goal_direction)

	# Additional info
	obs["collision"] = episode_info["collision"]
	obs["fell"] = episode_info["fell"]

	return obs


## Execute action from RL agent
func execute_action(action_dict: Dictionary):
	current_action = action_dict
	last_action_time = Time.get_ticks_msec() / 1000.0

	if action_dict.get("type") == "continuous":
		_execute_continuous_action(action_dict)
	elif action_dict.get("type") == "discrete":
		_execute_discrete_action(action_dict)


## Execute continuous action (smooth movement)
func _execute_continuous_action(action: Dictionary):
	if not character_body:
		return

	var move_h = action.get("move_horizontal", 0.0)
	var move_v = action.get("move_vertical", 0.0)
	var rotate = action.get("rotate", 0.0)

	var max_speed = action.get("max_movement_speed", 2.0)
	var max_rotation = action.get("max_rotation_speed", 90.0)

	# Calculate movement direction
	var camera_forward = -xr_camera.global_transform.basis.z if xr_camera else Vector3.FORWARD
	var camera_right = xr_camera.global_transform.basis.x if xr_camera else Vector3.RIGHT

	# Project to horizontal plane
	camera_forward.y = 0
	camera_right.y = 0
	camera_forward = camera_forward.normalized()
	camera_right = camera_right.normalized()

	# Calculate velocity
	var movement = camera_forward * move_v + camera_right * move_h
	character_body.velocity = movement * max_speed

	# Apply rotation (rotate the XROrigin3D parent, not camera directly)
	if xr_camera and xr_camera.get_parent():
		var rotation_delta = rotate * max_rotation * (1.0 / PHYSICS_FPS)
		xr_camera.get_parent().rotate_y(deg_to_rad(rotation_delta))


## Execute discrete action (teleport, snap turn)
func _execute_discrete_action(action: Dictionary):
	var action_idx = action.get("action_index", 0)
	var turn_angle = action.get("turn_angle", 45.0)
	var move_dist = action.get("move_distance", 1.0)

	match action_idx:
		0:  # Forward
			_teleport_relative(Vector3.FORWARD * move_dist)
		1:  # Back
			_teleport_relative(Vector3.BACK * move_dist)
		2:  # Left
			_teleport_relative(Vector3.LEFT * move_dist)
		3:  # Right
			_teleport_relative(Vector3.RIGHT * move_dist)
		4:  # Turn left
			_snap_turn(-turn_angle)
		5:  # Turn right
			_snap_turn(turn_angle)
		6:  # Idle
			pass


## Reset environment for new episode
func reset_environment():
	print("[RLEnvironment] Resetting environment for episode ", current_episode + 1)

	# Reset episode tracking
	current_episode += 1
	current_step = 0
	episode_reward = 0.0
	episode_done = false

	# Reset episode info
	episode_info = {
		"collision": false,
		"goal_reached": false,
		"timeout": false,
		"fell": false,
		"comfort_score": 0.0
	}

	# Reset camera position
	if xr_camera and xr_camera.get_parent():
		var spawn_pos = _get_random_spawn_position()
		xr_camera.get_parent().global_position = spawn_pos

	# Reset velocities
	camera_velocity = Vector3.ZERO
	camera_angular_velocity = Vector3.ZERO

	if character_body:
		character_body.velocity = Vector3.ZERO

	# Spawn new goal
	_spawn_random_goal()

	# Record initial distance
	if xr_camera:
		initial_distance_to_goal = xr_camera.global_position.distance_to(goal_position)


## Get current episode state
func get_episode_state() -> Dictionary:
	return {
		"episode": current_episode,
		"step": current_step,
		"reward": episode_reward,
		"done": episode_done,
		"info": episode_info
	}


## Check if episode is done
func _check_episode_done():
	if episode_done:
		return

	# Goal reached
	if xr_camera and xr_camera.global_position.distance_to(goal_position) < 1.0:
		episode_info["goal_reached"] = true
		episode_done = true
		print("[RLEnvironment] Goal reached!")
		return

	# Fell off map
	if xr_camera and xr_camera.global_position.y < -10.0:
		episode_info["fell"] = true
		episode_done = true
		print("[RLEnvironment] Fell off map!")
		return

	# Timeout (max steps)
	if current_step > 1000:  # Configurable max steps
		episode_info["timeout"] = true
		episode_done = true
		print("[RLEnvironment] Episode timeout")
		return


## Get ray sensor distances
func _get_ray_sensor_distances() -> Array:
	var distances = []

	if not xr_camera:
		# Return max distances if no camera
		for i in range(num_ray_sensors):
			distances.append(ray_length)
		return distances

	var space_state = get_world_3d().direct_space_state
	var origin = xr_camera.global_position

	for i in range(num_ray_sensors):
		var angle = (2.0 * PI * i) / num_ray_sensors
		var direction = Vector3(cos(angle), 0, sin(angle)).rotated(Vector3.RIGHT, deg_to_rad(ray_vertical_angle))

		# Create ray query
		var query = PhysicsRayQueryParameters3D.create(origin, origin + direction * ray_length)
		query.exclude = [character_body] if character_body else []

		var result = space_state.intersect_ray(query)

		if result:
			var hit_distance = origin.distance_to(result.position)
			distances.append(hit_distance)
		else:
			distances.append(ray_length)

	return distances


## Spawn random goal position
func _spawn_random_goal():
	# Spawn goal at random position
	var angle = randf() * 2.0 * PI
	var distance = randf_range(10.0, 30.0)

	goal_position = Vector3(
		cos(angle) * distance,
		0.0,
		sin(angle) * distance
	)

	if goal_marker:
		goal_marker.global_position = goal_position

	print("[RLEnvironment] Goal spawned at: ", goal_position)


## Get random spawn position
func _get_random_spawn_position() -> Vector3:
	var angle = randf() * 2.0 * PI
	var radius = randf_range(0.0, 5.0)

	return Vector3(
		cos(angle) * radius,
		1.5,  # Standing height
		sin(angle) * radius
	)


## Helper: Teleport relative to camera facing
func _teleport_relative(offset: Vector3):
	if not xr_camera or not xr_camera.get_parent():
		return

	var camera_basis = xr_camera.global_transform.basis
	var world_offset = camera_basis * offset
	world_offset.y = 0  # Keep on ground

	xr_camera.get_parent().global_position += world_offset
	episode_info["teleported"] = true


## Helper: Snap turn
func _snap_turn(angle_degrees: float):
	if not xr_camera or not xr_camera.get_parent():
		return

	xr_camera.get_parent().rotate_y(deg_to_rad(angle_degrees))


## Helper: Convert Vector3 to array
func _vector3_to_array(v: Vector3) -> Array:
	return [v.x, v.y, v.z]


## Helper: Convert Quaternion to array
func _quaternion_to_array(q: Quaternion) -> Array:
	return [q.x, q.y, q.z, q.w]


## Helper: Calculate angular velocity from quaternions
func _quaternion_to_angular_velocity(q_prev: Quaternion, q_current: Quaternion, delta: float) -> Vector3:
	var q_delta = q_current * q_prev.inverse()
	var axis = Vector3(q_delta.x, q_delta.y, q_delta.z)
	var angle = 2.0 * acos(clamp(q_delta.w, -1.0, 1.0))

	if axis.length_squared() > 0.0001:
		axis = axis.normalized()
		return axis * (angle / delta)

	return Vector3.ZERO


## Collision detection (connect to CharacterBody3D signals)
func _on_collision_detected(collision: KinematicCollision3D):
	episode_info["collision"] = true
	print("[RLEnvironment] Collision detected with: ", collision.get_collider().name)


## Example HTTP API Router Integration
## Add this to HttpApiServer to register RL endpoints:
##
## func _register_rl_routers():
##     # Get RL environment controller from current scene
##     var rl_env = get_tree().current_scene.get_node("RLEnvironmentController")
##     if not rl_env:
##         print("[HttpApiServer] Warning: No RLEnvironmentController found")
##         return
##
##     # GET /rl/observation
##     var obs_router = preload("res://scripts/http_api/rl_observation_router.gd").new(rl_env)
##     server.register_router(obs_router)
##
##     # POST /rl/action
##     var action_router = preload("res://scripts/http_api/rl_action_router.gd").new(rl_env)
##     server.register_router(action_router)
##
##     # POST /rl/reset
##     var reset_router = preload("res://scripts/http_api/rl_reset_router.gd").new(rl_env)
##     server.register_router(reset_router)
##
##     # GET /rl/state
##     var state_router = preload("res://scripts/http_api/rl_state_router.gd").new(rl_env)
##     server.register_router(state_router)
