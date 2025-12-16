extends SceneTree

## Static Verifier - Editor Loop Check
## Runs in headless mode to validate project configuration and file integrity.
## Usage: godot --headless --script scripts/core/static_verifier.gd

func _init():
	print("[StaticVerifier] Starting checks...")
	var passed = 0
	var failed = 0
	
	# Check 1: VR Enabled
	var vr_enabled = ProjectSettings.get_setting("xr/openxr/enabled")
	if vr_enabled:
		print("[PASS] VR is enabled in ProjectSettings.")
		passed += 1
	else:
		push_error("[FAIL] VR is DISABLED in ProjectSettings!")
		failed += 1
		
	# Check 2: Main Scene
	var main_scene = ProjectSettings.get_setting("application/run/main_scene")
	if main_scene == "res://vr_main.tscn":
		print("[PASS] Main Scene is set to vr_main.tscn.")
		passed += 1
	else:
		push_error("[FAIL] Main Scene is NOT vr_main.tscn! Found: " + str(main_scene))
		failed += 1
		
	# Check 3: Critical Files Exist
	var critical_files = [
		"res://vr_main.tscn",
		"res://scripts/core/runtime_verifier.gd",
		"res://scripts/core/engine.gd"
	]
	
	for file_path in critical_files:
		if FileAccess.file_exists(file_path):
			print("[PASS] File exists: " + file_path)
			passed += 1
		else:
			push_error("[FAIL] Missing critical file: " + file_path)
			failed += 1
			
	print("------------------------------------------------")
	print("[StaticVerifier] Completed. Passed: %d, Failed: %d" % [passed, failed])
	
	if failed > 0:
		print("[StaticVerifier] FAILED. Fix errors before launching.")
		quit(1)
	else:
		print("[StaticVerifier] SUCCESS.")
		quit(0)
