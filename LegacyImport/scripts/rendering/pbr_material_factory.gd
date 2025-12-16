## PBRMaterialFactory - Factory for creating PBR materials
## Creates StandardMaterial3D instances with consistent PBR settings.
## Provides presets for common space simulation materials.
##
## Requirements: 16.4 - Apply PBR materials with accurate albedo and roughness values
extends Node
class_name PBRMaterialFactory

## Emitted when a material is created
signal material_created(material_name: String, material: StandardMaterial3D)

## Cache of created materials for reuse
var _material_cache: Dictionary = {}

## Default material settings
const DEFAULT_ROUGHNESS := 0.5
const DEFAULT_METALLIC := 0.0
const DEFAULT_SPECULAR := 0.5


## Create a basic PBR material with the given parameters
## Requirements: 16.4 - Apply PBR materials with accurate albedo and roughness
func create_material(
	albedo: Color = Color.WHITE,
	roughness: float = DEFAULT_ROUGHNESS,
	metallic: float = DEFAULT_METALLIC,
	emission: Color = Color.BLACK,
	emission_energy: float = 0.0
) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	
	# Albedo (base color)
	material.albedo_color = albedo
	
	# Roughness (0 = mirror, 1 = completely rough)
	material.roughness = clampf(roughness, 0.0, 1.0)
	
	# Metallic (0 = dielectric, 1 = metal)
	material.metallic = clampf(metallic, 0.0, 1.0)
	
	# Specular (affects non-metallic reflections)
	material.metallic_specular = DEFAULT_SPECULAR
	
	# Emission (for glowing materials)
	if emission != Color.BLACK or emission_energy > 0.0:
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = emission_energy
	
	return material


## Create a named material and cache it for reuse
func create_named_material(
	name: String,
	albedo: Color = Color.WHITE,
	roughness: float = DEFAULT_ROUGHNESS,
	metallic: float = DEFAULT_METALLIC,
	emission: Color = Color.BLACK,
	emission_energy: float = 0.0
) -> StandardMaterial3D:
	# Check cache first
	if _material_cache.has(name):
		return _material_cache[name]
	
	var material := create_material(albedo, roughness, metallic, emission, emission_energy)
	material.resource_name = name
	
	_material_cache[name] = material
	material_created.emit(name, material)
	
	return material


## Get a cached material by name
func get_material(name: String) -> StandardMaterial3D:
	if _material_cache.has(name):
		return _material_cache[name]
	return null


## Check if a material exists in cache
func has_material(name: String) -> bool:
	return _material_cache.has(name)


## Clear the material cache
func clear_cache() -> void:
	_material_cache.clear()


## Create a spacecraft hull material (metallic, slightly rough)
func create_spacecraft_hull_material(
	base_color: Color = Color(0.7, 0.7, 0.75)
) -> StandardMaterial3D:
	return create_named_material(
		"spacecraft_hull",
		base_color,
		0.3,   # Slightly rough
		0.9,   # Highly metallic
		Color.BLACK,
		0.0
	)


## Create a spacecraft glass/canopy material (transparent, smooth)
func create_spacecraft_glass_material(
	tint: Color = Color(0.1, 0.15, 0.2, 0.3)
) -> StandardMaterial3D:
	var material := create_material(
		tint,
		0.0,   # Very smooth (mirror-like)
		0.0,   # Non-metallic
		Color.BLACK,
		0.0
	)
	
	# Enable transparency
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
	
	# Fresnel effect for glass
	material.rim_enabled = true
	material.rim = 0.5
	material.rim_tint = 0.5
	
	_material_cache["spacecraft_glass"] = material
	material_created.emit("spacecraft_glass", material)
	
	return material


## Create a rocky planet surface material
func create_rocky_surface_material(
	base_color: Color = Color(0.4, 0.35, 0.3)
) -> StandardMaterial3D:
	return create_named_material(
		"rocky_surface",
		base_color,
		0.9,   # Very rough
		0.0,   # Non-metallic
		Color.BLACK,
		0.0
	)


## Create an ice surface material
func create_ice_surface_material(
	base_color: Color = Color(0.8, 0.9, 1.0)
) -> StandardMaterial3D:
	var material := create_named_material(
		"ice_surface",
		base_color,
		0.2,   # Smooth but not mirror
		0.0,   # Non-metallic
		Color.BLACK,
		0.0
	)
	
	# Subsurface scattering for ice
	material.subsurf_scatter_enabled = true
	material.subsurf_scatter_strength = 0.3
	
	return material


