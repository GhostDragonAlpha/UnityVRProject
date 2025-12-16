extends Node
class_name HttpApiAuditLogger

## Audit logging system for HTTP API security events
## Logs authentication, authorization, rate limiting, and scene operations

const LOG_DIR = "logs"
const LOG_FILE = "http_api_audit.log"
const MAX_LOG_SIZE = 10485760  # 10MB
const MAX_LOG_FILES = 5

static var _log_file_handle: FileAccess = null
static var _current_log_size: int = 0
static var _log_enabled: bool = true

## Initialize audit logger
static func initialize() -> void:
	if not DirAccess.dir_exists_absolute("user://" + LOG_DIR):
		DirAccess.make_dir_absolute("user://" + LOG_DIR)
	_open_log_file()
	log_info("SYSTEM", "/", "STARTUP", "Audit logging initialized")

static func _open_log_file() -> void:
	var log_path = "user://" + LOG_DIR + "/" + LOG_FILE
	if FileAccess.file_exists(log_path):
		var existing_size = FileAccess.get_file_as_bytes(log_path).size()
		if existing_size >= MAX_LOG_SIZE:
			_rotate_logs()
	_log_file_handle = FileAccess.open(log_path, FileAccess.WRITE_READ)
	if _log_file_handle:
		_log_file_handle.seek_end()
		_current_log_size = _log_file_handle.get_position()
	else:
		push_error("[AuditLogger] Failed to open log file")

static func _rotate_logs() -> void:
	var log_path = "user://" + LOG_DIR + "/" + LOG_FILE
	if _log_file_handle:
		_log_file_handle.close()
		_log_file_handle = null
	var oldest_log = log_path + "." + str(MAX_LOG_FILES)
	if FileAccess.file_exists(oldest_log):
		DirAccess.remove_absolute(oldest_log)
	for i in range(MAX_LOG_FILES - 1, 0, -1):
		var from_file = log_path + "." + str(i)
		var to_file = log_path + "." + str(i + 1)
		if FileAccess.file_exists(from_file):
			DirAccess.rename_absolute(from_file, to_file)
	if FileAccess.file_exists(log_path):
		DirAccess.rename_absolute(log_path, log_path + ".1")
	_current_log_size = 0

static func _write_log(level: String, client_ip: String, endpoint: String, result: String, details: String) -> void:
	if not _log_enabled:
		return
	var time_dict = Time.get_datetime_dict_from_system()
	var timestamp = "%04d-%02d-%02d %02d:%02d:%02d" % [
		time_dict.year, time_dict.month, time_dict.day,
		time_dict.hour, time_dict.minute, time_dict.second
	]
	var log_entry = "[%s] [%s] [%s] [%s] [%s] %s" + String.chr(10)
	log_entry = log_entry % [timestamp, level, client_ip, endpoint, result, details]
	if _current_log_size + log_entry.length() >= MAX_LOG_SIZE:
		_rotate_logs()
		_open_log_file()
	if _log_file_handle:
		_log_file_handle.store_string(log_entry)
		_log_file_handle.flush()
		_current_log_size += log_entry.length()

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

static func enable() -> void:
	_log_enabled = true

static func disable() -> void:
	_log_enabled = false

static func shutdown() -> void:
	if _log_file_handle:
		log_info("SYSTEM", "/", "SHUTDOWN", "Audit logging shutting down")
		_log_file_handle.close()
		_log_file_handle = null

static func get_log_path() -> String:
	return "user://" + LOG_DIR + "/" + LOG_FILE
