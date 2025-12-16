class_name Pipe
extends Node3D

## Pipe for fluid/gas transport
## Connects source to destination with flow rate limits

var pipe_id: String = ""
var start_position: Vector3 = Vector3.ZERO
var end_position: Vector3 = Vector3.ZERO
var max_flow_rate: float = 10.0 # units per second
var pressure: float = 1.0 # atmospheric pressure
var fluid_type: String = ""
var source_node: Node = null
var destination_node: Node = null

func _ready():
	pipe_id = str(get_instance_id())

func add_fluid(amount: float) -> void:
	# Stub - actual implementation would transfer fluid
	pass

func connect_to_destination(dest: Node) -> void:
	destination_node = dest

func connect_from_source(src: Node) -> void:
	source_node = src

func save_state() -> Dictionary:
	return {
		"pipe_id": pipe_id,
		"start_position": start_position,
		"end_position": end_position,
		"max_flow_rate": max_flow_rate,
		"pressure": pressure,
		"fluid_type": fluid_type
	}

func load_state(data: Dictionary) -> void:
	pipe_id = data.get("pipe_id", pipe_id)
	start_position = data.get("start_position", Vector3.ZERO)
	end_position = data.get("end_position", Vector3.ZERO)
	max_flow_rate = data.get("max_flow_rate", 10.0)
	pressure = data.get("pressure", 1.0)
	fluid_type = data.get("fluid_type", "")
