extends Node
class_name TLSServerWrapper

## Native Godot TLS Server Wrapper
## Wraps TCPServer with StreamPeerTLS for HTTPS support
## Use NGINX reverse proxy when possible - this is a fallback option
##
## WARNING: This is experimental and not as battle-tested as NGINX
## Only use when NGINX/reverse proxy is not available

signal client_connected(peer_id: int)
signal client_disconnected(peer_id: int)
signal tls_error(error_message: String)

const TLS_CONFIG_PATH = "res://scripts/http_api/tls_config.json"

var tcp_server: TCPServer
var tls_clients: Dictionary = {}  # peer_id -> {tcp: StreamPeerTCP, tls: StreamPeerTLS, state: String}
var next_peer_id: int = 1
var running: bool = false

var bind_address: String = "127.0.0.1"
var port: int = 8443
var cert_path: String = ""
var key_path: String = ""

var tls_options: TLSOptions


func _init(_port: int = 8443, _bind_address: String = "127.0.0.1"):
	port = _port
	bind_address = _bind_address


func _ready() -> void:
	set_process(false)


## Load TLS configuration from config file
func load_config() -> bool:
	print("[TLSServerWrapper] Loading TLS configuration...")

	if not FileAccess.file_exists(TLS_CONFIG_PATH):
		push_error("[TLSServerWrapper] Config file not found: " + TLS_CONFIG_PATH)
		return false

	var file = FileAccess.open(TLS_CONFIG_PATH, FileAccess.READ)
	if not file:
		push_error("[TLSServerWrapper] Failed to open config file")
		return false

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		push_error("[TLSServerWrapper] Failed to parse JSON: " + json.get_error_message())
		return false

	var config = json.data
	if not config.has("tls"):
		push_error("[TLSServerWrapper] Missing 'tls' section in config")
		return false

	var tls_config = config["tls"]

	# Determine certificate paths based on environment
	var env = "dev"  # Default to development
	if OS.has_environment("SPACETIME_ENV"):
		env = OS.get_environment("SPACETIME_ENV")

	var certs = tls_config["certificates"][env]
	cert_path = certs["cert_path"]
	key_path = certs["key_path"]

	print("[TLSServerWrapper] Environment: ", env)
	print("[TLSServerWrapper] Certificate: ", cert_path)
	print("[TLSServerWrapper] Key: ", key_path)

	return true


## Start the TLS server
func start() -> bool:
	print("[TLSServerWrapper] Starting TLS server...")

	# Load configuration
	if not load_config():
		return false

	# Load certificate and key
	if not _load_tls_options():
		return false

	# Create TCP server
	tcp_server = TCPServer.new()

	# Start listening
	var err = tcp_server.listen(port, bind_address)
	if err != OK:
		push_error("[TLSServerWrapper] Failed to bind to %s:%d - Error: %d" % [bind_address, port, err])
		match err:
			ERR_ALREADY_IN_USE:
				push_error("[TLSServerWrapper] Port %d already in use" % port)
			ERR_CANT_CREATE:
				push_error("[TLSServerWrapper] Cannot create server")
		return false

	running = true
	set_process(true)

	print("[TLSServerWrapper] ✓ TLS server listening on https://%s:%d" % [bind_address, port])
	return true


## Load TLS certificate and key into TLSOptions
func _load_tls_options() -> bool:
	print("[TLSServerWrapper] Loading TLS certificate and key...")

	# Check if files exist
	if not FileAccess.file_exists(cert_path):
		push_error("[TLSServerWrapper] Certificate file not found: " + cert_path)
		print("[TLSServerWrapper] Generate certificate with:")
		print("[TLSServerWrapper]   python scripts/certificate_manager.py --generate-dev")
		return false

	if not FileAccess.file_exists(key_path):
		push_error("[TLSServerWrapper] Key file not found: " + key_path)
		return false

	# Load certificate
	var cert_file = FileAccess.open(cert_path, FileAccess.READ)
	if not cert_file:
		push_error("[TLSServerWrapper] Failed to open certificate file")
		return false
	var cert_data = cert_file.get_as_text()
	cert_file.close()

	# Load private key
	var key_file = FileAccess.open(key_path, FileAccess.READ)
	if not key_file:
		push_error("[TLSServerWrapper] Failed to open key file")
		return false
	var key_data = key_file.get_as_text()
	key_file.close()

	# Create X509Certificate
	var cert = X509Certificate.new()
	var cert_err = cert.load_from_string(cert_data)
	if cert_err != OK:
		push_error("[TLSServerWrapper] Failed to load certificate: Error %d" % cert_err)
		return false

	# Create CryptoKey
	var key = CryptoKey.new()
	var key_err = key.load_from_string(key_data)
	if key_err != OK:
		push_error("[TLSServerWrapper] Failed to load private key: Error %d" % key_err)
		return false

	# Create TLSOptions for server
	tls_options = TLSOptions.server(key, cert)
	if not tls_options:
		push_error("[TLSServerWrapper] Failed to create TLSOptions")
		return false

	print("[TLSServerWrapper] ✓ TLS certificate and key loaded successfully")
	return true


