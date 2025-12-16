## Simple File-Based Audit Logger
##
## Lightweight audit logging system that avoids circular dependencies
## by not extending Node or using class_name. Uses only FileAccess for
## direct file I/O operations.
##
## Writes to: user://http_api_audit.log
## Rotation: When file exceeds 10MB, rotates to .1, .2, .3, .4, .5
## Format: [timestamp] [level] [client_ip] [endpoint] [result] details

## Configuration constants
const LOG_FILE_PATH = "user://http_api_audit.log"
const MAX_LOG_SIZE = 10485760  # 10MB
const MAX_ROTATED_LOGS = 5

## Runtime state (static to avoid instance creation)
static var _initialized: bool = false
static var _log_enabled: bool = true

## Initialize the audit logger (call once at startup)
static func initialize() -> void:
	if _initialized:
		return

	_initialized = true
	_log_enabled = true

	# Ensure log directory exists (user:// always exists, but check anyway)
	var log_dir = LOG_FILE_PATH.get_base_dir()
	if not DirAccess.dir_exists_absolute(log_dir):
		var dir = DirAccess.open("user://")
		if dir:
			dir.make_dir_recursive(log_dir)

	# Log initialization
	log_info("SYSTEM", "/", "STARTUP", "Simple audit logging initialized")
	print("[SimpleAuditLogger] Audit logging initialized - writing to: ", LOG_FILE_PATH)


## Write a log entry with specified level
static func _write_log(level: String, client_ip: String, endpoint: String, result: String, details: String) -> void:
	if not _log_enabled:
		return

	# Check if rotation is needed before opening file
	_check_and_rotate_if_needed()

	# Format timestamp
	var time_dict = Time.get_datetime_dict_from_system()
	var timestamp = "%04d-%02d-%02d %02d:%02d:%02d" % [
		time_dict.year, time_dict.month, time_dict.day,
		time_dict.hour, time_dict.minute, time_dict.second
	]

	# Format log entry
	var log_entry = "[%s] [%s] [%s] [%s] [%s] %s\n" % [
		timestamp, level, client_ip, endpoint, result, details
	]

	# Append to log file (create if doesn't exist)
	var mode = FileAccess.READ_WRITE if FileAccess.file_exists(LOG_FILE_PATH) else FileAccess.WRITE
	var file = FileAccess.open(LOG_FILE_PATH, mode)
	if file:
		if mode == FileAccess.READ_WRITE:
			file.seek_end()
		file.store_string(log_entry)
		file.close()
	else:
		push_error("[SimpleAuditLogger] Failed to open log file: %s (Error: %s)" % [LOG_FILE_PATH, FileAccess.get_open_error()])


## Check file size and rotate logs if needed
static func _check_and_rotate_if_needed() -> void:
	if not FileAccess.file_exists(LOG_FILE_PATH):
		return

	# Check current file size
	var file = FileAccess.open(LOG_FILE_PATH, FileAccess.READ)
	if not file:
		return

	var current_size = file.get_length()
	file.close()

	# Rotate if exceeds max size
	if current_size >= MAX_LOG_SIZE:
		_rotate_logs()


## Rotate log files (*.log -> *.log.1 -> *.log.2 -> ... -> *.log.5)
static func _rotate_logs() -> void:
	print("[SimpleAuditLogger] Rotating logs (current size exceeds %d bytes)" % MAX_LOG_SIZE)

	# Remove oldest log if it exists
	var oldest_log = LOG_FILE_PATH + "." + str(MAX_ROTATED_LOGS)
	if FileAccess.file_exists(oldest_log):
		DirAccess.remove_absolute(oldest_log)

	# Shift all rotated logs (*.4 -> *.5, *.3 -> *.4, etc.)
	for i in range(MAX_ROTATED_LOGS - 1, 0, -1):
		var from_file = LOG_FILE_PATH + "." + str(i)
		var to_file = LOG_FILE_PATH + "." + str(i + 1)
		if FileAccess.file_exists(from_file):
			DirAccess.rename_absolute(from_file, to_file)

	# Move current log to *.1
	if FileAccess.file_exists(LOG_FILE_PATH):
		DirAccess.rename_absolute(LOG_FILE_PATH, LOG_FILE_PATH + ".1")

	print("[SimpleAuditLogger] Log rotation complete")


## Public logging functions

static func log_auth_attempt(client_ip: String, endpoint: String, success: bool, reason: String = "") -> void:
	var result = "AUTH_SUCCESS" if success else "AUTH_FAILURE"
	var details = reason if not reason.is_empty() else ("Valid token" if success else "Invalid or missing token")
	_write_log("INFO" if success else "WARN", client_ip, endpoint, result, details)


static func log_rate_limit(client_ip: String, endpoint: String, limit: int, retry_after: float) -> void:
	var details = "Rate limit exceeded: %d req/min, retry after %.2fs" % [limit, retry_after]
	_write_log("WARN", client_ip, endpoint, "RATE_LIMIT", details)


static func log_whitelist_violation(client_ip: String, endpoint: String, scene_path: String, reason: String) -> void:
	var details = "Whitelist violation: %s (%s)" % [scene_path, reason]
	_write_log("WARN", client_ip, endpoint, "WHITELIST_VIOLATION", details)


static func log_size_violation(client_ip: String, endpoint: String, size: int, max_size: int) -> void:
	var details = "Request size violation: %d bytes (max: %d)" % [size, max_size]
	_write_log("WARN", client_ip, endpoint, "SIZE_VIOLATION", details)


static func log_scene_operation(client_ip: String, operation: String, scene_path: String, success: bool, details: String = "") -> void:
	var result = "SUCCESS" if success else "FAILURE"
	var log_details = "%s: %s" % [operation, scene_path]
	if not details.is_empty():
		log_details += " - " + details
	_write_log("INFO", client_ip, "/scene", result, log_details)


static func log_info(client_ip: String, endpoint: String, result: String, details: String) -> void:
	_write_log("INFO", client_ip, endpoint, result, details)


static func log_warn(client_ip: String, endpoint: String, result: String, details: String) -> void:
	_write_log("WARN", client_ip, endpoint, result, details)


static func log_error(client_ip: String, endpoint: String, result: String, details: String) -> void:
	_write_log("ERROR", client_ip, endpoint, result, details)


## Enable/disable logging

static func enable() -> void:
	_log_enabled = true
	print("[SimpleAuditLogger] Audit logging enabled")


static func disable() -> void:
	_log_enabled = false
	print("[SimpleAuditLogger] Audit logging disabled")


## Get log file path for external access

static func get_log_path() -> String:
	return LOG_FILE_PATH


## Shutdown (flush and cleanup)

static func shutdown() -> void:
	if _initialized:
		log_info("SYSTEM", "/", "SHUTDOWN", "Audit logging shutting down")
		_initialized = false
		print("[SimpleAuditLogger] Audit logging shut down")
