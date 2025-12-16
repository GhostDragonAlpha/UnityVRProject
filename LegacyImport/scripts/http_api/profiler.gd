extends RefCounted
class_name HttpApiProfiler

## Performance Profiler for HTTP API
## Tracks detailed timing for each request phase and generates flame graphs for slow requests
##
## Request phases:
## - Auth validation
## - Scene validation
## - File I/O
## - Response serialization
##
## Exposes /debug/profile endpoint with detailed timing data

# Profile data storage
var request_profiles: Array[Dictionary] = []
const MAX_PROFILES: int = 1000  # Keep last 1000 requests
const SLOW_REQUEST_THRESHOLD_MS: float = 100.0  # Requests >100ms are flagged as slow

# Current request being profiled
var current_request: Dictionary = {}

# Aggregate statistics
var phase_stats: Dictionary = {}

func _init():
	_initialize_stats()

func _initialize_stats():
	"""Initialize statistics tracking"""
	phase_stats = {
		"auth_validation": {"total_ms": 0.0, "count": 0, "max_ms": 0.0, "min_ms": INF},
		"scene_validation": {"total_ms": 0.0, "count": 0, "max_ms": 0.0, "min_ms": INF},
		"file_io": {"total_ms": 0.0, "count": 0, "max_ms": 0.0, "min_ms": INF},
		"response_serialization": {"total_ms": 0.0, "count": 0, "max_ms": 0.0, "min_ms": INF},
		"total": {"total_ms": 0.0, "count": 0, "max_ms": 0.0, "min_ms": INF}
	}

## Start profiling a new request
func start_request(endpoint: String, method: String, request_id: String = "") -> void:
	if request_id.is_empty():
		request_id = "%s_%d" % [endpoint.get_file(), Time.get_ticks_usec()]

	current_request = {
		"request_id": request_id,
		"endpoint": endpoint,
		"method": method,
		"start_time_usec": Time.get_ticks_usec(),
		"phases": [],
		"current_phase": null,
		"metadata": {}
	}

## Start timing a specific phase
func start_phase(phase_name: String) -> void:
	if current_request.is_empty():
		push_warning("[HttpApiProfiler] start_phase called without active request")
		return

	# End previous phase if any
	if current_request.current_phase != null:
		end_phase()

	current_request.current_phase = {
		"name": phase_name,
		"start_time_usec": Time.get_ticks_usec(),
		"end_time_usec": 0,
		"duration_ms": 0.0,
		"details": {}
	}

## End the current phase
func end_phase(details: Dictionary = {}) -> void:
	if current_request.is_empty():
		return

	if current_request.current_phase == null:
		push_warning("[HttpApiProfiler] end_phase called without active phase")
		return

	var phase = current_request.current_phase
	phase.end_time_usec = Time.get_ticks_usec()
	phase.duration_ms = (phase.end_time_usec - phase.start_time_usec) / 1000.0
	phase.details = details

	# Add to phases array
	current_request.phases.append(phase)
	current_request.current_phase = null

	# Update aggregate stats
	_update_phase_stats(phase.name, phase.duration_ms)

## Add metadata to current request
func add_metadata(key: String, value) -> void:
	if not current_request.is_empty():
		current_request.metadata[key] = value

## Complete the current request profile
func end_request(status_code: int, response_size: int = 0) -> Dictionary:
	if current_request.is_empty():
		push_warning("[HttpApiProfiler] end_request called without active request")
		return {}

	# End any active phase
	if current_request.current_phase != null:
		end_phase()

	# Calculate total duration
	var end_time_usec = Time.get_ticks_usec()
	var total_duration_ms = (end_time_usec - current_request.start_time_usec) / 1000.0

	current_request["end_time_usec"] = end_time_usec
	current_request["total_duration_ms"] = total_duration_ms
	current_request["status_code"] = status_code
	current_request["response_size"] = response_size
	current_request["is_slow"] = total_duration_ms >= SLOW_REQUEST_THRESHOLD_MS

	# Update total stats
	_update_phase_stats("total", total_duration_ms)

	# Store profile
	request_profiles.append(current_request.duplicate(true))
	if request_profiles.size() > MAX_PROFILES:
		request_profiles.remove_at(0)

	var completed_request = current_request.duplicate(true)
	current_request = {}

	return completed_request

## Get profile data for the /debug/profile endpoint
func get_profile_data(filters: Dictionary = {}) -> Dictionary:
	var filtered_profiles = _filter_profiles(filters)

	return {
		"timestamp": Time.get_datetime_string_from_system(),
		"total_profiles": request_profiles.size(),
		"filtered_count": filtered_profiles.size(),
		"recent_requests": filtered_profiles.slice(max(0, filtered_profiles.size() - 20), filtered_profiles.size()),
		"slow_requests": _get_slow_requests(),
		"phase_statistics": _get_phase_statistics(),
		"endpoint_summary": _get_endpoint_summary(),
		"filters_applied": filters
	}