## Process incoming connections and data
func _process(_delta: float) -> void:
	if not running:
		return

	# Accept new connections
	if tcp_server.is_connection_available():
		var tcp_peer = tcp_server.take_connection()
		if tcp_peer:
			_accept_tls_connection(tcp_peer)

	# Process existing TLS connections
	_process_tls_clients()


## Accept new TLS connection from TCP peer
func _accept_tls_connection(tcp_peer: StreamPeerTCP) -> void:
	var peer_id = next_peer_id
	next_peer_id += 1

	print("[TLSServerWrapper] Accepting TLS connection from peer %d" % peer_id)

	# Create TLS peer
	var tls_peer = StreamPeerTLS.new()

	# Start TLS handshake
	var err = tls_peer.accept_stream(tcp_peer, tls_options)
	if err != OK:
		push_error("[TLSServerWrapper] Failed to accept TLS stream: Error %d" % err)
		tcp_peer.disconnect_from_host()
		return

	# Store client info
	tls_clients[peer_id] = {
		"tcp": tcp_peer,
		"tls": tls_peer,
		"state": "handshaking",
		"buffer": PackedByteArray()
	}

	print("[TLSServerWrapper] TLS handshake started for peer %d" % peer_id)


## Process TLS clients
func _process_tls_clients() -> void:
	var disconnected_peers = []

	for peer_id in tls_clients.keys():
		var client = tls_clients[peer_id]
		var tls_peer: StreamPeerTLS = client["tls"]
		var tcp_peer: StreamPeerTCP = client["tcp"]

		# Poll TLS connection
		tls_peer.poll()

		var status = tls_peer.get_status()

		match status:
			StreamPeerTLS.STATUS_HANDSHAKING:
				# Still handshaking
				pass

			StreamPeerTLS.STATUS_CONNECTED:
				if client["state"] == "handshaking":
					client["state"] = "connected"
					print("[TLSServerWrapper] TLS handshake complete for peer %d" % peer_id)
					client_connected.emit(peer_id)

				# Read available data
				var available = tls_peer.get_available_bytes()
				if available > 0:
					var data = tls_peer.get_data(available)
					if data[0] == OK:
						_handle_client_data(peer_id, data[1])

			StreamPeerTLS.STATUS_ERROR:
				push_error("[TLSServerWrapper] TLS error for peer %d" % peer_id)
				tls_error.emit("TLS error for peer %d" % peer_id)
				disconnected_peers.append(peer_id)

			StreamPeerTLS.STATUS_ERROR_HOSTNAME_MISMATCH:
				push_error("[TLSServerWrapper] Hostname mismatch for peer %d" % peer_id)
				disconnected_peers.append(peer_id)

		# Check if TCP connection is still alive
		if tcp_peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			print("[TLSServerWrapper] TCP connection lost for peer %d" % peer_id)
			disconnected_peers.append(peer_id)

	# Clean up disconnected clients
	for peer_id in disconnected_peers:
		_disconnect_client(peer_id)


## Handle data received from client
func _handle_client_data(peer_id: int, data: PackedByteArray) -> void:
	# This is where HTTP request parsing would happen
	# For now, just log that we received data
	print("[TLSServerWrapper] Received %d bytes from peer %d" % [data.size(), peer_id])

	# TODO: Parse HTTP request and generate response
	# This would integrate with the existing HTTP router system

	# For now, send a simple HTTP response
	var response = "HTTP/1.1 200 OK\r\n"
	response += "Content-Type: text/plain\r\n"
	response += "Content-Length: 12\r\n"
	response += "\r\n"
	response += "Hello, TLS!\n"

	send_to_client(peer_id, response.to_utf8_buffer())


## Send data to specific client
func send_to_client(peer_id: int, data: PackedByteArray) -> bool:
	if not tls_clients.has(peer_id):
		push_error("[TLSServerWrapper] Unknown peer ID: %d" % peer_id)
		return false

	var client = tls_clients[peer_id]
	var tls_peer: StreamPeerTLS = client["tls"]

	if tls_peer.get_status() != StreamPeerTLS.STATUS_CONNECTED:
		push_error("[TLSServerWrapper] Peer %d not connected" % peer_id)
		return false

	var err = tls_peer.put_data(data)
	if err != OK:
		push_error("[TLSServerWrapper] Failed to send data to peer %d: Error %d" % [peer_id, err])
		return false

	return true


## Disconnect a client
func _disconnect_client(peer_id: int) -> void:
	if not tls_clients.has(peer_id):
		return

	print("[TLSServerWrapper] Disconnecting peer %d" % peer_id)

	var client = tls_clients[peer_id]
	var tcp_peer: StreamPeerTCP = client["tcp"]

	tcp_peer.disconnect_from_host()
	tls_clients.erase(peer_id)

	client_disconnected.emit(peer_id)


## Stop the server
func stop() -> void:
	if not running:
		return

	print("[TLSServerWrapper] Stopping TLS server...")

	# Disconnect all clients
	for peer_id in tls_clients.keys():
		_disconnect_client(peer_id)

	# Stop TCP server
	if tcp_server:
		tcp_server.stop()

	running = false
	set_process(false)

	print("[TLSServerWrapper] TLS server stopped")


func _exit_tree() -> void:
	stop()
