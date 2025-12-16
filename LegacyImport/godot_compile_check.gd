extends SceneTree

# Godot script to check compilation of specific files
# This uses Godot's actual GDScript parser

func _init():
	var files = [
		"res://scripts/core/voxel_performance_monitor.gd",
		"res://scripts/procedural/voxel_generator_procedural.gd",
		"res://scripts/procedural/terrain_noise_generator.gd",
		"res://scripts/procedural/planet_generator.gd",
		"res://scripts/voxel_terrain_generator.gd",
		"res://voxel_test_terrain.gd",
		"res://tests/unit/test_voxel_terrain.gd"
	]

	print("================================================================================")
	print("VOXEL TERRAIN COMPILATION CHECK REPORT")
	print("================================================================================")
	print()

	var total = files.size()
	var passed = 0
	var failed = 0

	for file_path in files:
		print("Checking: ", file_path)

		# Check if file exists
		if not FileAccess.file_exists(file_path):
			print("  [FAIL] FILE NOT FOUND")
			failed += 1
			print()
			continue

		# Try to load the script
		var script = load(file_path)

		if script == null:
			print("  [FAIL] Script failed to load/compile")
			failed += 1
		elif script is GDScript:
			# Check for parse errors
			if script.reload() == OK:
				print("  [PASS] Compiled successfully")
				passed += 1
			else:
				print("  [FAIL] Script has parse errors")
				failed += 1
		else:
			print("  [FAIL] Not a valid GDScript")
			failed += 1

		print()

	# Summary
	print("================================================================================")
	print("SUMMARY")
	print("================================================================================")
	print("Total files checked: ", total)
	print("Passed: ", passed)
	print("Failed: ", failed)
	print()

	if failed == 0:
		print("[SUCCESS] ALL FILES PASSED COMPILATION CHECK")
		quit(0)
	else:
		print("[FAILURE] ", failed, " FILE(S) FAILED COMPILATION CHECK")
		quit(1)
