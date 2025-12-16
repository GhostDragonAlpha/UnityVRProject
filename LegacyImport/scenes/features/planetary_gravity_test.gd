extends Node3D
## Planetary Gravity Test Scene
##
## Tests the GravityManager by creating a small planet and allowing
## the player to walk on its curved surface.
##
## Controls:
##   W/S: Move forward/backward
##   A/D: Strafe left/right
##   Space: Jump
##   R: Reset to spawn point
##   P: Print stats
##
## Features:
##   - Small test planet (100m radius)
##   - Spherical gravity pointing to center
##   - Player orientation follows surface normal
##   - Can walk 360° around planet

## Planet properties
const PLANET_RADIUS := 100.0  # meters
const PLANET_MASS := 5.972e24  # kg (Earth mass for testing)

## Player movement
const MOVE_SPEED := 5.0  # m/s
const JUMP_FORCE := 10.0  # m/s
const GRAVITY_ALIGN_SPEED := 5.0  # How fast player aligns to gravity
const MAX_VELOCITY := 50.0  # m/s - Maximum speed to prevent runaway physics
const MAX_DISTANCE := 5000.0  # meters - Reset player if they go too far

## References
@onready var planet: StaticBody3D = $Planet
@onready var player: CharacterBody3D = $Player
@onready var camera: Camera3D = $Player/Camera3D
@onready var status_label: Label = $UI/StatusLabel

## Player state
var spawn_position := Vector3(0, PLANET_RADIUS + 2, 0)
var is_on_surface := false

## Astronomical tracking
var planet_astro_id: int = -1
var player_astro_id: int = -1


func _ready() -> void:
	print("[PlanetaryGravityTest] Scene ready")

	# Register planet with GravityManager
	GravityManager.register_gravity_source(planet, PLANET_MASS, PLANET_RADIUS)
	print("[PlanetaryGravityTest] Planet registered with GravityManager")

	# Register with FloatingOriginSystem
	FloatingOriginSystem.register_object(planet)
	FloatingOriginSystem.register_object(player)
	FloatingOriginSystem.set_player(player)

	# Register with AstronomicalCoordinateSystem
	# Planet is at origin in local space, 1 AU from star in system space
	var planet_astro_pos = AstroPos.new()
	planet_astro_pos.local_meters = Vector3.ZERO
	planet_astro_pos.system_au = Vector3(1.0, 0, 0)  # 1 AU from star
	planet_astro_pos.authoritative = AstroPos.CoordSystem.SYSTEM
	planet_astro_id = AstronomicalCoordinateSystem.register_object(planet, planet_astro_pos)
	print("[PlanetaryGravityTest] Planet registered with AstronomicalCoordinateSystem (ID: %d)" % planet_astro_id)

	# Set player for astronomical tracking
	AstronomicalCoordinateSystem.set_player(player)

	# Position player at spawn
	player.global_position = spawn_position

	# Create planet mesh (will be created in editor, but documented here)
	print("[PlanetaryGravityTest] Planet radius: %.1f m" % PLANET_RADIUS)
	print("[PlanetaryGravityTest] Planet mass: " + str(PLANET_MASS) + " kg")

	var surface_g = GravityManager.get_surface_gravity(
		GravityManager.get_nearest_gravity_source(planet.global_position)
	)
	print("[PlanetaryGravityTest] Surface gravity: %.2f m/s²" % surface_g)


func _process(delta: float) -> void:
	# Bounds check - reset if player went too far
	if player and player.global_position.length() > MAX_DISTANCE:
		print("[PlanetaryGravityTest] Player exceeded bounds, resetting")
		_reset_player()
		return

	# Handle input
	_handle_movement(delta)

	# Align player to gravity
	_align_player_to_gravity(delta)

	# Update UI
	_update_ui()

	# Check for reset
	if Input.is_key_pressed(KEY_R):
		_reset_player()
	if Input.is_key_pressed(KEY_P):
		_print_stats()


