extends Node
class_name CameraShake
## Camera shake system for VR and desktop cameras
## Provides trauma-based screen shake for impacts and thrust
## VR-SAFE: Position-only shake with max 0.05m offset, 20-30 Hz, < 0.3s duration

signal shake_started
signal shake_stopped

## Camera reference (XRCamera3D or Camera3D)
var camera: Node3D = null
var original_position: Vector3 = Vector3.ZERO
var original_rotation: Vector3 = Vector3.ZERO

## Shake parameters
var trauma: float = 0.0  # 0.0 to 1.0, decays over time
var trauma_decay_rate: float = 3.5  # How fast trauma decays per second (ensures < 0.3s duration)

## Shake intensity multipliers (VR-SAFE LIMITS)
@export var max_position_offset: float = 0.05  # Max position shake in meters (VR-safe: 0.05m max)
@export var max_rotation_offset_deg: float = 0.0  # Rotation disabled for VR safety (position-only shake)
@export var shake_frequency: float = 25.0  # Shake oscillation speed (20-30 Hz for VR)

## Noise for randomness
var noise: FastNoiseLite = null
var noise_sample_x: float = 0.0
var noise_sample_y: float = 0.0

## State
var is_shaking: bool = false


func _ready() -> void:
	# Create noise for randomized shake
	noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = shake_frequency
	noise.noise_type = FastNoiseLite.TYPE_PERLIN


## Setup camera shake with camera reference
func setup(cam: Node3D) -> void:
	camera = cam
	if camera:
		original_position = camera.position
		original_rotation = camera.rotation
		print("[CameraShake] VR-safe shake initialized with camera: %s (max offset: %.3fm, freq: %.1f Hz)" % [camera.name, max_position_offset, shake_frequency])


func _process(delta: float) -> void:
	if not camera or trauma <= 0.0:
		if is_shaking:
			_reset_camera()
			is_shaking = false
			shake_stopped.emit()
		return

	if not is_shaking:
		is_shaking = true
		shake_started.emit()

	# Decay trauma over time (3.5/sec ensures trauma from 1.0 to 0 in ~0.3s)
	trauma = max(trauma - trauma_decay_rate * delta, 0.0)

	# Apply shake with trauma squared for smooth falloff
	var shake_amount = trauma * trauma

	# Sample noise at different points for each axis
	noise_sample_x += delta * shake_frequency
	noise_sample_y += delta * shake_frequency * 1.1  # Slightly different frequency

	# Get noise values (-1 to 1)
	var offset_x = noise.get_noise_2d(noise_sample_x, 0.0) * shake_amount
	var offset_y = noise.get_noise_2d(0.0, noise_sample_y) * shake_amount
	var offset_z = noise.get_noise_2d(noise_sample_x, noise_sample_y) * shake_amount

	# Apply to camera (VR-safe: POSITION ONLY, NO ROTATION)
	camera.position = original_position + Vector3(
		offset_x * max_position_offset,
		offset_y * max_position_offset,
		offset_z * max_position_offset
	)

	# VR-SAFE: Rotation disabled (max_rotation_offset_deg = 0.0)
	# Original rotation is maintained to prevent VR nausea
	camera.rotation = original_rotation


## Add trauma to the camera (0.0 to 1.0)
func add_trauma(amount: float) -> void:
	trauma = min(trauma + amount, 1.0)
	if amount > 0.1:
		print("[CameraShake] Added trauma: %.2f (total: %.2f)" % [amount, trauma])


## Add trauma from an impact (scales with velocity)
func impact_shake(velocity: float, intensity: float = 1.0) -> void:
	# Scale trauma based on impact velocity
	# velocity in m/s, moderate impact at 5 m/s, hard impact at 10+ m/s
	var trauma_amount = clampf(velocity / 10.0, 0.1, 1.0) * intensity
	add_trauma(trauma_amount)


## Add subtle continuous shake (for thrust/engine rumble)
func continuous_shake(intensity: float, delta: float) -> void:
	# Add small amount of trauma continuously (decays fast)
	var trauma_amount = intensity * delta * 0.5
	trauma = min(trauma + trauma_amount, intensity)


## Reset camera to original transform
func _reset_camera() -> void:
	if camera:
		camera.position = original_position
		camera.rotation = original_rotation


## Stop shake immediately
func stop_shake() -> void:
	trauma = 0.0
	_reset_camera()
