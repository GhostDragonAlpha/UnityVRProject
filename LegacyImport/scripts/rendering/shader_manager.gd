## ShaderManager - Manages shader loading, compilation, and hot-reloading
## Provides a centralized system for loading .gdshader files, handling compilation
## errors with fallbacks, and supporting hot-reload during development.
##
## Requirements: 30.1 - Separate vertex displacement logic into shader files
## Requirements: 30.2 - Separate grid rendering logic into shader files
## Requirements: 30.3 - Separate post-processing effects into separate shader files
## Requirements: 30.4 - Support hot-reloading without requiring application restart
## Requirements: 30.5 - Compose multiple effects in a defined rendering pipeline order
extends Node
class_name ShaderManager

## Emitted when a shader is successfully loaded
signal shader_loaded(shader_name: String)
## Emitted when a shader fails to load
signal shader_load_failed(shader_name: String, error: String)
## Emitted when a shader is reloaded via hot-reload
signal shader_reloaded(shader_name: String)
## Emitted when shader parameters are updated
signal shader_parameter_changed(shader_name: String, param_name: String, value: Variant)

## Cache of loaded shaders by name
var _shader_cache: Dictionary = {}
## Cache of ShaderMaterial instances by name
var _material_cache: Dictionary = {}
## Fallback shader for when loading fails
var _fallback_shader: Shader = null
## Whether hot-reload is enabled
var _hot_reload_enabled: bool = false
## File modification times for hot-reload detection
var _file_mod_times: Dictionary = {}
## Hot-reload check interval in seconds
var _hot_reload_interval: float = 1.0
## Time since last hot-reload check
var _time_since_check: float = 0.0
## Shader file paths for hot-reload monitoring
var _shader_paths: Dictionary = {}

## Default shader directory
const SHADER_DIR := "res://shaders/"
## Fallback shader code (simple unlit magenta for visibility)
const FALLBACK_SHADER_CODE := """
shader_type spatial;
render_mode unshaded;

void fragment() {
	ALBEDO = vec3(1.0, 0.0, 1.0);
}
"""


func _ready() -> void:
	_create_fallback_shader()


func _process(delta: float) -> void:
	if _hot_reload_enabled:
		_time_since_check += delta
		if _time_since_check >= _hot_reload_interval:
			_time_since_check = 0.0
			_check_for_shader_changes()


## Create the fallback shader used when loading fails
func _create_fallback_shader() -> void:
	_fallback_shader = Shader.new()
	_fallback_shader.code = FALLBACK_SHADER_CODE



## Load a shader from a .gdshader file
## @param shader_name: Unique name to identify this shader
## @param shader_path: Path to the .gdshader file (relative to res://)
## @return: The loaded Shader resource, or fallback shader on failure
func load_shader(shader_name: String, shader_path: String) -> Shader:
	# Check cache first
	if _shader_cache.has(shader_name):
		return _shader_cache[shader_name]
	
	var full_path := shader_path
	if not shader_path.begins_with("res://"):
		full_path = SHADER_DIR + shader_path
	
	# Attempt to load the shader
	var shader := _load_shader_from_file(full_path)
	
	if shader != null:
		_shader_cache[shader_name] = shader
		_shader_paths[shader_name] = full_path
		_update_mod_time(shader_name, full_path)
		shader_loaded.emit(shader_name)
		print("ShaderManager: Loaded shader '%s' from '%s'" % [shader_name, full_path])
		return shader
	else:
		push_error("ShaderManager: Failed to load shader '%s' from '%s', using fallback" % [shader_name, full_path])
		shader_load_failed.emit(shader_name, "Failed to load shader file")
		return _fallback_shader


