extends SceneTree
## Generate missing audio files for moon_landing.tscn
## Run with: godot --headless --script scripts/tools/generate_moon_landing_audio.gd

const ProceduralAudioGenerator = preload("res://scripts/audio/procedural_audio_generator.gd")

func _init() -> void:
	print("================================================================================")
	print("Moon Landing Audio Generator")
	print("================================================================================")

	var generator = ProceduralAudioGenerator.new()
	var files_generated = 0
	var files_failed = 0

	# Ensure audio directories exist
	print("\n[1/7] Creating audio directories...")
	DirAccess.make_dir_recursive_absolute("res://data/audio/cockpit")
	DirAccess.make_dir_recursive_absolute("res://data/audio/jetpack")
	DirAccess.make_dir_recursive_absolute("res://data/audio/impact")
	DirAccess.make_dir_recursive_absolute("res://data/audio/landing")
	DirAccess.make_dir_recursive_absolute("res://data/audio/notifications")
	DirAccess.make_dir_recursive_absolute("res://data/audio/breathing")
	print("  ✓ Directories created")

	# Generate cockpit_ambience_loop.ogg (looping low hum)
	print("\n[2/7] Generating cockpit_ambience_loop.tres...")
	var cockpit_ambience = generator.generate_looping_sine_tone(80.0, 10.0, 0.15)
	if generator.save_to_file(cockpit_ambience, "res://data/audio/cockpit/cockpit_ambience_loop.tres") == OK:
		print("  ✓ Saved: data/audio/cockpit/cockpit_ambience_loop.tres")
		files_generated += 1
	else:
		print("  ✗ FAILED: cockpit_ambience_loop.tres")
		files_failed += 1

	# Generate rcs_thruster_burst.ogg (short burst)
	print("\n[3/7] Generating rcs_thruster_burst.tres...")
	var rcs_burst = generator.generate_white_noise(0.15, 0.4)
	if generator.save_to_file(rcs_burst, "res://data/audio/jetpack/rcs_thruster_burst.tres") == OK:
		print("  ✓ Saved: data/audio/jetpack/rcs_thruster_burst.tres")
		files_generated += 1
	else:
		print("  ✗ FAILED: rcs_thruster_burst.tres")
		files_failed += 1

	# Generate landing_gear_deploy.ogg (mechanical sound)
	print("\n[4/7] Generating landing_gear_deploy.tres...")
	var landing_gear = generator.generate_sweep(200.0, 100.0, 1.5, 0.5)
	if generator.save_to_file(landing_gear, "res://data/audio/landing/landing_gear_deploy.tres") == OK:
		print("  ✓ Saved: data/audio/landing/landing_gear_deploy.tres")
		files_generated += 1
	else:
		print("  ✗ FAILED: landing_gear_deploy.tres")
		files_failed += 1

	# Generate objective_complete.ogg (success chirp)
	print("\n[5/7] Generating objective_complete.tres...")
	var objective_complete = generator.generate_sweep(600.0, 1200.0, 0.5, 0.6)
	if generator.save_to_file(objective_complete, "res://data/audio/notifications/objective_complete.tres") == OK:
		print("  ✓ Saved: data/audio/notifications/objective_complete.tres")
		files_generated += 1
	else:
		print("  ✗ FAILED: objective_complete.tres")
		files_failed += 1

	# Generate notification.ogg (simple beep)
	print("\n[6/7] Generating notification.tres...")
	var notification = generator.generate_beep(1000.0, 0.3, 0.5)
	if generator.save_to_file(notification, "res://data/audio/notifications/notification.tres") == OK:
		print("  ✓ Saved: data/audio/notifications/notification.tres")
		files_generated += 1
	else:
		print("  ✗ FAILED: notification.tres")
		files_failed += 1

	# Generate breathing_loop.ogg (rhythmic low frequency)
	print("\n[7/7] Generating breathing_loop.tres...")
	# Create breathing rhythm: 4 seconds (2s inhale, 2s exhale)
	var breathing = generator.generate_looping_sine_tone(0.25, 4.0, 0.1)
	if generator.save_to_file(breathing, "res://data/audio/breathing/breathing_loop.tres") == OK:
		print("  ✓ Saved: data/audio/breathing/breathing_loop.tres")
		files_generated += 1
	else:
		print("  ✗ FAILED: breathing_loop.tres")
		files_failed += 1

	print("\n================================================================================")
	print("Generation Summary")
	print("================================================================================")
	print("Files generated: " + str(files_generated) + " / 6")
	print("Files failed: " + str(files_failed) + " / 6")

	if files_generated == 6:
		print("\n✓ SUCCESS: All 6 procedural audio files generated!")
		print("\nNext Steps:")
		print("1. Convert .tres files to .ogg using Godot editor import system")
		print("2. Update MoonAudioManager references to use new files")
		print("3. Download remaining 6 audio files from freesound.org:")
		print("   - jetpack_ignition.ogg")
		print("   - jetpack_shutdown.ogg")
		print("   - impact_soft.ogg")
		print("   - impact_hard.ogg")
		print("   - walking_dust.ogg")
		print("   - surface_scrape.ogg")
	else:
		print("\n✗ WARNING: Some files failed to generate")
		print("Check error messages above for details")

	print("\n================================================================================")

	# Exit
	quit()
