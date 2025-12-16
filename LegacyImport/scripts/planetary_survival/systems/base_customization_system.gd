## BaseCustomizationSystem - Manages decorative items, painting, lighting, and materials
## Handles VR-optimized base aesthetics and customization
##
## Requirements: 31.1, 31.2, 31.3, 31.4, 31.5
## - 31.1: Allow decorative item placement with free positioning and rotation in VR
## - 31.2: Apply color to terrain and structures using a color picker
## - 31.3: Calculate real-time illumination with appropriate shadows
## - 31.4: Display distinct visual textures for different material types
## - 31.5: Maintain visual fidelity while preserving VR performance
extends Node
class_name BaseCustomizationSystem

## Emitted when a decorative item is placed
signal decorative_item_placed(item: DecorativeItem, position: Vector3)

## Emitted when a surface is painted
signal surface_painted(target: Node3D, color: Color)

## Emitted when lighting is updated
signal lighting_updated(light: Light3D)

## Emitted when material is changed
signal material_changed(target: Node3D, material_type: String)

# Decorative items registry
var decorative_items: Dictionary = {} # int -> DecorativeItem
var next_item_id: int = 0

# Painting system
var painted_surfaces: Dictionary = {} # Node3D -> Color
var paint_brush_size: float = 1.0
var current_paint_color: Color = Color.WHITE

# Lighting system
var placed_lights: Array[Light3D] = []
var max_lights_per_area: int = 8 # VR performance limit
var shadow_quality: int = 1 # 0=off, 1=low, 2=medium, 3=high

# Material system
var material_library: Dictionary = {} # String -> Material
var material_variations: Dictionary = {} # String -> Array[Material]

# Performance tracking
var active_decorations: int = 0
var max_decorations: int = 500 # VR performance limit
var shadow_update_interval: float = 0.1
var shadow_update_timer: float = 0.0

# VR optimization
var lod_distances: Array[float] = [10.0, 25.0, 50.0] # LOD thresholds
var culling_distance: float = 100.0


func _ready() -> void:
	_initialize_material_library()
	_setup_default_materials()
	print("BaseCustomizationSystem initialized")


func _process(delta: float) -> void:
	shadow_update_timer += delta
	if shadow_update_timer >= shadow_update_interval:
		_update_shadow_quality()
		shadow_update_timer = 0.0


## Initialize the material library with base materials
func _initialize_material_library() -> void:
	# Metal materials
	material_library["metal_smooth"] = _create_metal_material(0.1, 0.9)
	material_library["metal_rough"] = _create_metal_material(0.8, 0.3)
	material_library["metal_brushed"] = _create_metal_material(0.4, 0.6)
	
	# Stone materials
	material_library["stone_smooth"] = _create_stone_material(0.2)
	material_library["stone_rough"] = _create_stone_material(0.8)
	material_library["stone_polished"] = _create_stone_material(0.05)
	
	# Composite materials
	material_library["composite_matte"] = _create_composite_material(0.7)
	material_library["composite_glossy"] = _create_composite_material(0.2)
	
	# Glass materials
	material_library["glass_clear"] = _create_glass_material(0.95)
	material_library["glass_frosted"] = _create_glass_material(0.5)
	
	print("Material library initialized with ", material_library.size(), " materials")


