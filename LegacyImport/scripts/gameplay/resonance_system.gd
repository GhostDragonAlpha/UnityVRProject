extends Node
class_name ResonanceSystem

## Resonance-based interaction system for harmonic frequency matching
## Implements constructive and destructive interference mechanics
## Requirements: 20.1, 20.2, 20.3, 20.4, 20.5

signal object_scanned(object: Node3D, frequency: float)
signal interference_applied(object: Node3D, interference_type: String, amplitude_change: float)
signal object_cancelled(object: Node3D)

## Base frequency range for objects (Hz)
const MIN_FREQUENCY: float = 100.0
const MAX_FREQUENCY: float = 1000.0

## Amplitude threshold for object cancellation
const CANCELLATION_THRESHOLD: float = 0.1

## Interference strength multiplier
const INTERFERENCE_STRENGTH: float = 1.0

## Dictionary to track object frequencies and amplitudes
## Key: Node3D instance_id, Value: Dictionary with "frequency" and "amplitude"
var tracked_objects: Dictionary = {}

## Current emitted frequency (0 = not emitting)
var emitted_frequency: float = 0.0

## Whether frequency is inverted for destructive interference
var frequency_inverted: bool = false


func _ready() -> void:
	set_process(true)


func _process(delta: float) -> void:
	if emitted_frequency > 0.0:
		_apply_interference_to_tracked_objects(delta)


## Scan an object to determine its base harmonic frequency
## Requirements: 20.1
func scan_object(object: Node3D) -> float:
	if not is_instance_valid(object):
		push_error("ResonanceSystem: Cannot scan invalid object")
		return 0.0
	
	# Determine frequency based on object properties
	var frequency = _calculate_object_frequency(object)
	
	# Track the object with initial amplitude of 1.0
	var obj_id = object.get_instance_id()
	tracked_objects[obj_id] = {
		"object": object,
		"frequency": frequency,
		"amplitude": 1.0
	}
	
	object_scanned.emit(object, frequency)
	return frequency


## Emit a matching frequency for constructive interference
## Requirements: 20.2
func emit_matching_frequency(target_frequency: float) -> void:
	if target_frequency < MIN_FREQUENCY or target_frequency > MAX_FREQUENCY:
		push_warning("ResonanceSystem: Frequency %f out of valid range [%f, %f]" % [target_frequency, MIN_FREQUENCY, MAX_FREQUENCY])
		return
	
	emitted_frequency = target_frequency
	frequency_inverted = false


## Emit an inverted frequency for destructive interference
## Requirements: 20.3
func emit_inverted_frequency(target_frequency: float) -> void:
	if target_frequency < MIN_FREQUENCY or target_frequency > MAX_FREQUENCY:
		push_warning("ResonanceSystem: Frequency %f out of valid range [%f, %f]" % [target_frequency, MIN_FREQUENCY, MAX_FREQUENCY])
		return
	
	emitted_frequency = target_frequency
	frequency_inverted = true


## Stop emitting frequency
func stop_emission() -> void:
	emitted_frequency = 0.0
	frequency_inverted = false


## Get the current amplitude of a tracked object
func get_object_amplitude(object: Node3D) -> float:
	if not is_instance_valid(object):
		return 0.0
	
	var obj_id = object.get_instance_id()
	if tracked_objects.has(obj_id):
		return tracked_objects[obj_id]["amplitude"]
	
	return 0.0


## Get the frequency of a tracked object
func get_object_frequency(object: Node3D) -> float:
	if not is_instance_valid(object):
		return 0.0
	
	var obj_id = object.get_instance_id()
	if tracked_objects.has(obj_id):
		return tracked_objects[obj_id]["frequency"]
	
	return 0.0


## Stop tracking an object
func untrack_object(object: Node3D) -> void:
	if not is_instance_valid(object):
		return
	
	var obj_id = object.get_instance_id()
	tracked_objects.erase(obj_id)


