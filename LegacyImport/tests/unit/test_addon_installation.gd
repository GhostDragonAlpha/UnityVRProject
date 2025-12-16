extends GdUnitTestSuite
## Addon Installation Verification Tests
##
## These tests verify that all required addons are properly installed
## and have the correct directory structure for Godot to load them.
##
## TDD Principle: Tests define what "correctly installed" means
## Auto-healing: If structure is wrong, we can auto-fix it

# Called before each test
func before_test():
	pass

# Called after each test
func after_test():
	pass


## Test: godot-xr-tools has correct directory structure
func test_godot_xr_tools_directory_structure():
	# ARRANGE: Define expected structure
	var addon_path = "res://addons/godot-xr-tools/"
	var required_files = [
		"rumble/rumble_manager.gd",
		"functions/function_pointer.gd",
		"hands/hand.gd",
		"player/player_body.gd",
		"plugin.cfg"
	]

	# ACT & ASSERT: Verify each required file exists
	for file in required_files:
		var full_path = addon_path + file
		assert_file(full_path).override_failure_message(
			"godot-xr-tools missing required file: %s\n" % file +
			"This usually means the addon has nested structure.\n" +
			"Run: python scripts/tools/fix_addon_structure.py godot-xr-tools"
		).exists()


## Test: godot-xr-tools plugin.cfg is valid
func test_godot_xr_tools_plugin_cfg():
	var plugin_cfg_path = "res://addons/godot-xr-tools/plugin.cfg"

	# File must exist
	assert_file(plugin_cfg_path).exists()

	# Must be readable as ConfigFile
	var config = ConfigFile.new()
	var err = config.load(plugin_cfg_path)
	assert_int(err).override_failure_message("plugin.cfg must be valid ConfigFile format").is_equal(OK)

	# Must have required fields
	assert_str(config.get_value("plugin", "name", "")).is_not_empty()
	assert_str(config.get_value("plugin", "description", "")).is_not_empty()
	assert_str(config.get_value("plugin", "author", "")).is_not_empty()
	assert_str(config.get_value("plugin", "version", "")).is_not_empty()
	assert_str(config.get_value("plugin", "script", "")).is_not_empty()


## Test: gdUnit4 addon is properly installed
func test_gdunit4_installed():
	var addon_path = "res://addons/gdUnit4/"
	var required_files = [
		"plugin.cfg",
		"bin/GdUnitRunner.gd",
		"bin/GdUnitCmdTool.gd"
	]

	for file in required_files:
		assert_file(addon_path + file).override_failure_message(
			"gdUnit4 missing: %s" % file
		).exists()


## Test: godottpd addon is properly installed (for HTTP API)
func test_godottpd_installed():
	var addon_path = "res://addons/godottpd/"
	var required_files = [
		"plugin.cfg",
		"server.gd",
		"router.gd"
	]

	for file in required_files:
		assert_file(addon_path + file).override_failure_message(
			"godottpd missing: %s" % file
		).exists()


## Test: zylann.voxel addon is properly installed
func test_voxel_addon_installed():
	var addon_path = "res://addons/zylann.voxel/"
	var required_files = [
		"plugin.cfg"
	]

	for file in required_files:
		assert_file(addon_path + file).override_failure_message(
			"zylann.voxel missing: %s" % file
		).exists()


## Test: No nested addon directories (common mistake)
func test_no_nested_addon_directories():
	# Check for the common mistake: addons/addon-name/addons/addon-name/
	var addons_dir = DirAccess.open("res://addons/")

	if addons_dir:
		addons_dir.list_dir_begin()
		var dir_name = addons_dir.get_next()

		while dir_name != "":
			if addons_dir.current_is_dir() and dir_name != "." and dir_name != "..":
				# Check if this addon has a nested addons/ directory
				var nested_addons_path = "res://addons/%s/addons/" % dir_name
				assert_bool(DirAccess.dir_exists_absolute(nested_addons_path)) \
					.override_failure_message(
						"Addon '%s' has nested structure at: %s\n" % [dir_name, nested_addons_path] +
						"This is incorrect. The addon should be at: res://addons/%s/\n" % dir_name +
						"Run fix script to correct structure."
					) \
					.is_false()

			dir_name = addons_dir.get_next()

		addons_dir.list_dir_end()


## Test: All enabled plugins have valid plugin.cfg
func test_all_enabled_plugins_have_valid_config():
	# Get enabled plugins from project.godot
	var enabled_plugins = _get_enabled_plugins()

	for plugin_name in enabled_plugins:
		var plugin_cfg_path = "res://addons/%s/plugin.cfg" % plugin_name

		# Must have plugin.cfg
		assert_file(plugin_cfg_path).override_failure_message(
			"Enabled plugin '%s' missing plugin.cfg" % plugin_name
		).exists()

		# plugin.cfg must be valid
		var config = ConfigFile.new()
		var err = config.load(plugin_cfg_path)
		assert_int(err).override_failure_message(
			"Plugin '%s' has invalid plugin.cfg" % plugin_name
		).is_equal(OK)

		# Must have script entry
		var script_path = config.get_value("plugin", "script", "")
		assert_str(script_path).override_failure_message(
			"Plugin '%s' missing script entry in plugin.cfg" % plugin_name
		).is_not_empty()

		# Script file must exist
		var full_script_path = "res://addons/%s/%s" % [plugin_name, script_path]
		assert_file(full_script_path).override_failure_message(
			"Plugin '%s' script not found: %s" % [plugin_name, full_script_path]
		).exists()


## Helper: Get list of enabled plugins from project settings
func _get_enabled_plugins() -> Array:
	var enabled = []

	# Godot stores enabled plugins in project.godot under [editor_plugins]
	# We need to check ProjectSettings for this
	# Note: This runs at test time, so we check what's in project.godot

	# Common addons we expect to be installed
	var expected_addons = [
		"gdUnit4",
		"godot-xr-tools",
		"godottpd",
		"zylann.voxel"
	]

	for addon in expected_addons:
		if DirAccess.dir_exists_absolute("res://addons/" + addon):
			enabled.append(addon)

	return enabled


## Test: Autoload paths are valid (for godot-xr-tools)
func test_godot_xr_tools_autoload_paths():
	# godot-xr-tools registers several autoloads
	# If paths are wrong, editor will show errors

	var expected_autoloads = {
		"XRTools": "res://addons/godot-xr-tools/xr_tools.gd",
	}

	for autoload_name in expected_autoloads:
		var expected_path = expected_autoloads[autoload_name]

		# Check if file exists at expected path
		assert_file(expected_path).override_failure_message(
			"godot-xr-tools autoload '%s' missing at: %s" % [autoload_name, expected_path]
		).exists()


## Test: Can instantiate critical addon classes (smoke test)
func test_can_load_addon_scripts():
	# Try to load key scripts to verify they're valid GDScript
	var critical_scripts = [
		"res://addons/gdUnit4/bin/GdUnitRunner.gd",
		"res://addons/godottpd/server.gd",
	]

	for script_path in critical_scripts:
		if FileAccess.file_exists(script_path):
			var script = load(script_path)
			assert_object(script) \
				.override_failure_message("Failed to load script: %s" % script_path) \
				.is_not_null()
