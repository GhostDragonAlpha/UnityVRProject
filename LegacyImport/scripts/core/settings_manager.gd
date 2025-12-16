## SettingsManager - Handles user configuration
##
## Manages application settings (Graphics, Audio, Controls, VR) using ConfigFile.
## Persists settings to user://settings.cfg.
##
## Requirements:
## - 11.5: Persist user settings
## - 11.6: Apply settings on startup
## - 11.7: Support multiple settings categories
extends Node
# Note: SettingsManager is an autoload singleton, no class_name needed (would hide autoload)

## Signal emitted when settings are loaded
signal settings_loaded

## Signal emitted when settings are saved
signal settings_saved

## Signal emitted when a specific setting changes
signal setting_changed(section: String, key: String, value: Variant)

## Path to settings file
const SETTINGS_PATH: String = "user://settings.cfg"

## ConfigFile instance
var config: ConfigFile = ConfigFile.new()

## Default settings
var defaults: Dictionary = {
	"graphics": {
		"quality": "High", # Low, Medium, High, Ultra
		"fullscreen": false,
		"vsync": true,
		"render_scale": 1.0,
		"msaa": 2 # 0 (Disabled), 1 (2x), 2 (4x), 3 (8x)
	},
	"audio": {
		"master_volume": 1.0,
		"music_volume": 0.8,
		"sfx_volume": 1.0,
		"voice_volume": 1.0,
		"mute": false
	},
	"controls": {
		"mouse_sensitivity": 3.0,
		"invert_y": false,
		"vibration": true,
		"deadzone_trigger": 0.1,      # Dead zone for trigger (0.0-1.0)
		"deadzone_grip": 0.1,          # Dead zone for grip (0.0-1.0)
		"deadzone_thumbstick": 0.15,   # Dead zone for thumbstick (0.0-1.0)
		"deadzone_enabled": true,      # Enable dead zones globally
		"button_debounce_ms": 50       # Button debounce window in milliseconds
	},
	"vr": {
		"enabled": true,
		"comfort_mode": true,
		"vignetting_enabled": true,
		"vignetting_intensity": 0.7,
		"snap_turn_enabled": false,
		"snap_turn_angle": 45.0,
		"stationary_mode": false
	},
	"http_server": {
		"request_timeout": 30.0  # Timeout in seconds for HTTP requests (VULN-011 mitigation)
	}
}
func _ready() -> void:
	load_settings()

## Load settings from file
func load_settings() -> void:
	var err := config.load(SETTINGS_PATH)
	
	if err != OK:
		_log_info("No settings file found or failed to load. Using defaults.")
		_create_defaults()
		save_settings()
	else:
		_log_info("Settings loaded successfully.")
		_validate_settings()
	
	_apply_settings()
	settings_loaded.emit()

## Save settings to file
func save_settings() -> void:
	var err := config.save(SETTINGS_PATH)
	if err != OK:
		_log_error("Failed to save settings: Error %d" % err)
	else:
		_log_info("Settings saved successfully.")
		settings_saved.emit()

## Get a setting value
func get_setting(section: String, key: String, default_override = null) -> Variant:
	if default_override != null:
		return config.get_value(section, key, default_override)
	
	# Try to get from config, fallback to defaults
	if config.has_section_key(section, key):
		return config.get_value(section, key)
	
	if defaults.has(section) and defaults[section].has(key):
		return defaults[section][key]
	
	return null

## Set a setting value
func set_setting(section: String, key: String, value: Variant) -> void:
	config.set_value(section, key, value)
	setting_changed.emit(section, key, value)
	
	# Auto-save on change (optional, could be explicit)
	# save_settings() 
	
	# Apply immediately if needed
	_apply_single_setting(section, key, value)

## Reset all settings to defaults
func reset_to_defaults() -> void:
	config.clear()
	_create_defaults()
	save_settings()
	_apply_settings()
	_log_info("Settings reset to defaults.")

## Private: Create default settings in config
func _create_defaults() -> void:
	for section in defaults:
		for key in defaults[section]:
			config.set_value(section, key, defaults[section][key])

## Private: Validate settings against defaults (ensure new keys exist)
func _validate_settings() -> void:
	var changed := false
	for section in defaults:
		for key in defaults[section]:
			if not config.has_section_key(section, key):
				config.set_value(section, key, defaults[section][key])
				changed = true
	
	if changed:
		save_settings()

## Private: Apply all settings to the engine
func _apply_settings() -> void:
	# Graphics
	_apply_graphics_settings()
	
	# Audio
	_apply_audio_settings()
	
	# VR
	_apply_vr_settings()

## Private: Apply a single setting
func _apply_single_setting(section: String, key: String, value: Variant) -> void:
	match section:
		"graphics":
			_apply_graphics_settings() # Simpler to re-apply all graphics for now
		"audio":
			_apply_audio_settings()
		"vr":
			_apply_vr_settings()

## Private: Apply graphics settings
func _apply_graphics_settings() -> void:
	var fullscreen = get_setting("graphics", "fullscreen")
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
	var vsync = get_setting("graphics", "vsync")
	if vsync:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	
	var scale = get_setting("graphics", "render_scale")
	var viewport = get_viewport()
	if viewport:
		viewport.scaling_3d_scale = scale
	else:
		push_warning("SettingsManager: Could not get viewport for render_scale setting")
	
	var msaa = get_setting("graphics", "msaa")
	viewport = get_viewport()
	if viewport:
		viewport.msaa_3d = msaa
	else:
		push_warning("SettingsManager: Could not get viewport for msaa_3d setting")

## Private: Apply audio settings
func _apply_audio_settings() -> void:
	var master_vol = get_setting("audio", "master_volume")
	var mute = get_setting("audio", "mute")
	
	var master_bus = AudioServer.get_bus_index("Master")
	if mute:
		AudioServer.set_bus_mute(master_bus, true)
	else:
		AudioServer.set_bus_mute(master_bus, false)
		# Convert linear 0-1 to db
		var db = linear_to_db(master_vol)
		AudioServer.set_bus_volume_db(master_bus, db)

## Private: Apply VR settings
func _apply_vr_settings() -> void:
	# VR settings are mostly consumed by VRManager, which should query this manager
	pass

## Logging helpers
func _log_info(message: String) -> void:
	print("[INFO] [SettingsManager] " + message)

func _log_error(message: String) -> void:
	push_error("[SettingsManager] " + message)
