class_name AstroPos
extends RefCounted

## Astronomical Position - Multi-scale coordinate representation
## Allows objects to exist at planetary (meters), system (AU), and galactic (light-years) scales
##
## This class represents a position in the universe using three coordinate systems:
## - Local space (meters): For nearby objects and physics simulation
## - System space (AU): For planetary/solar system scale
## - Galactic space (light-years): For interstellar distances
##
## Usage:
##   var pos = AstroPos.new()
##   pos.system_au = Vector3(1.0, 0, 0)  # 1 AU from star
##   pos.authoritative = AstroPos.CoordSystem.SYSTEM
##   var total_meters = pos.get_total_distance_meters()

## Constants for unit conversion
const METERS_PER_AU := 149_597_870_700.0
const METERS_PER_LY := 9.461e15
const AU_PER_LY := 63_241.0

## Coordinates in different scales
var local_meters: Vector3 = Vector3.ZERO    ## Local space position (±5km range)
var system_au: Vector3 = Vector3.ZERO       ## System position in AU
var galactic_ly: Vector3 = Vector3.ZERO     ## Galactic position in light-years

## Which coordinate system is authoritative for this object
enum CoordSystem { LOCAL, SYSTEM, GALACTIC }
var authoritative: CoordSystem = CoordSystem.LOCAL

## Parent object ID for orbital mechanics (optional)
var parent_astro_id: int = -1

## Orbital parameters (optional, for future orbital mechanics)
var orbital_radius_au: float = 0.0
var orbital_period_days: float = 0.0
var orbital_phase: float = 0.0


## Create a deep copy of this AstroPos
func duplicate() -> AstroPos:
	var copy = AstroPos.new()
	copy.local_meters = local_meters
	copy.system_au = system_au
	copy.galactic_ly = galactic_ly
	copy.authoritative = authoritative
	copy.parent_astro_id = parent_astro_id
	copy.orbital_radius_au = orbital_radius_au
	copy.orbital_period_days = orbital_period_days
	copy.orbital_phase = orbital_phase
	return copy


## Serialize to dictionary for saving/networking
func to_dict() -> Dictionary:
	return {
		"local_meters": {
			"x": local_meters.x,
			"y": local_meters.y,
			"z": local_meters.z
		},
		"system_au": {
			"x": system_au.x,
			"y": system_au.y,
			"z": system_au.z
		},
		"galactic_ly": {
			"x": galactic_ly.x,
			"y": galactic_ly.y,
			"z": galactic_ly.z
		},
		"authoritative": authoritative,
		"parent_astro_id": parent_astro_id,
		"orbital_radius_au": orbital_radius_au,
		"orbital_period_days": orbital_period_days,
		"orbital_phase": orbital_phase
	}


## Deserialize from dictionary
func from_dict(data: Dictionary) -> void:
	if data.has("local_meters"):
		var lm = data["local_meters"]
		local_meters = Vector3(lm.get("x", 0.0), lm.get("y", 0.0), lm.get("z", 0.0))

	if data.has("system_au"):
		var sa = data["system_au"]
		system_au = Vector3(sa.get("x", 0.0), sa.get("y", 0.0), sa.get("z", 0.0))

	if data.has("galactic_ly"):
		var gl = data["galactic_ly"]
		galactic_ly = Vector3(gl.get("x", 0.0), gl.get("y", 0.0), gl.get("z", 0.0))

	if data.has("authoritative"):
		authoritative = data["authoritative"]

	if data.has("parent_astro_id"):
		parent_astro_id = data["parent_astro_id"]

	if data.has("orbital_radius_au"):
		orbital_radius_au = data["orbital_radius_au"]

	if data.has("orbital_period_days"):
		orbital_period_days = data["orbital_period_days"]

	if data.has("orbital_phase"):
		orbital_phase = data["orbital_phase"]


## Calculate total distance from universal origin in meters
## This combines all three coordinate systems into a single meter value
func get_total_distance_meters() -> float:
	# Convert all coordinates to meters
	var local_m = local_meters.length()
	var system_m = system_au.length() * METERS_PER_AU
	var galactic_m = galactic_ly.length() * METERS_PER_LY

	# Return total distance
	return local_m + system_m + galactic_m


## Debug string representation
func _to_string() -> String:
	var auth_str = ""
	match authoritative:
		CoordSystem.LOCAL:
			auth_str = "LOCAL"
		CoordSystem.SYSTEM:
			auth_str = "SYSTEM"
		CoordSystem.GALACTIC:
			auth_str = "GALACTIC"

	var parts = []

	# Show local meters if non-zero
	if local_meters.length_squared() > 0.0:
		parts.append("Local: (%.2fm, %.2fm, %.2fm)" % [local_meters.x, local_meters.y, local_meters.z])

	# Show system AU if non-zero
	if system_au.length_squared() > 0.0:
		parts.append("System: (%.4fAU, %.4fAU, %.4fAU)" % [system_au.x, system_au.y, system_au.z])

	# Show galactic light-years if non-zero
	if galactic_ly.length_squared() > 0.0:
		parts.append("Galactic: (%.4fly, %.4fly, %.4fly)" % [galactic_ly.x, galactic_ly.y, galactic_ly.z])

	# Build final string
	var coord_str = ", ".join(parts) if parts.size() > 0 else "Origin"
	return "AstroPos[%s] {%s}" % [auth_str, coord_str]
