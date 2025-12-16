extends RefCounted
class_name MetricsExporter

## Prometheus Metrics Exporter for HTTP API
## Exposes metrics in Prometheus text format at /metrics endpoint
##
## Tracks:
## - Request counters (by endpoint, status, method)
## - Request duration histograms
## - Request/response size histograms
## - Scene operation metrics
## - Auth/rate limit metrics
## - Active connections gauge

# Metric storage structures
var request_counter: Dictionary = {}  # {endpoint: {status: count}}
var request_duration_buckets: Dictionary = {}  # {endpoint: [bucket_counts]}
var request_size_buckets: Dictionary = {}
var response_size_buckets: Dictionary = {}
var scene_loads: Dictionary = {}  # {scene_path: count}
var scene_errors: Dictionary = {}  # {error_type: count}
var auth_attempts: Dictionary = {}  # {result: count}
var rate_limit_hits: Dictionary = {}  # {endpoint: count}
var active_connections: int = 0

# Histogram bucket boundaries (in seconds for duration, bytes for size)
const DURATION_BUCKETS: Array[float] = [0.005, 0.010, 0.025, 0.050, 0.100, 0.250, 0.500, 1.000, 2.500, 5.000, 10.0]
const SIZE_BUCKETS: Array[int] = [100, 500, 1000, 5000, 10000, 50000, 100000, 500000, 1000000, 5000000]

# Timing summaries for percentile calculation
var request_timings: Array[float] = []
const MAX_TIMING_SAMPLES: int = 10000

func _init():
	_initialize_metrics()

func _initialize_metrics():
	"""Initialize metric storage structures"""
	request_counter = {}
	request_duration_buckets = {}
	request_size_buckets = {}
	response_size_buckets = {}
	scene_loads = {}
	scene_errors = {}
	auth_attempts = {
		"success": 0,
		"invalid_token": 0,
		"missing_token": 0,
		"expired_token": 0
	}
	rate_limit_hits = {}
	active_connections = 0
	request_timings = []

## Record an HTTP request
func record_request(endpoint: String, method: String, status_code: int, duration_ms: float,
					request_size: int, response_size: int) -> void:
	# Normalize endpoint (remove query params)
	var normalized_endpoint = endpoint.split("?")[0]

	# Counter: http_requests_total
	var counter_key = "%s:%s:%d" % [normalized_endpoint, method, status_code]
	if not request_counter.has(counter_key):
		request_counter[counter_key] = 0
	request_counter[counter_key] += 1

	# Histogram: http_request_duration_seconds
	_record_histogram(request_duration_buckets, normalized_endpoint, duration_ms / 1000.0, DURATION_BUCKETS)

	# Histogram: http_request_size_bytes
	_record_histogram(request_size_buckets, normalized_endpoint, float(request_size), SIZE_BUCKETS)

	# Histogram: http_response_size_bytes
	_record_histogram(response_size_buckets, normalized_endpoint, float(response_size), SIZE_BUCKETS)

	# Store timing for percentile calculation
	request_timings.append(duration_ms)
	if request_timings.size() > MAX_TIMING_SAMPLES:
		request_timings.remove_at(0)  # Remove oldest

## Record a scene load operation
func record_scene_load(scene_path: String, success: bool, error_type: String = "") -> void:
	if success:
		# Counter: scene_loads_total
		if not scene_loads.has(scene_path):
			scene_loads[scene_path] = 0
		scene_loads[scene_path] += 1
	else:
		# Counter: scene_load_errors_total
		if not scene_errors.has(error_type):
			scene_errors[error_type] = 0
		scene_errors[error_type] += 1

## Record an auth attempt
func record_auth_attempt(result: String) -> void:
	# Counter: auth_attempts_total
	if not auth_attempts.has(result):
		auth_attempts[result] = 0
	auth_attempts[result] += 1

