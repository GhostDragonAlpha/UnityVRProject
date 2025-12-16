class_name PipeNetwork
extends Node

## Pipe network manager
## Manages connected pipes and fluid flow

var network_id: String = ""
var pipes: Array[Pipe] = []

func _ready():
	network_id = str(get_instance_id())

func add_pipe(pipe: Pipe) -> void:
	if not pipes.has(pipe):
		pipes.append(pipe)
		update_network()

func remove_pipe(pipe: Pipe) -> void:
	pipes.erase(pipe)
	update_network()

func update_network() -> void:
	# Stub - actual implementation would calculate flow rates
	pass

func save_state() -> Dictionary:
	var pipe_data: Array = []
	for pipe in pipes:
		if pipe and pipe.has_method("save_state"):
			pipe_data.append(pipe.save_state())

	return {
		"network_id": network_id,
		"pipes": pipe_data
	}

func load_state(data: Dictionary) -> void:
	network_id = data.get("network_id", network_id)
	# Stub - actual implementation would recreate pipes
