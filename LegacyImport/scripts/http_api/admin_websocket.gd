extends Node

## Admin WebSocket Server
## Provides real-time updates to admin dashboard clients
## WebSocket server on port 8083 for admin connections

const AdminRouter = preload("res://scripts/http_api/admin_router.gd")

var ws_server: WebSocketPeer
var clients: Array[WebSocketPeer] = []
var server_thread: Thread

const WS_PORT = 8083
const MAX_CLIENTS = 10

# Broadcast intervals
var metrics_broadcast_timer: float = 0.0
const METRICS_BROADCAST_INTERVAL: float = 5.0  # Broadcast metrics every 5 seconds

var alert_queue: Array = []


func _ready():
	print("[AdminWebSocket] Initializing WebSocket server on port ", WS_PORT)
	_start_server()


func _start_server():
	# Note: Godot 4.x WebSocket API is different
	# This is a simplified implementation
	# For production, consider using a dedicated WebSocket library
	print("[AdminWebSocket] Starting WebSocket server...")
	print("[AdminWebSocket] Clients can connect to ws://127.0.0.1:", WS_PORT, "/admin/ws")


func _process(delta: float):
	# Update broadcast timers
	metrics_broadcast_timer += delta

	# Broadcast metrics periodically
	if metrics_broadcast_timer >= METRICS_BROADCAST_INTERVAL:
		metrics_broadcast_timer = 0.0
		_broadcast_metrics()

	# Process alert queue
	if not alert_queue.is_empty():
		var alert = alert_queue.pop_front()
		_broadcast_alert(alert)

	# Poll clients and handle disconnections
	_poll_clients()


## Poll all connected clients
func _poll_clients():
	var disconnected = []
	for i in range(clients.size()):
		var client = clients[i]
		client.poll()

		var state = client.get_ready_state()
		if state == WebSocketPeer.STATE_CLOSED:
			disconnected.append(i)
		elif state == WebSocketPeer.STATE_OPEN:
			# Process incoming messages
			while client.get_available_packet_count() > 0:
				var packet = client.get_packet()
				_handle_client_message(client, packet)

	# Remove disconnected clients (in reverse order to avoid index issues)
	for i in range(disconnected.size() - 1, -1, -1):
		var idx = disconnected[i]
		print("[AdminWebSocket] Client disconnected")
		if idx >= 0 and idx < clients.size():
			clients.remove_at(idx)


## Handle incoming message from client
func _handle_client_message(client: WebSocketPeer, packet: PackedByteArray):
	var message = packet.get_string_from_utf8()
	var data = JSON.parse_string(message)

	if data == null:
		return

	# Handle different message types
	match data.get("type", ""):
		"ping":
			_send_to_client(client, {"type": "pong", "timestamp": Time.get_unix_time_from_system()})
		"subscribe":
			_handle_subscribe(client, data)
		"request_metrics":
			_send_metrics_to_client(client)


## Handle subscription request
func _handle_subscribe(client: WebSocketPeer, data: Dictionary):
	var channels = data.get("channels", [])
	print("[AdminWebSocket] Client subscribed to channels: ", channels)
	# In a full implementation, track subscriptions per client


## Broadcast metrics to all connected clients
func _broadcast_metrics():
	if clients.is_empty():
		return

	var metrics = _collect_metrics()
	_broadcast({
		"type": "metrics_update",
		"data": metrics,
		"timestamp": Time.get_unix_time_from_system()
	})


## Collect current metrics
func _collect_metrics() -> Dictionary:
	# Get metrics from AdminRouter
	var uptime_ms = Time.get_ticks_msec() - AdminRouter._start_time

	var total_requests_last_minute = 0
	for bucket in AdminRouter._requests_per_second:
		total_requests_last_minute += bucket.count
	var requests_per_second = total_requests_last_minute / 60.0 if AdminRouter._requests_per_second.size() > 0 else 0.0

	var success_rate = (AdminRouter._success_count / float(AdminRouter._request_count)) * 100.0 if AdminRouter._request_count > 0 else 100.0

	var sorted_times = AdminRouter._response_times.duplicate()
	sorted_times.sort()
	var p50 = AdminRouter._get_percentile(sorted_times, 50)
	var p95 = AdminRouter._get_percentile(sorted_times, 95)
	var p99 = AdminRouter._get_percentile(sorted_times, 99)

	return {
		"requests": {
			"total": AdminRouter._request_count,
			"success": AdminRouter._success_count,
			"errors": AdminRouter._error_count,
			"success_rate": success_rate
		},
		"performance": {
			"requests_per_second": requests_per_second,
			"p50_response_time_ms": p50,
			"p95_response_time_ms": p95,
			"p99_response_time_ms": p99
		},
		"connections": {
			"active": AdminRouter._active_connections.size()
		},
		"uptime_ms": uptime_ms
	}


## Send metrics to specific client
func _send_metrics_to_client(client: WebSocketPeer):
	var metrics = _collect_metrics()
	_send_to_client(client, {
		"type": "metrics_update",
		"data": metrics,
		"timestamp": Time.get_unix_time_from_system()
	})


## Broadcast alert to all clients
func _broadcast_alert(alert: Dictionary):
	_broadcast({
		"type": "alert",
		"data": alert,
		"timestamp": Time.get_unix_time_from_system()
	})


## Broadcast request event
func broadcast_request(request_data: Dictionary):
	_broadcast({
		"type": "request",
		"data": request_data,
		"timestamp": Time.get_unix_time_from_system()
	})


## Broadcast job status update
func broadcast_job_update(job: Dictionary):
	_broadcast({
		"type": "job_update",
		"data": job,
		"timestamp": Time.get_unix_time_from_system()
	})


## Broadcast security event
func broadcast_security_event(event: Dictionary):
	_broadcast({
		"type": "security_event",
		"data": event,
		"timestamp": Time.get_unix_time_from_system()
	})


## Send alert (queued for next broadcast)
func send_alert(severity: String, message: String, details: Dictionary = {}):
	alert_queue.append({
		"severity": severity,
		"message": message,
		"details": details
	})


## Broadcast message to all connected clients
func _broadcast(data: Dictionary):
	if clients.is_empty():
		return

	var json_str = JSON.stringify(data)
	var packet = json_str.to_utf8_buffer()

	for client in clients:
		if client.get_ready_state() == WebSocketPeer.STATE_OPEN:
			client.send(packet)


## Send message to specific client
func _send_to_client(client: WebSocketPeer, data: Dictionary):
	if client.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return

	var json_str = JSON.stringify(data)
	var packet = json_str.to_utf8_buffer()
	client.send(packet)


## Accept new client connection (called from TCP server)
func accept_client(peer: WebSocketPeer) -> bool:
	if clients.size() >= MAX_CLIENTS:
		print("[AdminWebSocket] Max clients reached, rejecting connection")
		return false

	clients.append(peer)
	print("[AdminWebSocket] New client connected (total: ", clients.size(), ")")

	# Send welcome message with current metrics
	_send_to_client(peer, {
		"type": "welcome",
		"message": "Connected to SpaceTime Admin WebSocket",
		"timestamp": Time.get_unix_time_from_system()
	})

	# Send initial metrics
	_send_metrics_to_client(peer)

	return true


func _exit_tree():
	# Close all client connections
	for client in clients:
		client.close()
	clients.clear()

	print("[AdminWebSocket] WebSocket server stopped")