## Record a rate limit hit
func record_rate_limit_hit(endpoint: String) -> void:
	# Counter: rate_limit_hits_total
	var normalized_endpoint = endpoint.split("?")[0]
	if not rate_limit_hits.has(normalized_endpoint):
		rate_limit_hits[normalized_endpoint] = 0
	rate_limit_hits[normalized_endpoint] += 1

## Update active connections count
func set_active_connections(count: int) -> void:
	active_connections = count

## Generate Prometheus-formatted metrics output
func export_metrics() -> String:
	var output: String = ""

	# Add header
	output += "# Godot HTTP API Metrics\n"
	output += "# Generated: %s\n\n" % Time.get_datetime_string_from_system()

	# http_requests_total
	output += "# HELP http_requests_total Total HTTP requests by endpoint, method, and status\n"
	output += "# TYPE http_requests_total counter\n"
	for key in request_counter.keys():
		var parts = key.split(":")
		var endpoint = parts[0]
		var method = parts[1]
		var status = parts[2]
		output += 'http_requests_total{endpoint="%s",method="%s",status="%s"} %d\n' % [
			_escape_label(endpoint), method, status, request_counter[key]
		]
	output += "\n"

	# http_request_duration_seconds
	output += "# HELP http_request_duration_seconds HTTP request duration in seconds\n"
	output += "# TYPE http_request_duration_seconds histogram\n"
	for endpoint in request_duration_buckets.keys():
		output += _format_histogram("http_request_duration_seconds", endpoint,
									 request_duration_buckets[endpoint], DURATION_BUCKETS)
	output += "\n"

	# http_request_size_bytes
	output += "# HELP http_request_size_bytes HTTP request size in bytes\n"
	output += "# TYPE http_request_size_bytes histogram\n"
	for endpoint in request_size_buckets.keys():
		output += _format_histogram("http_request_size_bytes", endpoint,
									 request_size_buckets[endpoint], SIZE_BUCKETS)
	output += "\n"

	# http_response_size_bytes
	output += "# HELP http_response_size_bytes HTTP response size in bytes\n"
	output += "# TYPE http_response_size_bytes histogram\n"
	for endpoint in response_size_buckets.keys():
		output += _format_histogram("http_response_size_bytes", endpoint,
									 response_size_buckets[endpoint], SIZE_BUCKETS)
	output += "\n"

	# scene_loads_total
	output += "# HELP scene_loads_total Total scene loads by scene path\n"
	output += "# TYPE scene_loads_total counter\n"
	for scene_path in scene_loads.keys():
		output += 'scene_loads_total{scene="%s"} %d\n' % [_escape_label(scene_path), scene_loads[scene_path]]
	output += "\n"

	# scene_load_errors_total
	output += "# HELP scene_load_errors_total Total scene load errors by error type\n"
	output += "# TYPE scene_load_errors_total counter\n"
	for error_type in scene_errors.keys():
		output += 'scene_load_errors_total{error_type="%s"} %d\n' % [_escape_label(error_type), scene_errors[error_type]]
	output += "\n"

	# auth_attempts_total
	output += "# HELP auth_attempts_total Total authentication attempts by result\n"
	output += "# TYPE auth_attempts_total counter\n"
	for result in auth_attempts.keys():
		output += 'auth_attempts_total{result="%s"} %d\n' % [result, auth_attempts[result]]
	output += "\n"

	# rate_limit_hits_total
	output += "# HELP rate_limit_hits_total Total rate limit hits by endpoint\n"
	output += "# TYPE rate_limit_hits_total counter\n"
	for endpoint in rate_limit_hits.keys():
		output += 'rate_limit_hits_total{endpoint="%s"} %d\n' % [_escape_label(endpoint), rate_limit_hits[endpoint]]
	output += "\n"

	# active_connections
	output += "# HELP active_connections Current number of active HTTP connections\n"
	output += "# TYPE active_connections gauge\n"
	output += "active_connections %d\n" % active_connections
	output += "\n"

	# Request latency percentiles (calculated from stored timings)
	if request_timings.size() > 0:
		var sorted_timings = request_timings.duplicate()
		sorted_timings.sort()

		output += "# HELP http_request_latency_ms Request latency percentiles in milliseconds\n"
		output += "# TYPE http_request_latency_ms gauge\n"
		output += 'http_request_latency_ms{quantile="0.50"} %.3f\n' % _percentile(sorted_timings, 0.50)
		output += 'http_request_latency_ms{quantile="0.90"} %.3f\n' % _percentile(sorted_timings, 0.90)
		output += 'http_request_latency_ms{quantile="0.95"} %.3f\n' % _percentile(sorted_timings, 0.95)
		output += 'http_request_latency_ms{quantile="0.99"} %.3f\n' % _percentile(sorted_timings, 0.99)
		output += "\n"

	return output

