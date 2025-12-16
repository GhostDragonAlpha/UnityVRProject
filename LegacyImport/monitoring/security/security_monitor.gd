## SecurityMonitor - Real-time security monitoring and alerting
## Monitors for security events, anomalies, and threats
extends Node
class_name SecurityMonitor

## Monitoring configuration
const CHECK_INTERVAL: float = 10.0  # Check every 10 seconds
const ALERT_THRESHOLD_CRITICAL: int = 5  # Critical events trigger immediate alert
const ALERT_THRESHOLD_HIGH: int = 10
const ALERT_THRESHOLD_MEDIUM: int = 50

## Monitoring state
var event_counters: Dictionary = {
	"failed_auth": 0,
	"auth_success": 0,
	"rate_limit_violations": 0,
	"path_traversal_attempts": 0,
	"invalid_input": 0,
	"unauthorized_access": 0,
	"suspicious_activity": 0
}

var event_history: Array[Dictionary] = []
const MAX_HISTORY_SIZE: int = 1000

## Alert state
var alerts: Array[Dictionary] = []
var last_alert_time: Dictionary = {}

## Suspicious IP tracking
var suspicious_ips: Dictionary = {}  # IP -> {score: int, events: Array, first_seen: float}
const SUSPICION_THRESHOLD: int = 100
const IP_BAN_SCORE: int = 200

## Metrics
var metrics: Dictionary = {
	"total_requests": 0,
	"failed_requests": 0,
	"avg_response_time": 0.0,
	"requests_per_minute": 0.0,
	"active_sessions": 0,
	"banned_ips": 0
}

signal security_alert(severity: String, message: String, details: Dictionary)
signal suspicious_activity_detected(ip: String, score: int, events: Array)
signal ip_banned(ip: String, reason: String)

func _ready() -> void:
	# Start monitoring timer
	var monitor_timer = Timer.new()
	monitor_timer.wait_time = CHECK_INTERVAL
	monitor_timer.autostart = true
	monitor_timer.timeout.connect(_perform_security_checks)
	add_child(monitor_timer)

	print("SecurityMonitor initialized")

## Record security event
func record_event(event_type: String, details: Dictionary) -> void:
	# Update counter
	if event_counters.has(event_type):
		event_counters[event_type] += 1

	# Add to history
	var event = {
		"type": event_type,
		"timestamp": Time.get_unix_time_from_system(),
		"details": details
	}
	event_history.append(event)

	# Trim history if too large
	if event_history.size() > MAX_HISTORY_SIZE:
		event_history.pop_front()

	# Update IP suspicion score
	if details.has("ip"):
		_update_ip_suspicion(details["ip"], event_type, details)

	# Check for immediate alerts
	_check_event_alerts(event_type, details)

## Update IP suspicion scoring
func _update_ip_suspicion(ip: String, event_type: String, details: Dictionary) -> void:
	if not suspicious_ips.has(ip):
		suspicious_ips[ip] = {
			"score": 0,
			"events": [],
			"first_seen": Time.get_unix_time_from_system()
		}

	var ip_data = suspicious_ips[ip]

	# Add points based on event severity
	var points = 0
	match event_type:
		"failed_auth":
			points = 10
		"rate_limit_violations":
			points = 5
		"path_traversal_attempts":
			points = 50  # Very suspicious
		"unauthorized_access":
			points = 20
		"invalid_input":
			points = 2

	ip_data["score"] += points
	ip_data["events"].append({
		"type": event_type,
		"timestamp": Time.get_unix_time_from_system(),
		"points": points
	})

	# Check if IP should be banned
	if ip_data["score"] >= IP_BAN_SCORE:
		_ban_ip(ip, "Suspicion score threshold exceeded")
	elif ip_data["score"] >= SUSPICION_THRESHOLD:
		suspicious_activity_detected.emit(ip, ip_data["score"], ip_data["events"])

## Ban an IP address
func _ban_ip(ip: String, reason: String) -> void:
	print("SECURITY: Banning IP %s - %s" % [ip, reason])

	# Emit signal for other systems to enforce ban
	ip_banned.emit(ip, reason)

	# Update metrics
	metrics["banned_ips"] += 1

	# Generate critical alert
	_generate_alert("CRITICAL", "IP Banned", {
		"ip": ip,
		"reason": reason,
		"score": suspicious_ips.get(ip, {}).get("score", 0)
	})