## Load shader from file with error handling
func _load_shader_from_file(path: String) -> Shader:
	if not FileAccess.file_exists(path):
		push_error("ShaderManager: Shader file not found: %s" % path)
		return null
	
	var shader: Shader = load(path) as Shader
	if shader == null:
		# Try loading as text and creating shader
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			push_error("ShaderManager: Cannot open shader file: %s" % path)
			return null
		
		var code := file.get_as_text()
		file.close()
		
		shader = Shader.new()
		shader.code = code
	
	return shader


## Create a ShaderMaterial from a loaded shader
## @param shader_name: Name of the shader (must be loaded first)
## @param material_name: Optional unique name for this material instance
## @return: A new ShaderMaterial using the specified shader
func create_shader_material(shader_name: String, material_name: String = "") -> ShaderMaterial:
	var shader := get_shader(shader_name)
	if shader == null:
		push_error("ShaderManager: Cannot create material, shader '%s' not found" % shader_name)
		shader = _fallback_shader
	
	var material := ShaderMaterial.new()
	material.shader = shader
	
	# Cache the material if a name is provided
	if material_name != "":
		_material_cache[material_name] = material
	
	return material


## Get a cached shader by name
## @param shader_name: Name of the shader to retrieve
## @return: The cached Shader, or null if not found
func get_shader(shader_name: String) -> Shader:
	if _shader_cache.has(shader_name):
		return _shader_cache[shader_name]
	return null


## Get a cached material by name
## @param material_name: Name of the material to retrieve
## @return: The cached ShaderMaterial, or null if not found
func get_material(material_name: String) -> ShaderMaterial:
	if _material_cache.has(material_name):
		return _material_cache[material_name]
	return null


## Check if a shader is loaded
func has_shader(shader_name: String) -> bool:
	return _shader_cache.has(shader_name)


## Check if a material exists
func has_material(material_name: String) -> bool:
	return _material_cache.has(material_name)



## Set a shader parameter on a material
## @param material_name: Name of the cached material
## @param param_name: Name of the shader parameter
## @param value: Value to set
func set_shader_parameter(material_name: String, param_name: String, value: Variant) -> void:
	var material := get_material(material_name)
	if material == null:
		push_error("ShaderManager: Cannot set parameter, material '%s' not found" % material_name)
		return
	
	material.set_shader_parameter(param_name, value)
	shader_parameter_changed.emit(material_name, param_name, value)


## Set a shader parameter directly on a ShaderMaterial instance
## @param material: The ShaderMaterial to modify
## @param param_name: Name of the shader parameter
## @param value: Value to set
func set_material_parameter(material: ShaderMaterial, param_name: String, value: Variant) -> void:
	if material == null:
		push_error("ShaderManager: Cannot set parameter on null material")
		return
	
	material.set_shader_parameter(param_name, value)


## Get a shader parameter from a material
## @param material_name: Name of the cached material
## @param param_name: Name of the shader parameter
## @return: The parameter value, or null if not found
func get_shader_parameter(material_name: String, param_name: String) -> Variant:
	var material := get_material(material_name)
	if material == null:
		push_error("ShaderManager: Cannot get parameter, material '%s' not found" % material_name)
		return null
	
	return material.get_shader_parameter(param_name)


## Enable hot-reload functionality for development
## Requirements: 30.4 - Support hot-reloading without requiring application restart
func enable_hot_reload() -> void:
	_hot_reload_enabled = true
	# Initialize modification times for all loaded shaders
	for shader_name in _shader_paths.keys():
		_update_mod_time(shader_name, _shader_paths[shader_name])
	print("ShaderManager: Hot-reload enabled")


## Disable hot-reload functionality
func disable_hot_reload() -> void:
	_hot_reload_enabled = false
	print("ShaderManager: Hot-reload disabled")


## Check if hot-reload is enabled
func is_hot_reload_enabled() -> bool:
	return _hot_reload_enabled


## Set the hot-reload check interval
## @param interval: Time in seconds between checks
func set_hot_reload_interval(interval: float) -> void:
	_hot_reload_interval = maxf(interval, 0.1)


