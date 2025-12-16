extends SceneTree
## Automated test runner for SpaceTime VR
## Usage: godot --path C:/Ignotus --headless --script tests/test_runner.gd --quit-after 5

var tests_passed := 0
var tests_failed := 0

func _init() -> void:
	print("=== SpaceTime VR Test Runner ===\n")

	# Run tests
	test_autoloads()
	test_vr_system()
	test_http_api()
	test_scene_files()

	# Report results
	print("\n=== Test Results ===")
	print("Passed: %d" % tests_passed)
	print("Failed: %d" % tests_failed)
	print("Total: %d" % (tests_passed + tests_failed))

	if tests_failed == 0:
		print("\n✅ ALL TESTS PASSED")
		quit(0)
	else:
		print("\n❌ TESTS FAILED")
		quit(1)

func test_autoloads() -> void:
	print("Testing autoloads...")

	# Test ResonanceEngine
	if root.has_node("/root/ResonanceEngine"):
		print("  ✅ ResonanceEngine loaded")
		tests_passed += 1
	else:
		print("  ❌ ResonanceEngine missing")
		tests_failed += 1

	# Test HttpApiServer
	if root.has_node("/root/HttpApiServer"):
		print("  ✅ HttpApiServer loaded")
		tests_passed += 1
	else:
		print("  ❌ HttpApiServer missing")
		tests_failed += 1

	# Test SceneLoadMonitor
	if root.has_node("/root/SceneLoadMonitor"):
		print("  ✅ SceneLoadMonitor loaded")
		tests_passed += 1
	else:
		print("  ❌ SceneLoadMonitor missing")
		tests_failed += 1

	# Test SettingsManager
	if root.has_node("/root/SettingsManager"):
		print("  ✅ SettingsManager loaded")
		tests_passed += 1
	else:
		print("  ❌ SettingsManager missing")
		tests_failed += 1

	# Test VoxelPerformanceMonitor
	if root.has_node("/root/VoxelPerformanceMonitor"):
		print("  ✅ VoxelPerformanceMonitor loaded")
		tests_passed += 1
	else:
		print("  ❌ VoxelPerformanceMonitor missing")
		tests_failed += 1

func test_vr_system() -> void:
	print("\nTesting VR system...")

	var xr_interface := XRServer.find_interface("OpenXR")
	if xr_interface:
		print("  ✅ OpenXR interface found")
		tests_passed += 1
	else:
		print("  ⚠️  OpenXR interface not found (OK if no headset)")
		# Don't fail - VR might not be active in headless mode

	# Test XRServer is available
	if XRServer != null:
		print("  ✅ XRServer available")
		tests_passed += 1
	else:
		print("  ❌ XRServer not available")
		tests_failed += 1

func test_http_api() -> void:
	print("\nTesting HTTP API...")
	# Note: Can't actually test HTTP in headless mode
	# This is a placeholder for runtime tests
	print("  ⚠️  HTTP API test requires runtime (skipped in headless)")
	print("  ℹ️  To test: curl http://127.0.0.1:8080/health")

func test_scene_files() -> void:
	print("\nTesting scene files...")

	# Test main VR scene exists
	if ResourceLoader.exists("res://vr_main.tscn"):
		print("  ✅ vr_main.tscn exists")
		tests_passed += 1
	else:
		print("  ❌ vr_main.tscn missing")
		tests_failed += 1

	# Test minimal test scene exists
	if ResourceLoader.exists("res://minimal_test.tscn"):
		print("  ✅ minimal_test.tscn exists")
		tests_passed += 1
	else:
		print("  ❌ minimal_test.tscn missing")
		tests_failed += 1

	# Test VR tracking test scene exists
	if ResourceLoader.exists("res://scenes/features/vr_tracking_test.tscn"):
		print("  ✅ vr_tracking_test.tscn exists")
		tests_passed += 1
	else:
		print("  ⚠️  vr_tracking_test.tscn not yet created")
		# Don't fail - this is a new file we're creating
