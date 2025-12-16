extends Node

func _ready():
	await get_tree().create_timer(2.0).timeout
	
	# Find solar system initializer
	var solar_system = get_node_or_null("/root/SolarSystemLanding/SolarSystemInitializer")
	if not solar_system:
		print("[TEST] Could not find solar system")
		return
	
	# Find player
	var player = get_node_or_null("/root/SolarSystemLanding/XROrigin3D")
	if not player:
		print("[TEST] Could not find player")
		return
	
	print("[TEST] Player position: %s" % player.global_position)
	
	# Get planets and their positions
	var planets = solar_system.get_planets()
	print("[TEST] Found %d planets" % planets.size())
	
	for planet in planets:
		var distance = player.global_position.distance_to(planet.global_position)
		print("[TEST] %s: position=%s, distance=%.1f, radius=%.1f" % [
			planet.body_name,
			planet.global_position,
			distance,
			planet.radius
		])
	
	# Move player close to first planet for testing
	if planets.size() > 0:
		var first_planet = planets[0]
		var new_pos = first_planet.global_position + Vector3(first_planet.radius * 2, 0, 0)
		player.global_position = new_pos
		print("[TEST] Moved player to %s (near %s)" % [new_pos, first_planet.body_name])
		
		await get_tree().create_timer(3.0).timeout
		
		# Check if terrain was generated
		var terrain = first_planet.get_node_or_null("VoxelTerrain")
		if terrain:
			print("[TEST] SUCCESS! Terrain generated for %s" % first_planet.body_name)
		else:
			print("[TEST] FAIL! No terrain generated for %s" % first_planet.body_name)
	
	get_tree().quit()