## Create a gas giant atmosphere material
func create_gas_giant_material(
	base_color: Color = Color(0.8, 0.6, 0.4)
) -> StandardMaterial3D:
	var material := create_named_material(
		"gas_giant",
		base_color,
		1.0,   # Completely rough (no specular)
		0.0,   # Non-metallic
		Color.BLACK,
		0.0
	)
	
	# Disable specular for gas giants
	material.metallic_specular = 0.0
	
	return material


## Create a star/sun material (emissive)
func create_star_material(
	star_color: Color = Color(1.0, 0.95, 0.8),
	emission_strength: float = 10.0
) -> StandardMaterial3D:
	var material := create_material(
		Color.BLACK,  # Albedo doesn't matter for emissive
		1.0,          # Rough
		0.0,          # Non-metallic
		star_color,
		emission_strength
	)
	
	# Disable shadows for stars
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	_material_cache["star_" + str(star_color.to_html())] = material
	material_created.emit("star", material)
	
	return material


## Create a lattice grid material (emissive, transparent)
func create_lattice_material(
	grid_color: Color = Color(0.0, 1.0, 1.0),  # Cyan
	emission_strength: float = 2.0
) -> StandardMaterial3D:
	var material := create_material(
		Color.BLACK,
		1.0,
		0.0,
		grid_color,
		emission_strength
	)
	
	# Unshaded for consistent glow
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	# Enable transparency for grid lines
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	
	_material_cache["lattice"] = material
	material_created.emit("lattice", material)
	
	return material


## Create a cockpit interior material (dark, slightly metallic)
func create_cockpit_interior_material(
	base_color: Color = Color(0.1, 0.1, 0.12)
) -> StandardMaterial3D:
	return create_named_material(
		"cockpit_interior",
		base_color,
		0.6,   # Moderately rough
		0.3,   # Slightly metallic
		Color.BLACK,
		0.0
	)


## Create a cockpit display material (emissive screen)
func create_cockpit_display_material(
	display_color: Color = Color(0.0, 0.8, 1.0),
	brightness: float = 3.0
) -> StandardMaterial3D:
	var material := create_material(
		Color.BLACK,
		1.0,
		0.0,
		display_color,
		brightness
	)
	
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	_material_cache["cockpit_display"] = material
	material_created.emit("cockpit_display", material)
	
	return material


## Create a material with a texture
func create_textured_material(
	albedo_texture: Texture2D,
	roughness: float = DEFAULT_ROUGHNESS,
	metallic: float = DEFAULT_METALLIC,
	normal_texture: Texture2D = null,
	roughness_texture: Texture2D = null
) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	
	# Albedo texture
	material.albedo_texture = albedo_texture
	
	# Roughness
	material.roughness = roughness
	if roughness_texture != null:
		material.roughness_texture = roughness_texture
	
	# Metallic
	material.metallic = metallic
	
	# Normal map
	if normal_texture != null:
		material.normal_enabled = true
		material.normal_texture = normal_texture
	
	return material


## Create a material for asteroid/debris
func create_asteroid_material(
	base_color: Color = Color(0.3, 0.28, 0.25)
) -> StandardMaterial3D:
	return create_named_material(
		"asteroid",
		base_color,
		0.95,  # Very rough
		0.1,   # Slightly metallic (iron content)
		Color.BLACK,
		0.0
	)


## Create a material for engine exhaust/thrust
func create_engine_exhaust_material(
	exhaust_color: Color = Color(0.3, 0.5, 1.0),
	intensity: float = 5.0
) -> StandardMaterial3D:
	var material := create_material(
		Color.BLACK,
		1.0,
		0.0,
		exhaust_color,
		intensity
	)
	
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	
	_material_cache["engine_exhaust"] = material
	material_created.emit("engine_exhaust", material)
	
	return material


## Get all cached material names
func get_cached_material_names() -> Array[String]:
	var names: Array[String] = []
	for key in _material_cache.keys():
		names.append(key)
	return names


## Duplicate a material (for per-instance modifications)
func duplicate_material(source: StandardMaterial3D) -> StandardMaterial3D:
	return source.duplicate() as StandardMaterial3D