## Get detailed profile for a specific request
func get_request_profile(request_id: String) -> Dictionary:
	for profile in request_profiles:
		if profile.request_id == request_id:
			return profile
	return {}

## Generate flame graph data for slow requests
func generate_flame_graph(request_id: String = "") -> Dictionary:
	var profile: Dictionary

	if request_id.is_empty():
		# Get the slowest recent request
		var slow_requests = _get_slow_requests()
		if slow_requests.is_empty():
			return {"error": "No slow requests found"}
		profile = slow_requests[0]
	else:
		profile = get_request_profile(request_id)
		if profile.is_empty():
			return {"error": "Request profile not found"}

	# Build flame graph structure
	var flame_graph = {
		"name": "%s %s" % [profile.method, profile.endpoint],
		"value": profile.total_duration_ms,
		"children": []
	}

	for phase in profile.phases:
		flame_graph.children.append({
			"name": phase.name,
			"value": phase.duration_ms,
			"details": phase.details
		})

	return {
		"request_id": profile.request_id,
		"flame_graph": flame_graph,
		"metadata": profile.metadata,
		"total_duration_ms": profile.total_duration_ms
	}

## Get list of slow requests (>100ms)
func _get_slow_requests() -> Array:
	var slow = []
	for profile in request_profiles:
		if profile.get("is_slow", false):
			slow.append(profile)

	# Sort by duration (slowest first)
	slow.sort_custom(func(a, b): return a.total_duration_ms > b.total_duration_ms)
	return slow.slice(0, min(20, slow.size()))  # Return top 20

## Get phase statistics
func _get_phase_statistics() -> Dictionary:
	var stats = {}
	for phase_name in phase_stats.keys():
		var phase = phase_stats[phase_name]
		if phase.count > 0:
			stats[phase_name] = {
				"avg_ms": phase.total_ms / phase.count,
				"max_ms": phase.max_ms,
				"min_ms": phase.min_ms,
				"count": phase.count,
				"total_ms": phase.total_ms
			}
	return stats

## Get summary by endpoint
func _get_endpoint_summary() -> Dictionary:
	var summary = {}
	for profile in request_profiles:
		var endpoint = profile.endpoint
		if not summary.has(endpoint):
			summary[endpoint] = {
				"count": 0,
				"total_ms": 0.0,
				"max_ms": 0.0,
				"min_ms": INF,
				"slow_count": 0
			}

		var s = summary[endpoint]
		s.count += 1
		s.total_ms += profile.total_duration_ms
		s.max_ms = max(s.max_ms, profile.total_duration_ms)
		s.min_ms = min(s.min_ms, profile.total_duration_ms)
		if profile.get("is_slow", false):
			s.slow_count += 1

	# Calculate averages
	for endpoint in summary.keys():
		var s = summary[endpoint]
		s["avg_ms"] = s.total_ms / s.count

	return summary

## Update aggregate statistics for a phase
func _update_phase_stats(phase_name: String, duration_ms: float) -> void:
	if not phase_stats.has(phase_name):
		phase_stats[phase_name] = {"total_ms": 0.0, "count": 0, "max_ms": 0.0, "min_ms": INF}

	var stats = phase_stats[phase_name]
	stats.total_ms += duration_ms
	stats.count += 1
	stats.max_ms = max(stats.max_ms, duration_ms)
	stats.min_ms = min(stats.min_ms, duration_ms)

## Filter profiles based on criteria
func _filter_profiles(filters: Dictionary) -> Array:
	if filters.is_empty():
		return request_profiles.duplicate()

	var filtered = []
	for profile in request_profiles:
		var matches = true

		# Filter by endpoint
		if filters.has("endpoint") and profile.endpoint != filters.endpoint:
			matches = false

		# Filter by method
		if filters.has("method") and profile.method != filters.method:
			matches = false

		# Filter by slow requests only
		if filters.has("slow_only") and filters.slow_only and not profile.get("is_slow", false):
			matches = false

		# Filter by minimum duration
		if filters.has("min_duration_ms") and profile.total_duration_ms < filters.min_duration_ms:
			matches = false

		# Filter by status code
		if filters.has("status_code") and profile.status_code != filters.status_code:
			matches = false

		if matches:
			filtered.append(profile)

	return filtered

## Clear all stored profiles
func clear_profiles() -> void:
	request_profiles.clear()
	_initialize_stats()

## Get performance summary (for quick checks)
func get_summary() -> Dictionary:
	var total_requests = request_profiles.size()
	var slow_count = 0
	var total_duration = 0.0

	for profile in request_profiles:
		if profile.get("is_slow", false):
			slow_count += 1
		total_duration += profile.total_duration_ms

	return {
		"total_requests": total_requests,
		"slow_requests": slow_count,
		"slow_percentage": (float(slow_count) / total_requests * 100.0) if total_requests > 0 else 0.0,
		"avg_duration_ms": total_duration / total_requests if total_requests > 0 else 0.0,
		"profiles_stored": request_profiles.size(),
		"max_profiles": MAX_PROFILES
	}