## Check for immediate alert conditions
func _check_event_alerts(event_type: String, details: Dictionary) -> void:
	match event_type:
		"path_traversal_attempts":
			_generate_alert("CRITICAL", "Path Traversal Attempt Detected", details)

		"unauthorized_access":
			# Check if multiple failed attempts from same IP
			if details.has("ip"):
				var ip = details["ip"]
				var recent_failures = _count_recent_events(ip, "unauthorized_access", 60.0)
				if recent_failures >= 5:
					_generate_alert("HIGH", "Multiple Unauthorized Access Attempts", {
						"ip": ip,
						"count": recent_failures,
						"timeframe": "60 seconds"
					})

		"failed_auth":
			# Check for brute force attempts
			if details.has("ip"):
				var ip = details["ip"]
				var recent_failures = _count_recent_events(ip, "failed_auth", 300.0)
				if recent_failures >= 10:
					_generate_alert("HIGH", "Possible Brute Force Attack", {
						"ip": ip,
						"attempts": recent_failures,
						"timeframe": "5 minutes"
					})

## Count recent events from IP
func _count_recent_events(ip: String, event_type: String, timeframe: float) -> int:
	var current_time = Time.get_unix_time_from_system()
	var count = 0

	for event in event_history:
		if event["type"] == event_type:
			if event["details"].get("ip", "") == ip:
				if current_time - event["timestamp"] <= timeframe:
					count += 1

	return count

## Perform periodic security checks
func _perform_security_checks() -> void:
	var current_time = Time.get_unix_time_from_system()

	# Check for rate limit abuse patterns
	_check_rate_patterns()

	# Check for anomalies in event patterns
	_check_event_anomalies()

	# Decay IP suspicion scores over time
	_decay_suspicion_scores()

	# Calculate metrics
	_update_metrics()

	# Check alert thresholds
	_check_alert_thresholds()

## Check for suspicious rate patterns
func _check_rate_patterns() -> void:
	# Check requests per minute
	var recent_requests = _count_recent_events_total("request", 60.0)

	if recent_requests > 600:  # More than 10 req/sec sustained
		_generate_alert("MEDIUM", "High Request Rate Detected", {
			"requests_per_minute": recent_requests,
			"threshold": 600
		})

## Check for event anomalies
func _check_event_anomalies() -> void:
	# Check if failed auth rate is abnormally high
	var failed_auth_rate = event_counters.get("failed_auth", 0)
	var success_auth_rate = event_counters.get("auth_success", 0)

	if success_auth_rate > 0:
		var failure_ratio = float(failed_auth_rate) / float(success_auth_rate)
		if failure_ratio > 5.0:  # 5x more failures than successes
			_generate_alert("HIGH", "Abnormal Authentication Failure Rate", {
				"failed": failed_auth_rate,
				"successful": success_auth_rate,
				"ratio": failure_ratio
			})

## Decay suspicion scores over time
func _decay_suspicion_scores() -> void:
	var current_time = Time.get_unix_time_from_system()
	var ips_to_remove = []

	for ip in suspicious_ips:
		var ip_data = suspicious_ips[ip]

		# Decay score by 10 points per check (every 10 seconds)
		ip_data["score"] = max(0, ip_data["score"] - 10)

		# Remove if score is 0 and no recent activity
		if ip_data["score"] == 0:
			var time_since_seen = current_time - ip_data["first_seen"]
			if time_since_seen > 3600.0:  # 1 hour
				ips_to_remove.append(ip)

	for ip in ips_to_remove:
		suspicious_ips.erase(ip)

## Update metrics
func _update_metrics() -> void:
	# Calculate requests per minute
	metrics["requests_per_minute"] = _count_recent_events_total("request", 60.0)

	# Calculate failure rate
	var total = metrics["total_requests"]
	var failed = metrics["failed_requests"]
	metrics["failure_rate"] = float(failed) / float(total) if total > 0 else 0.0

