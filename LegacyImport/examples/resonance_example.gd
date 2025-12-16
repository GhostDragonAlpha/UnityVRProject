extends Node

## Example demonstrating ResonanceSystem usage
## Shows how to scan objects and apply interference

var resonance_system: ResonanceSystem
var test_objects: Array[Node3D] = []


func _ready() -> void:
	print("=== Resonance System Example ===\n")
	
	# Create resonance system
	resonance_system = ResonanceSystem.new()
	add_child(resonance_system)
	
	# Connect to signals
	resonance_system.object_scanned.connect(_on_object_scanned)
	resonance_system.interference_applied.connect(_on_interference_applied)
	resonance_system.object_cancelled.connect(_on_object_cancelled)
	
	# Create some test objects
	_create_test_objects()
	
	# Demonstrate scanning
	print("--- Scanning Objects ---")
	for obj in test_objects:
		var frequency = resonance_system.scan_object(obj)
		print("Scanned %s: frequency = %.2f Hz" % [obj.name, frequency])
	
	print("\n--- Applying Constructive Interference ---")
	# Apply constructive interference to first object
	if test_objects.size() > 0:
		var target_freq = resonance_system.get_object_frequency(test_objects[0])
		print("Emitting matching frequency: %.2f Hz" % target_freq)
		resonance_system.emit_matching_frequency(target_freq)
		
		# Wait a bit
		await get_tree().create_timer(1.0).timeout
		
		var amplitude = resonance_system.get_object_amplitude(test_objects[0])
		print("Object amplitude after 1s: %.3f" % amplitude)
		
		resonance_system.stop_emission()
	
	print("\n--- Applying Destructive Interference ---")
	# Apply destructive interference to second object
	if test_objects.size() > 1:
		var target_freq = resonance_system.get_object_frequency(test_objects[1])
		print("Emitting inverted frequency: %.2f Hz" % target_freq)
		resonance_system.emit_inverted_frequency(target_freq)
		
		# Wait for cancellation
		await get_tree().create_timer(2.0).timeout
		
		if is_instance_valid(test_objects[1]):
			var amplitude = resonance_system.get_object_amplitude(test_objects[1])
			print("Object amplitude after 2s: %.3f" % amplitude)
		else:
			print("Object was cancelled!")
		
		resonance_system.stop_emission()
	
	print("\n=== Example Complete ===")


func _create_test_objects() -> void:
	# Create a few test objects with different properties
	for i in range(3):
		var obj = Node3D.new()
		obj.name = "TestObject_%d" % i
		obj.global_position = Vector3(i * 10, 0, 0)
		add_child(obj)
		test_objects.append(obj)


func _on_object_scanned(object: Node3D, frequency: float) -> void:
	print("  → Object scanned: %s at %.2f Hz" % [object.name, frequency])


func _on_interference_applied(object: Node3D, interference_type: String, amplitude_change: float) -> void:
	var sign = "+" if amplitude_change > 0 else ""
	print("  → %s interference on %s: %s%.4f" % [interference_type.capitalize(), object.name, sign, amplitude_change])


func _on_object_cancelled(object: Node3D) -> void:
	print("  → Object cancelled: %s" % object.name)