## Record value in histogram buckets
func _record_histogram(buckets_dict: Dictionary, key: String, value: float, bucket_boundaries: Array) -> void:
	if not buckets_dict.has(key):
		# Initialize buckets: [count_per_bucket, sum, total_count]
		var bucket_counts = []
		for i in range(bucket_boundaries.size() + 1):
			bucket_counts.append(0)
		buckets_dict[key] = {
			"buckets": bucket_counts,
			"sum": 0.0,
			"count": 0
		}

	var data = buckets_dict[key]
	data["sum"] += value
	data["count"] += 1

	# Increment appropriate bucket
	var bucket_idx = 0
	var placed_in_bucket = false
	for boundary in bucket_boundaries:
		if value <= boundary:
			data["buckets"][bucket_idx] += 1
			placed_in_bucket = true
			break
		else:
			bucket_idx += 1

	# If value exceeds all buckets, goes in +Inf bucket
	if not placed_in_bucket:
		data["buckets"][bucket_boundaries.size()] += 1

## Format histogram for Prometheus output
func _format_histogram(metric_name: String, endpoint: String, data: Dictionary, boundaries: Array) -> String:
	var output = ""
	var cumulative_count = 0

	# Output each bucket
	for i in range(boundaries.size()):
		cumulative_count += data["buckets"][i]
		output += '%s_bucket{endpoint="%s",le="%s"} %d\n' % [
			metric_name, _escape_label(endpoint), str(boundaries[i]), cumulative_count
		]

	# +Inf bucket
	cumulative_count += data["buckets"][boundaries.size()]
	output += '%s_bucket{endpoint="%s",le="+Inf"} %d\n' % [
		metric_name, _escape_label(endpoint), cumulative_count
	]

	# Sum and count
	output += '%s_sum{endpoint="%s"} %.6f\n' % [metric_name, _escape_label(endpoint), data["sum"]]
	output += '%s_count{endpoint="%s"} %d\n' % [metric_name, _escape_label(endpoint), data["count"]]

	return output

## Escape label values for Prometheus format
func _escape_label(value: String) -> String:
	return value.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")

## Calculate percentile from sorted array
func _percentile(sorted_array: Array, p: float) -> float:
	if sorted_array.is_empty():
		return 0.0
	var idx = int((sorted_array.size() - 1) * p)
	return sorted_array[idx]

## Get current metrics summary (for debugging)
func get_metrics_summary() -> Dictionary:
	var total_requests = 0
	for count in request_counter.values():
		total_requests += count

	var total_scene_loads = 0
	for count in scene_loads.values():
		total_scene_loads += count

	var total_errors = 0
	for count in scene_errors.values():
		total_errors += count

	return {
		"total_requests": total_requests,
		"total_scene_loads": total_scene_loads,
		"total_scene_errors": total_errors,
		"total_auth_attempts": auth_attempts.values().reduce(func(a, b): return a + b, 0),
		"active_connections": active_connections,
		"unique_endpoints": request_duration_buckets.size()
	}