## Count total recent events
func _count_recent_events_total(event_type: String, timeframe: float) -> int:
	var current_time = Time.get_unix_time_from_system()
	var count = 0

	for event in event_history:
		if event["type"] == event_type:
			if current_time - event["timestamp"] <= timeframe:
				count += 1

	return count

## Check alert thresholds
func _check_alert_thresholds() -> void:
	# Check if any event type exceeds thresholds
	for event_type in event_counters:
		var count = event_counters[event_type]

		if event_type in ["path_traversal_attempts", "unauthorized_access"]:
			if count >= ALERT_THRESHOLD_CRITICAL:
				_generate_alert("CRITICAL", "High Volume of Security Events", {
					"event_type": event_type,
					"count": count
				})
		elif event_type in ["failed_auth", "rate_limit_violations"]:
			if count >= ALERT_THRESHOLD_HIGH:
				_generate_alert("HIGH", "Elevated Security Event Volume", {
					"event_type": event_type,
					"count": count
				})

## Generate security alert
func _generate_alert(severity: String, message: String, details: Dictionary) -> void:
	var current_time = Time.get_unix_time_from_system()

	# Check if we recently alerted on this
	var alert_key = "%s:%s" % [severity, message]
	if last_alert_time.has(alert_key):
		var time_since_last = current_time - last_alert_time[alert_key]
		if time_since_last < 300.0:  # Don't re-alert within 5 minutes
			return

	last_alert_time[alert_key] = current_time

	var alert = {
		"timestamp": current_time,
		"severity": severity,
		"message": message,
		"details": details
	}

	alerts.append(alert)

	# Emit signal
	security_alert.emit(severity, message, details)

	# Log to console
	print("[SECURITY ALERT] [%s] %s" % [severity, message])
	print("  Details: %s" % JSON.stringify(details))

	# In production, also send to:
	# - Email notification system
	# - Slack/Discord webhook
	# - SIEM system
	# - PagerDuty/incident management

## Get current security status
func get_security_status() -> Dictionary:
	return {
		"event_counters": event_counters.duplicate(),
		"metrics": metrics.duplicate(),
		"suspicious_ips": suspicious_ips.size(),
		"recent_alerts": alerts.size(),
		"is_under_attack": _is_under_attack()
	}

## Determine if system is under attack
func _is_under_attack() -> bool:
	# Simple heuristic - check if multiple indicators are present
	var indicators = 0

	if event_counters.get("path_traversal_attempts", 0) > 0:
		indicators += 1

	if event_counters.get("rate_limit_violations", 0) > 20:
		indicators += 1

	if event_counters.get("failed_auth", 0) > 50:
		indicators += 1

	if suspicious_ips.size() > 5:
		indicators += 1

	return indicators >= 2

## Reset counters (call periodically, e.g., hourly)
func reset_counters() -> void:
	for key in event_counters:
		event_counters[key] = 0

	print("SecurityMonitor: Counters reset")

## Get recent alerts
func get_recent_alerts(count: int = 10) -> Array:
	var recent = alerts.slice(max(0, alerts.size() - count), alerts.size())
	recent.reverse()
	return recent

## Export security report
func export_security_report() -> Dictionary:
	return {
		"timestamp": Time.get_unix_time_from_system(),
		"event_counters": event_counters.duplicate(),
		"metrics": metrics.duplicate(),
		"suspicious_ips_count": suspicious_ips.size(),
		"suspicious_ips": _get_top_suspicious_ips(10),
		"recent_alerts": get_recent_alerts(20),
		"is_under_attack": _is_under_attack(),
		"banned_ips_count": metrics["banned_ips"]
	}

## Get top suspicious IPs
func _get_top_suspicious_ips(count: int) -> Array:
	var ip_list = []

	for ip in suspicious_ips:
		ip_list.append({
			"ip": ip,
			"score": suspicious_ips[ip]["score"],
			"event_count": suspicious_ips[ip]["events"].size()
		})

	# Sort by score descending
	ip_list.sort_custom(func(a, b): return a["score"] > b["score"])

	return ip_list.slice(0, min(count, ip_list.size()))
