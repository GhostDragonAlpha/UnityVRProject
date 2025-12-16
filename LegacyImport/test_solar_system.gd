extends Node

## Test script for solar system initialization

func _ready() -> void:
	print("=== Solar System Test Starting ===")

	# Test 1: Verify data files exist
	print("\n[Test 1] Checking ephemeris data files...")
	var solar_system_path = "res://data/ephemeris/solar_system.json"
	if FileAccess.file_exists(solar_system_path):
		print("  ✓ solar_system.json found")
	else:
		print("  ✗ solar_system.json NOT FOUND at: " + solar_system_path)
		return

	# Test 2: Create and initialize SolarSystemInitializer
	print("\n[Test 2] Creating SolarSystemInitializer...")
	var solar_system = SolarSystemInitializer.new()
	add_child(solar_system)
	print("  ✓ SolarSystemInitializer created")

	# Test 3: Initialize the solar system
	print("\n[Test 3] Initializing solar system...")
	var success = solar_system.initialize()
	if success:
		print("  ✓ Solar system initialized successfully")
	else:
		print("  ✗ Solar system initialization FAILED")
		return

	# Test 4: Verify bodies were created
	print("\n[Test 4] Checking celestial bodies...")
	var sun = solar_system.get_sun()
	if sun:
		print("  ✓ Sun created: " + sun.body_name)
		print("    - Mass: " + str(sun.mass))
		print("    - Radius: " + str(sun.radius))
	else:
		print("  ✗ Sun NOT created")

	var planets = solar_system.get_planets()
	print("  ✓ Planets created: " + str(planets.size()))
	for planet in planets:
		print("    - " + planet.body_name + " (rotation period: " + str(planet.rotation_period) + "s)")

	var moons = solar_system.get_moons()
	print("  ✓ Moons created: " + str(moons.size()))

	# Test 5: Create DayNightCycle for Earth
	print("\n[Test 5] Testing day/night cycle...")
	var earth = solar_system.get_body("earth")
	var day_night: DayNightCycle = null
	if earth and sun:
		print("  ✓ Earth found")

		# Create directional light for sun
		var sun_light = DirectionalLight3D.new()
		add_child(sun_light)

		# Create day/night cycle
		day_night = DayNightCycle.new()
		day_night.sun_light = sun_light
		day_night.planet = earth
		day_night.star = sun
		add_child(day_night)

		print("  ✓ Day/Night cycle created")
		print("    - Current rotation: " + str(earth.get_current_rotation()))
		print("    - Rotation axis: " + str(earth.get_rotation_axis()))

		# Wait a frame and check rotation
		await get_tree().process_frame
		await get_tree().process_frame

		print("    - Time of day: " + day_night.get_time_string())
		print("    - Day phase: " + day_night.get_day_phase())
		print("    - Sun elevation: " + str(day_night.get_sun_elevation()))
	else:
		print("  ✗ Earth or Sun not found")

	print("\n=== Solar System Test Complete ===")

	# Keep running for a few seconds to see rotation
	await get_tree().create_timer(3.0).timeout

	if earth:
		print("\n[After 3 seconds]")
		print("  - Earth rotation: " + str(earth.get_current_rotation()))
		if day_night:
			print("  - Time of day: " + day_night.get_time_string())

	print("\nTest finished. Exiting...")
	get_tree().quit()
