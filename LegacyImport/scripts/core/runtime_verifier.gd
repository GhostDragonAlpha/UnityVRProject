extends Node

## Runtime Verifier - Internal Self-Test System
## Runs registered verification checks on game startup to ensure system integrity.
## Requirements:
## - Allow systems to register validation callbacks
## - Run all checks on _ready()
## - Report failures to console and API

signal verification_completed(results: Dictionary)

var _checks: Array = []
var _results: Dictionary = {
	"passed": [],
	"failed": [],
	"total": 0,
	"timestamp": ""
}
var _is_running: bool = false

func _ready() -> void:
	# Wait for other systems to initialize and register their checks
	await get_tree().process_frame
	await get_tree().process_frame

	run_all_checks()

## Register a verification check
## @param check_callback: A Callable that returns true (pass) or false (fail), or a Dictionary {"success": bool, "message": String}
## @param description: A human-readable description of the check
func register_check(check_callback: Callable, description: String) -> void:
	_checks.append({
		"callback": check_callback,
		"description": description
	})

## Run all registered checks
func run_all_checks() -> void:
	if _is_running:
		return

	_is_running = true
	print("[RuntimeVerifier] Starting self-tests...")

	_results.passed.clear()
	_results.failed.clear()
	_results.total = _checks.size()
	_results.timestamp = Time.get_datetime_string_from_system()

	for check in _checks:
		var callback = check.callback
		var description = check.description
		var result = null

		# Execute the check safely (GDScript doesn't have try/catch)
		result = callback.call()

		# If callback returns null or invalid, treat as error
		if result == null:
			result = {"success": false, "message": "Check returned null"}

		# Parse result
		var success = false
		var message = ""

		if typeof(result) == TYPE_BOOL:
			success = result
		elif typeof(result) == TYPE_DICTIONARY:
			success = result.get("success", false)
			message = result.get("message", "")

		# Record result
		if success:
			_results.passed.append(description)
			# print("[RuntimeVerifier] PASS: ", description)
		else:
			_results.failed.append({
				"description": description,
				"message": message
			})
			push_error("[RuntimeVerifier] FAIL: %s - %s" % [description, message])

	print("[RuntimeVerifier] Completed. Passed: %d, Failed: %d" % [_results.passed.size(), _results.failed.size()])
	_is_running = false
	verification_completed.emit(_results)

## Get the latest results
func get_results() -> Dictionary:
	return _results