## Calculate wave amplitude changes and apply interference
## Requirements: 20.4
func _apply_interference_to_tracked_objects(delta: float) -> void:
	var objects_to_remove: Array = []
	
	for obj_id in tracked_objects.keys():
		var data = tracked_objects[obj_id]
		var object = data["object"]
		
		# Check if object is still valid
		if not is_instance_valid(object):
			objects_to_remove.append(obj_id)
			continue
		
		var object_frequency = data["frequency"]
		var current_amplitude = data["amplitude"]
		
		# Calculate frequency match (1.0 = perfect match, 0.0 = no match)
		var frequency_match = _calculate_frequency_match(object_frequency, emitted_frequency)
		
		# Calculate amplitude change based on interference type
		var amplitude_change: float = 0.0
		var interference_type: String = ""
		
		if frequency_inverted:
			# Destructive interference - reduce amplitude
			# Requirements: 20.3
			amplitude_change = -frequency_match * INTERFERENCE_STRENGTH * delta
			interference_type = "destructive"
		else:
			# Constructive interference - increase amplitude
			# Requirements: 20.2
			amplitude_change = frequency_match * INTERFERENCE_STRENGTH * delta
			interference_type = "constructive"
		
		# Apply amplitude change (sum of wave amplitudes)
		# Requirements: 20.4
		var new_amplitude = current_amplitude + amplitude_change
		new_amplitude = max(0.0, new_amplitude)  # Amplitude cannot be negative
		
		data["amplitude"] = new_amplitude
		
		# Emit signal for amplitude change
		if abs(amplitude_change) > 0.001:
			interference_applied.emit(object, interference_type, amplitude_change)
		
		# Check if object should be cancelled
		# Requirements: 20.5
		if new_amplitude <= CANCELLATION_THRESHOLD:
			objects_to_remove.append(obj_id)
			_cancel_object(object)
	
	# Remove cancelled objects from tracking
	for obj_id in objects_to_remove:
		tracked_objects.erase(obj_id)


## Calculate the base harmonic frequency of an object
## Based on object properties like mass, size, and type
func _calculate_object_frequency(object: Node3D) -> float:
	# Use a hash of the object's properties to generate a deterministic frequency
	var hash_value: int = 0
	
	# Factor in object name
	hash_value += object.name.hash()
	
	# Factor in position (for spatial variation)
	var pos = object.global_position
	hash_value += int(pos.x * 100) + int(pos.y * 100) + int(pos.z * 100)
	
	# Factor in object type/class
	hash_value += object.get_class().hash()
	
	# If object is a RigidBody3D, factor in mass
	if object is RigidBody3D:
		hash_value += int(object.mass * 1000)
	
	# Normalize hash to frequency range
	var normalized = abs(hash_value % 10000) / 10000.0
	var frequency = MIN_FREQUENCY + (normalized * (MAX_FREQUENCY - MIN_FREQUENCY))
	
	return frequency


## Calculate how well two frequencies match (0.0 to 1.0)
## Uses a Gaussian-like falloff for frequency matching
func _calculate_frequency_match(freq1: float, freq2: float) -> float:
	if freq2 == 0.0:
		return 0.0
	
	# Calculate frequency difference as a percentage
	var freq_diff = abs(freq1 - freq2)
	var freq_avg = (freq1 + freq2) / 2.0
	var diff_ratio = freq_diff / freq_avg
	
	# Use exponential falloff for matching
	# Perfect match (0 diff) = 1.0, large diff = ~0.0
	var match_strength = exp(-diff_ratio * 5.0)
	
	return match_strength


## Cancel an object through destructive interference
## Requirements: 20.5
func _cancel_object(object: Node3D) -> void:
	if not is_instance_valid(object):
		return
	
	object_cancelled.emit(object)
	
	# Remove object from scene and return it to background lattice
	# Requirements: 20.5
	object.queue_free()


## Get all currently tracked objects
func get_tracked_objects() -> Array[Node3D]:
	var objects: Array[Node3D] = []
	
	for obj_id in tracked_objects.keys():
		var data = tracked_objects[obj_id]
		var object = data["object"]
		
		if is_instance_valid(object):
			objects.append(object)
	
	return objects


## Clear all tracked objects
func clear_tracked_objects() -> void:
	tracked_objects.clear()