## Update the stored modification time for a shader file
func _update_mod_time(shader_name: String, path: String) -> void:
	if FileAccess.file_exists(path):
		var mod_time := FileAccess.get_modified_time(path)
		_file_mod_times[shader_name] = mod_time


## Check for shader file changes and reload if necessary
func _check_for_shader_changes() -> void:
	for shader_name in _shader_paths.keys():
		var path: String = _shader_paths[shader_name]
		if not FileAccess.file_exists(path):
			continue
		
		var current_mod_time := FileAccess.get_modified_time(path)
		var stored_mod_time: int = _file_mod_times.get(shader_name, 0)
		
		if current_mod_time > stored_mod_time:
			print("ShaderManager: Detected change in '%s', reloading..." % shader_name)
			reload_shader(shader_name)



## Reload a specific shader from disk
## Requirements: 30.4 - Support hot-reloading without requiring application restart
## @param shader_name: Name of the shader to reload
## @return: true if reload was successful
func reload_shader(shader_name: String) -> bool:
	if not _shader_paths.has(shader_name):
		push_error("ShaderManager: Cannot reload unknown shader '%s'" % shader_name)
		return false
	
	var path: String = _shader_paths[shader_name]
	var new_shader := _load_shader_from_file(path)
	
	if new_shader == null:
		push_error("ShaderManager: Failed to reload shader '%s'" % shader_name)
		return false
	
	# Update the cached shader
	var old_shader: Shader = _shader_cache[shader_name]
	_shader_cache[shader_name] = new_shader
	
	# Update all materials using this shader
	_update_materials_with_shader(shader_name, new_shader)
	
	# Update modification time
	_update_mod_time(shader_name, path)
	
	shader_reloaded.emit(shader_name)
	print("ShaderManager: Reloaded shader '%s'" % shader_name)
	return true


## Reload all loaded shaders from disk
## @return: Number of shaders successfully reloaded
func reload_all_shaders() -> int:
	var count := 0
	for shader_name in _shader_paths.keys():
		if reload_shader(shader_name):
			count += 1
	return count


## Update all materials that use a specific shader
func _update_materials_with_shader(shader_name: String, new_shader: Shader) -> void:
	var shader_to_match: Shader = _shader_cache.get(shader_name)
	
	for material_name in _material_cache.keys():
		var material: ShaderMaterial = _material_cache[material_name]
		# Check if this material uses the shader we're updating
		# We need to update it to use the new shader instance
		if material.shader == shader_to_match or _is_material_using_shader(material_name, shader_name):
			material.shader = new_shader


## Check if a material is using a specific shader (by tracking)
func _is_material_using_shader(material_name: String, shader_name: String) -> bool:
	# This is a simple check - in a more complex system you might track
	# which materials use which shaders explicitly
	var material: ShaderMaterial = _material_cache.get(material_name)
	if material == null:
		return false
	
	var shader: Shader = _shader_cache.get(shader_name)
	return material.shader == shader


## Unload a shader and remove it from cache
## @param shader_name: Name of the shader to unload
func unload_shader(shader_name: String) -> void:
	if _shader_cache.has(shader_name):
		_shader_cache.erase(shader_name)
	if _shader_paths.has(shader_name):
		_shader_paths.erase(shader_name)
	if _file_mod_times.has(shader_name):
		_file_mod_times.erase(shader_name)
	print("ShaderManager: Unloaded shader '%s'" % shader_name)


## Clear all cached shaders and materials
func clear_cache() -> void:
	_shader_cache.clear()
	_material_cache.clear()
	_shader_paths.clear()
	_file_mod_times.clear()
	print("ShaderManager: Cache cleared")


## Get the fallback shader
func get_fallback_shader() -> Shader:
	return _fallback_shader


## Get list of all loaded shader names
func get_loaded_shader_names() -> Array[String]:
	var names: Array[String] = []
	for key in _shader_cache.keys():
		names.append(key)
	return names