## Create a metal PBR material
func _create_metal_material(roughness: float, metallic: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.metallic = metallic
	mat.roughness = roughness
	mat.albedo_color = Color(0.8, 0.8, 0.8)
	return mat


## Create a stone PBR material
func _create_stone_material(roughness: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.metallic = 0.0
	mat.roughness = roughness
	mat.albedo_color = Color(0.5, 0.5, 0.5)
	return mat


## Create a composite PBR material
func _create_composite_material(roughness: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.metallic = 0.2
	mat.roughness = roughness
	mat.albedo_color = Color(0.6, 0.6, 0.7)
	return mat


## Create a glass PBR material
func _create_glass_material(transparency: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1.0, 1.0, 1.0, 1.0 - transparency)
	mat.metallic = 0.0
	mat.roughness = 0.1
	return mat


## Setup default material variations
func _setup_default_materials() -> void:
	# Create color variations for each base material
	for mat_name in material_library.keys():
		var variations: Array[Material] = []
		var base_mat: StandardMaterial3D = material_library[mat_name]
		
		# Create 5 color variations
		for i in range(5):
			var variant := base_mat.duplicate() as StandardMaterial3D
			variant.albedo_color = _get_variation_color(i)
			variations.append(variant)
		
		material_variations[mat_name] = variations


## Get a color variation based on index
func _get_variation_color(index: int) -> Color:
	match index:
		0: return Color(0.8, 0.8, 0.8) # Light gray
		1: return Color(0.4, 0.4, 0.4) # Dark gray
		2: return Color(0.6, 0.4, 0.3) # Brown
		3: return Color(0.3, 0.5, 0.6) # Blue-gray
		4: return Color(0.5, 0.6, 0.4) # Green-gray
		_: return Color.WHITE


## Place a decorative item in the world
## Requirements: 31.1
func place_decorative_item(item_type: String, position: Vector3, rotation: Quaternion) -> DecorativeItem:
	if active_decorations >= max_decorations:
		push_warning("Maximum decoration limit reached: ", max_decorations)
		return null
	
	var item := DecorativeItem.new()
	item.item_type = item_type
	item.item_id = next_item_id
	next_item_id += 1
	item.position = position
	item.rotation = rotation
	
	decorative_items[item.item_id] = item
	active_decorations += 1
	
	decorative_item_placed.emit(item, position)
	return item


## Remove a decorative item
func remove_decorative_item(item_id: int) -> bool:
	if not decorative_items.has(item_id):
		return false
	
	decorative_items.erase(item_id)
	active_decorations -= 1
	return true


## Paint a surface with a color
## Requirements: 31.2
func paint_surface(target: Node3D, color: Color, brush_size: float = 1.0) -> bool:
	if not is_instance_valid(target):
		return false
	
	# Apply color to the target's material
	if target is MeshInstance3D:
		var mesh_instance := target as MeshInstance3D
		var mat := mesh_instance.get_active_material(0)
		
		if mat is StandardMaterial3D:
			var painted_mat := mat.duplicate() as StandardMaterial3D
			painted_mat.albedo_color = color
			mesh_instance.set_surface_override_material(0, painted_mat)
			
			painted_surfaces[target] = color
			surface_painted.emit(target, color)
			return true
	
	return false


## Get the current paint color for a surface
func get_surface_color(target: Node3D) -> Color:
	if painted_surfaces.has(target):
		return painted_surfaces[target]
	return Color.WHITE


## Set the current paint brush color
func set_paint_color(color: Color) -> void:
	current_paint_color = color


## Set the paint brush size
func set_brush_size(size: float) -> void:
	paint_brush_size = clamp(size, 0.1, 10.0)


## Place a light source
## Requirements: 31.3
func place_light(light_type: String, position: Vector3, color: Color = Color.WHITE, energy: float = 1.0) -> Light3D:
	# Check light limit for performance
	var nearby_lights := _count_nearby_lights(position, 10.0)
	if nearby_lights >= max_lights_per_area:
		push_warning("Too many lights in area, performance limit reached")
		return null
	
	var light: Light3D = null
	
	match light_type:
		"omni":
			var omni := OmniLight3D.new()
			omni.omni_range = 10.0
			light = omni
		"spot":
			var spot := SpotLight3D.new()
			spot.spot_range = 15.0
			spot.spot_angle = 45.0
			light = spot
		"directional":
			var directional := DirectionalLight3D.new()
			light = directional
		_:
			push_error("Unknown light type: ", light_type)
			return null
	
	light.light_color = color
	light.light_energy = energy
	light.position = position
	
	# Configure shadows based on quality setting
	_configure_light_shadows(light)
	
	placed_lights.append(light)
	lighting_updated.emit(light)
	
	return light


## Remove a light source
func remove_light(light: Light3D) -> bool:
	var index := placed_lights.find(light)
	if index >= 0:
		placed_lights.remove_at(index)
		if is_instance_valid(light):
			light.queue_free()
		return true
	return false


## Count nearby lights for performance management
func _count_nearby_lights(position: Vector3, radius: float) -> int:
	var count := 0
	for light in placed_lights:
		if is_instance_valid(light) and light.global_position.distance_to(position) <= radius:
			count += 1
	return count


## Configure light shadows based on quality setting
func _configure_light_shadows(light: Light3D) -> void:
	match shadow_quality:
		0: # Off
			light.shadow_enabled = false
		1: # Low
			light.shadow_enabled = true
			if light is OmniLight3D:
				(light as OmniLight3D).omni_shadow_mode = OmniLight3D.SHADOW_CUBE
			elif light is SpotLight3D:
				(light as SpotLight3D).shadow_blur = 0.5
		2: # Medium
			light.shadow_enabled = true
			if light is OmniLight3D:
				(light as OmniLight3D).omni_shadow_mode = OmniLight3D.SHADOW_CUBE
			elif light is SpotLight3D:
				(light as SpotLight3D).shadow_blur = 1.0
		3: # High
			light.shadow_enabled = true
			if light is OmniLight3D:
				(light as OmniLight3D).omni_shadow_mode = OmniLight3D.SHADOW_CUBE
			elif light is SpotLight3D:
				(light as SpotLight3D).shadow_blur = 1.5


## Update shadow quality dynamically based on performance
## Requirements: 31.5
func _update_shadow_quality() -> void:
	var fps := Engine.get_frames_per_second()
	
	# Adjust shadow quality to maintain 90 FPS
	if fps < 85:
		if shadow_quality > 0:
			shadow_quality -= 1
			_apply_shadow_quality_to_all_lights()
			print("Reduced shadow quality to ", shadow_quality, " (FPS: ", fps, ")")
	elif fps > 95 and shadow_quality < 3:
		shadow_quality += 1
		_apply_shadow_quality_to_all_lights()
		print("Increased shadow quality to ", shadow_quality, " (FPS: ", fps, ")")


## Apply current shadow quality to all lights
func _apply_shadow_quality_to_all_lights() -> void:
	for light in placed_lights:
		if is_instance_valid(light):
			_configure_light_shadows(light)


## Apply a material to a target object
## Requirements: 31.4
func apply_material(target: Node3D, material_type: String, variation_index: int = 0) -> bool:
	if not is_instance_valid(target):
		return false
	
	if not material_library.has(material_type):
		push_error("Unknown material type: ", material_type)
		return false
	
	var material: Material = null
	
	# Get variation if available
	if material_variations.has(material_type):
		var variations: Array = material_variations[material_type]
		if variation_index >= 0 and variation_index < variations.size():
			material = variations[variation_index]
		else:
			material = material_library[material_type]
	else:
		material = material_library[material_type]
	
	# Apply to mesh instance
	if target is MeshInstance3D:
		var mesh_instance := target as MeshInstance3D
		mesh_instance.set_surface_override_material(0, material)
		material_changed.emit(target, material_type)
		return true
	
	return false


## Get available material types
func get_material_types() -> Array[String]:
	var types: Array[String] = []
	for key in material_library.keys():
		types.append(key)
	return types


## Get material variations for a type
func get_material_variations(material_type: String) -> int:
	if material_variations.has(material_type):
		return material_variations[material_type].size()
	return 0


## Set shadow quality (0-3)
func set_shadow_quality(quality: int) -> void:
	shadow_quality = clamp(quality, 0, 3)
	_apply_shadow_quality_to_all_lights()


## Get current shadow quality
func get_shadow_quality() -> int:
	return shadow_quality


## Set maximum decorations limit
func set_max_decorations(limit: int) -> void:
	max_decorations = max(0, limit)


## Get decoration count
func get_decoration_count() -> int:
	return active_decorations


## Get light count
func get_light_count() -> int:
	return placed_lights.size()


## Clear all customizations
func clear_all_customizations() -> void:
	decorative_items.clear()
	painted_surfaces.clear()
	
	for light in placed_lights:
		if is_instance_valid(light):
			light.queue_free()
	placed_lights.clear()
	
	active_decorations = 0
	print("All customizations cleared")


## Shutdown the system
func shutdown() -> void:
	clear_all_customizations()
	material_library.clear()
	material_variations.clear()
	print("BaseCustomizationSystem shutdown")


## DecorativeItem - Represents a placed decorative item
class DecorativeItem:
	var item_id: int = -1
	var item_type: String = ""
	var position: Vector3 = Vector3.ZERO
	var rotation: Quaternion = Quaternion.IDENTITY
	var scale: Vector3 = Vector3.ONE
	var custom_data: Dictionary = {}
