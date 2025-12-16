## AudioPaths - Centralized Audio File Path Constants
##
## This file provides a single source of truth for all audio file paths
## used in the moon landing experience. Import this to access audio paths
## consistently across the codebase.

class_name AudioPaths
extends RefCounted

## Spacecraft audio files
const SPACECRAFT = {
	"engine_thrust_loop": "res://audio/sfx/spacecraft/engine_thrust_loop.ogg",
	"rcs_thruster_burst": "res://audio/sfx/spacecraft/rcs_thruster_burst.ogg",
	"cockpit_ambience_loop": "res://audio/sfx/spacecraft/cockpit_ambience_loop.ogg",
	"landing_gear_deploy": "res://audio/sfx/spacecraft/landing_gear_deploy.ogg",
}

## Landing audio files
const LANDING = {
	"impact_soft": "res://audio/sfx/landing/landing_impact_soft.ogg",
	"impact_medium": "res://audio/sfx/landing/landing_impact_medium.ogg",
	"impact_hard": "res://audio/sfx/landing/landing_impact_hard.ogg",
	"dust_settling": "res://audio/sfx/landing/dust_settling.ogg",
}

## Moon walking audio files
const WALKING = {
	"footstep_01": "res://audio/sfx/walking/footstep_moon_01.ogg",
	"footstep_02": "res://audio/sfx/walking/footstep_moon_02.ogg",
	"footstep_03": "res://audio/sfx/walking/footstep_moon_03.ogg",
	"jetpack_thrust_loop": "res://audio/sfx/walking/jetpack_thrust_loop.ogg",
	"jetpack_ignition": "res://audio/sfx/walking/jetpack_ignition.ogg",
	"jetpack_shutdown": "res://audio/sfx/walking/jetpack_shutdown.ogg",
	"landing_thud": "res://audio/sfx/walking/landing_thud.ogg",
	"breathing_loop": "res://audio/sfx/walking/breathing_loop.ogg",
}

## UI audio files
const UI = {
	"objective_complete": "res://audio/sfx/ui/objective_complete.ogg",
	"warning_beep": "res://audio/sfx/ui/warning_beep.ogg",
	"notification": "res://audio/sfx/ui/notification.ogg",
	"success_chime": "res://audio/sfx/ui/success_chime.ogg",
}

## Get all audio paths as a flat dictionary
static func get_all_paths() -> Dictionary:
	var all_paths: Dictionary = {}

	for key in SPACECRAFT:
		all_paths["spacecraft_" + key] = SPACECRAFT[key]

	for key in LANDING:
		all_paths["landing_" + key] = LANDING[key]

	for key in WALKING:
		all_paths["walking_" + key] = WALKING[key]

	for key in UI:
		all_paths["ui_" + key] = UI[key]

	return all_paths

## Check which audio files exist
static func get_existing_files() -> Array[String]:
	var existing: Array[String] = []
	var all_paths = get_all_paths()

	for key in all_paths:
		var path = all_paths[key]
		if ResourceLoader.exists(path):
			existing.append(path)

	return existing

## Check which audio files are missing
static func get_missing_files() -> Array[String]:
	var missing: Array[String] = []
	var all_paths = get_all_paths()

	for key in all_paths:
		var path = all_paths[key]
		if not ResourceLoader.exists(path):
			missing.append(path)

	return missing

## Print audio file status to console
static func print_status() -> void:
	var all_paths = get_all_paths()
	var existing = get_existing_files()
	var missing = get_missing_files()

	print("========================================")
	print("MOON LANDING AUDIO FILE STATUS")
	print("========================================")
	print("Total files: %d" % all_paths.size())
	print("Existing: %d" % existing.size())
	print("Missing: %d" % missing.size())
	print("========================================")

	if missing.size() > 0:
		print("Missing audio files:")
		for path in missing:
			print("  - ", path)
		print("========================================")
		print("See audio/AUDIO_FILES_NEEDED.txt for details")
	else:
		print("All audio files present!")

	print("========================================")