## Get list of all cached material names
func get_cached_material_names() -> Array[String]:
	var names: Array[String] = []
	for key in _material_cache.keys():
		names.append(key)
	return names



## Load multiple shaders at once
## @param shader_definitions: Dictionary of {name: path} pairs
## @return: Number of shaders successfully loaded
func load_shaders(shader_definitions: Dictionary) -> int:
	var count := 0
	for shader_name in shader_definitions.keys():
		var path: String = shader_definitions[shader_name]
		var shader := load_shader(shader_name, path)
		if shader != _fallback_shader:
			count += 1
	return count


## Create a shader from code string (useful for procedural shaders)
## @param shader_name: Unique name for this shader
## @param shader_code: The GLSL shader code
## @return: The created Shader resource
func create_shader_from_code(shader_name: String, shader_code: String) -> Shader:
	var shader := Shader.new()
	shader.code = shader_code
	
	_shader_cache[shader_name] = shader
	shader_loaded.emit(shader_name)
	print("ShaderManager: Created shader '%s' from code" % shader_name)
	
	return shader


## Preload common shaders for the rendering pipeline
## Requirements: 30.5 - Compose multiple effects in a defined rendering pipeline order
func preload_pipeline_shaders() -> void:
	# Define the standard shader pipeline
	var pipeline_shaders := {
		# Lattice rendering shaders
		# Requirements: 30.1, 30.2 - Separate vertex and fragment logic
		"lattice": "lattice.gdshader",
		
		# Post-processing shaders
		# Requirements: 30.3 - Separate post-processing effects
		"post_glitch": "post_glitch.gdshader",
		"post_chromatic": "post_chromatic.gdshader",
		"post_scanlines": "post_scanlines.gdshader",
		
		# Planet and surface shaders
		"planet_surface": "planet_surface.gdshader",
		"atmosphere": "atmosphere.gdshader",
		
		# Volumetric effects
		"volumetric": "volumetric.gdshader",
	}
	
	# Attempt to load each shader (will use fallback if not found)
	for shader_name in pipeline_shaders.keys():
		var path: String = pipeline_shaders[shader_name]
		# Only load if file exists to avoid spam during development
		var full_path := SHADER_DIR + path
		if FileAccess.file_exists(full_path):
			load_shader(shader_name, path)
		else:
			print("ShaderManager: Pipeline shader '%s' not found at '%s' (will be created later)" % [shader_name, full_path])


## Get shader compilation errors (if any)
## Note: Godot doesn't expose shader compilation errors directly,
## but we can check if the shader is valid
## @param shader_name: Name of the shader to check
## @return: Empty string if valid, error message if invalid
func get_shader_errors(shader_name: String) -> String:
	var shader := get_shader(shader_name)
	if shader == null:
		return "Shader not found"
	
	# In Godot 4, we can check if shader code is empty or if it's the fallback
	if shader == _fallback_shader:
		return "Using fallback shader (original failed to load)"
	
	if shader.code.is_empty():
		return "Shader code is empty"
	
	return ""


## Validate a shader by checking if it can be used
## @param shader_name: Name of the shader to validate
## @return: true if shader is valid and usable
func validate_shader(shader_name: String) -> bool:
	var shader := get_shader(shader_name)
	if shader == null:
		return false
	if shader == _fallback_shader:
		return false
	if shader.code.is_empty():
		return false
	return true


## Get statistics about loaded shaders
func get_stats() -> Dictionary:
	return {
		"loaded_shaders": _shader_cache.size(),
		"cached_materials": _material_cache.size(),
		"hot_reload_enabled": _hot_reload_enabled,
		"shader_names": get_loaded_shader_names(),
		"material_names": get_cached_material_names()
	}


## Shutdown and cleanup
func shutdown() -> void:
	disable_hot_reload()
	clear_cache()
	print("ShaderManager: Shutdown complete")
