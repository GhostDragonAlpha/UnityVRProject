extends RefCounted
class_name HttpApiSecurityConfigEnhanced

## VULN-004 FIX: Enhanced whitelist validation helper functions
## These functions extend HttpApiSecurityConfig with advanced validation

## Check if path matches wildcard pattern
## Supports ** for recursive directory matching and * for single segment
static func matches_wildcard(path: String, pattern: String) -> bool:
	var regex_pattern = pattern

	# Escape special regex characters except * and /
	regex_pattern = regex_pattern.replace(".", "\\.")
	regex_pattern = regex_pattern.replace("+", "\\+")
	regex_pattern = regex_pattern.replace("?", "\\?")
	regex_pattern = regex_pattern.replace("(", "\\(")
	regex_pattern = regex_pattern.replace(")", "\\)")
	regex_pattern = regex_pattern.replace("[", "\\[")
	regex_pattern = regex_pattern.replace("]", "\\]")
	regex_pattern = regex_pattern.replace("{", "\\{")
	regex_pattern = regex_pattern.replace("}", "\\}") 
	regex_pattern = regex_pattern.replace("^", "\\^")
	regex_pattern = regex_pattern.replace("$", "\\$")

	# Replace ** with regex for zero or more path segments
	regex_pattern = regex_pattern.replace("**/", "(?:.*/)?") 
	regex_pattern = regex_pattern.replace("/**", "(?:/.*)?") 

	# Replace * for single segment (no /)
	regex_pattern = regex_pattern.replace("*", "[^/]*")

	# Anchor to start and end
	regex_pattern = "^" + regex_pattern + "$"

	var regex = RegEx.new()
	regex.compile(regex_pattern)

	return regex.search(path) != null


## Canonicalize path (resolve .., remove duplicate slashes)
static func canonicalize_path(path: String) -> String:
	# Split into segments
	var segments = path.split("/")
	var canonical = []

	for segment in segments:
		if segment == "" or segment == ".":
			continue
		elif segment == "..":
			# Remove last segment (go up)
			if canonical.size() > 0:
				canonical.pop_back()
		else:
			canonical.append(segment)

	# Reconstruct path
	var result = "/".join(canonical)

	# Preserve res:// prefix
	if path.begins_with("res://"):
		result = "res://" + result

	return result


## Load whitelist configuration from JSON file
static func load_whitelist_from_json(config_path: String) -> Dictionary:
	var result = {
		"success": false,
		"exact_scenes": [],
		"directories": [],
		"wildcards": [],
		"blacklist_patterns": [],
		"blacklist_exact": [],
		"error": ""
	}

	# Check if config file exists
	if not FileAccess.file_exists(config_path):
		result.error = "Config file not found: " + config_path
		return result

	# Load and parse JSON
	var file = FileAccess.open(config_path, FileAccess.READ)
	if not file:
		result.error = "Failed to open config file"
		return result

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_text)
	if parse_result != OK:
		result.error = "Failed to parse JSON: " + json.get_error_message()
		return result

	var config = json.get_data()
	result.success = true

	return result