func _handle_movement(delta: float) -> void:
	if not player:
		return

	# Get input
	var input_dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_W):
		input_dir.y -= 1.0
	if Input.is_key_pressed(KEY_S):
		input_dir.y += 1.0
	if Input.is_key_pressed(KEY_A):
		input_dir.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		input_dir.x += 1.0

	# Get player's local directions (relative to gravity orientation)
	var forward = -player.global_transform.basis.z
	var right = player.global_transform.basis.x

	# Calculate movement direction
	var move_direction = (forward * input_dir.y + right * input_dir.x).normalized()

	# Apply horizontal movement
	if move_direction.length() > 0:
		var horizontal_velocity = move_direction * MOVE_SPEED
		player.velocity = player.velocity.lerp(horizontal_velocity, 10.0 * delta)

	# Apply gravity
	var gravity = GravityManager.get_gravity_at_position(player.global_position)
	player.velocity += gravity * delta

	# Jump
	if Input.is_action_just_pressed("ui_accept") and is_on_surface:
		var up_direction = GravityManager.get_up_direction(player.global_position)
		player.velocity += up_direction * JUMP_FORCE

	# Clamp velocity to prevent runaway physics
	if player.velocity.length() > MAX_VELOCITY:
		player.velocity = player.velocity.normalized() * MAX_VELOCITY

	# Move player
	player.move_and_slide()

	# Check if on surface
	is_on_surface = player.is_on_floor()


func _align_player_to_gravity(delta: float) -> void:
	if not player:
		return

	# Get up direction from gravity
	var target_up = GravityManager.get_up_direction(player.global_position)

	# Current up direction
	var current_up = player.global_transform.basis.y

	# Interpolate toward target
	var new_up = current_up.lerp(target_up, GRAVITY_ALIGN_SPEED * delta).normalized()

	# Create new transform aligned to gravity
	var new_transform = player.global_transform
	new_transform.basis = _create_aligned_basis(new_transform.basis, new_up)

	player.global_transform = new_transform


func _create_aligned_basis(basis: Basis, target_up: Vector3) -> Basis:
	# Keep forward direction as much as possible
	var forward = -basis.z

	# Make forward perpendicular to target_up
	forward = forward - target_up * forward.dot(target_up)

	if forward.length() < 0.001:
		# If forward is parallel to up, pick a new forward
		forward = Vector3.FORWARD
		forward = forward - target_up * forward.dot(target_up)

	forward = forward.normalized()

	# Calculate right direction
	var right = forward.cross(target_up).normalized()

	# Recalculate forward for perfect orthogonality
	forward = target_up.cross(right).normalized()

	# Create new basis
	return Basis(right, target_up, -forward)


func _update_ui() -> void:
	if not status_label or not player:
		return

	var distance_to_surface = GravityManager.get_distance_to_surface(player.global_position)
	var nearest_source = GravityManager.get_nearest_gravity_source(player.global_position)
	var gravity = GravityManager.get_gravity_at_position(player.global_position)
	var in_well = GravityManager.is_in_gravity_well(player.global_position)

	status_label.text = "Planetary Gravity Test\n"
	status_label.text += "Distance to surface: %.2f m\n" % distance_to_surface
	status_label.text += "Gravity strength: %.2f m/s²\n" % gravity.length()
	status_label.text += "In gravity well: %s\n" % ("Yes" if in_well else "No")
	status_label.text += "On surface: %s\n" % ("Yes" if is_on_surface else "No")

	if nearest_source:
		var surface_g = GravityManager.get_surface_gravity(nearest_source)
		status_label.text += "Surface gravity: %.2f m/s²\n" % surface_g

	# Display astronomical coordinates
	var player_astro_pos = AstronomicalCoordinateSystem.get_player_position()
	if player_astro_pos:
		status_label.text += "\nAstronomical Position:\n"
		status_label.text += "  System: %.6f AU from star\n" % player_astro_pos.system_au.length()
		status_label.text += "  Local: (%.1f, %.1f, %.1f) m\n" % [player.global_position.x, player.global_position.y, player.global_position.z]

		# Show distance to planet center in AU (should be very small)
		if planet_astro_id >= 0:
			var dist_au = AstronomicalCoordinateSystem.get_distance_au(planet_astro_id, -1)  # -1 = player
			status_label.text += "  Dist to planet: %.9f AU (%.1f m)\n" % [dist_au, dist_au * 149597870700.0]

	status_label.text += "\n"
	status_label.text += "Controls:\n"
	status_label.text += "  WASD: Move, Space: Jump\n"
	status_label.text += "  R: Reset, P: Print stats"


func _reset_player() -> void:
	if not player:
		return

	print("[PlanetaryGravityTest] Resetting player")
	player.global_position = spawn_position
	player.velocity = Vector3.ZERO


func _print_stats() -> void:
	print("[PlanetaryGravityTest] ===== Statistics =====")
	print("  Player position: %s" % player.global_position)
	print("  Distance to surface: %.2f m" % GravityManager.get_distance_to_surface(player.global_position))

	var gravity = GravityManager.get_gravity_at_position(player.global_position)
	print("  Gravity: %s (%.2f m/s²)" % [gravity, gravity.length()])

	GravityManager.print_status()
