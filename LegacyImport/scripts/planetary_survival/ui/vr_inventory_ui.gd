## VRInventoryUI - VR-optimized spatial inventory interface
##
## Provides intuitive VR inventory system with:
## - Spatial item placement and interaction
## - Hand-based grabbing and manipulation
## - Haptic feedback for all interactions
## - Visual item previews in 3D
## - Grid-based organization with snap-to-grid
## - Ergonomic positioning for comfort

extends Node3D
class_name VRInventoryUI

signal item_selected(item: Resource)
signal item_used(item: Resource)
signal item_dropped(item: Resource)
signal inventory_opened()
signal inventory_closed()

## Inventory grid settings
@export var grid_columns: int = 4
@export var grid_rows: int = 6
@export var cell_size: float = 0.15  # 15cm cells
@export var cell_spacing: float = 0.02

## Panel settings
@export var panel_distance: float = 0.5  # Attached to wrist (50cm)
@export var panel_offset: Vector3 = Vector3(-0.2, 0.1, 0)  # Left of hand

## Visual settings
@export var hover_highlight_color: Color = Color(0.4, 0.7, 1.0, 0.3)
@export var selected_highlight_color: Color = Color(0.2, 1.0, 0.4, 0.5)
@export var empty_cell_color: Color = Color(0.2, 0.2, 0.25, 0.6)

## System references
var vr_manager: VRManager = null
var haptic_manager: HapticManager = null
var inventory_manager = null
var left_controller: XRController3D = null
var right_controller: XRController3D = null

## UI components
var background_panel: MeshInstance3D = null
var grid_cells: Array[Dictionary] = []  # {mesh, item, position, index}
var item_previews: Dictionary = {}  # item -> MeshInstance3D

## Interaction state
var is_open: bool = false
var hover_cell_index: int = -1
var selected_cell_index: int = -1
var grabbed_item: Resource = null
var grab_offset: Vector3 = Vector3.ZERO

## Input tracking
var grip_pressed: bool = false
var trigger_pressed: bool = false

## Attachment (which hand to attach to)
@export var attach_to_hand: String = "left"  # "left" or "right"
var attached_controller: XRController3D = null


func _ready() -> void:
	# Get system references
	vr_manager = get_node_or_null("/root/ResonanceEngine/VRManager")
	if vr_manager:
		left_controller = vr_manager.get_controller("left")
		right_controller = vr_manager.get_controller("right")
		attached_controller = left_controller if attach_to_hand == "left" else right_controller

	haptic_manager = get_node_or_null("/root/ResonanceEngine/HapticManager")
	inventory_manager = get_node_or_null("/root/PersistenceSystem/InventoryManager")

	# Create inventory UI
	_create_inventory_panel()
	_create_grid_cells()

	# Start hidden
	visible = false

	print("VRInventoryUI: Initialized successfully")


func _create_inventory_panel() -> void:
	"""Create the main inventory panel background."""
	background_panel = MeshInstance3D.new()
	background_panel.name = "BackgroundPanel"

	var panel_width: float = grid_columns * (cell_size + cell_spacing) + cell_spacing
	var panel_height: float = grid_rows * (cell_size + cell_spacing) + cell_spacing

	var mesh := QuadMesh.new()
	mesh.size = Vector2(panel_width, panel_height)
	background_panel.mesh = mesh

	# Create material
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.08, 0.1, 0.15, 0.9)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.emission_enabled = true
	material.emission = Color(0.15, 0.2, 0.3)
	material.emission_energy = 0.4
	background_panel.material_override = material

	add_child.call_deferred(background_panel)


func _create_grid_cells() -> void:
	"""Create inventory grid cells."""
	grid_cells.clear()

	var panel_width: float = grid_columns * (cell_size + cell_spacing) + cell_spacing
	var panel_height: float = grid_rows * (cell_size + cell_spacing) + cell_spacing

	var start_x: float = -panel_width * 0.5 + cell_spacing + cell_size * 0.5
	var start_y: float = panel_height * 0.5 - cell_spacing - cell_size * 0.5

	for row in range(grid_rows):
		for col in range(grid_columns):
			var cell_index: int = row * grid_columns + col
			var cell_pos := Vector3(
				start_x + col * (cell_size + cell_spacing),
				start_y - row * (cell_size + cell_spacing),
				0.01  # Slightly in front of background
			)

			var cell := _create_cell(cell_index, cell_pos)
			grid_cells.append(cell)


func _create_cell(index: int, position: Vector3) -> Dictionary:
	"""Create a single inventory cell."""
	var cell_data := {
		"index": index,
		"position": position,
		"mesh": null,
		"item": null,
		"item_preview": null
	}

	# Create cell mesh
	var cell_mesh := MeshInstance3D.new()
	cell_mesh.name = "Cell_%d" % index

	var mesh := QuadMesh.new()
	mesh.size = Vector2(cell_size, cell_size)
	cell_mesh.mesh = mesh
	cell_mesh.position = position

	# Create cell material
	var material := StandardMaterial3D.new()
	material.albedo_color = empty_cell_color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	cell_mesh.material_override = material

	background_panel.add_child.call_deferred(cell_mesh)
	cell_data["mesh"] = cell_mesh

	return cell_data


func open_inventory() -> void:
	"""Open the inventory UI."""
	if is_open:
		return

	is_open = true
	visible = true

	# Position attached to controller
	_update_position()

	# Refresh inventory contents
	_refresh_inventory()

	# Haptic feedback
	if haptic_manager:
		haptic_manager.trigger_haptic(attach_to_hand, 0.2, 0.1)

	inventory_opened.emit()
	print("VRInventoryUI: Opened inventory")


func close_inventory() -> void:
	"""Close the inventory UI."""
	if not is_open:
		return

	is_open = false
	visible = false

	# Drop grabbed item if any
	if grabbed_item:
		_drop_grabbed_item()

	# Haptic feedback
	if haptic_manager:
		haptic_manager.trigger_haptic(attach_to_hand, 0.2, 0.1)

	inventory_closed.emit()
	print("VRInventoryUI: Closed inventory")


func toggle_inventory() -> void:
	"""Toggle inventory open/closed."""
	if is_open:
		close_inventory()
	else:
		open_inventory()


func _update_position() -> void:
	"""Update inventory position attached to controller."""
	if not attached_controller:
		return

	# Position relative to controller
	var controller_transform: Transform3D = attached_controller.global_transform
	global_position = controller_transform.origin + controller_transform.basis * panel_offset

	# Face the camera
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera:
		look_at(camera.global_position, Vector3.UP)


func _refresh_inventory() -> void:
	"""Refresh inventory contents from InventoryManager."""
	if not inventory_manager:
		return

	# Clear existing items
	for cell in grid_cells:
		_clear_cell(cell)

	# Get inventory items
	var items: Array = []
	if inventory_manager.has_method("get_all_items"):
		items = inventory_manager.get_all_items()

	# Populate cells with items
	for i in range(min(items.size(), grid_cells.size())):
		var item = items[i]
		var cell = grid_cells[i]
		_set_cell_item(cell, item)


func _clear_cell(cell: Dictionary) -> void:
	"""Clear a cell's item."""
	cell["item"] = null

	# Remove item preview
	if cell["item_preview"]:
		cell["item_preview"].queue_free()
		cell["item_preview"] = null

	# Reset cell appearance
	var mesh: MeshInstance3D = cell["mesh"]
	if mesh and mesh.material_override is StandardMaterial3D:
		mesh.material_override.albedo_color = empty_cell_color


func _set_cell_item(cell: Dictionary, item: Resource) -> void:
	"""Set a cell's item and create preview."""
	cell["item"] = item

	# Create item preview (simplified - would load actual 3D model)
	var preview := MeshInstance3D.new()
	preview.name = "ItemPreview_%d" % cell["index"]

	# Use simple sphere for preview (in production, load item's mesh)
	var sphere := SphereMesh.new()
	sphere.radius = cell_size * 0.35
	preview.mesh = sphere

	# Color based on item type (simplified)
	var material := StandardMaterial3D.new()
	material.albedo_color = _get_item_color(item)
	material.emission_enabled = true
	material.emission = material.albedo_color * 0.5
	material.emission_energy = 0.5
	preview.material_override = material

	preview.position = cell["position"] + Vector3(0, 0, 0.02)
	background_panel.add_child(preview)
	cell["item_preview"] = preview

	# Update cell appearance
	var mesh: MeshInstance3D = cell["mesh"]
	if mesh and mesh.material_override is StandardMaterial3D:
		mesh.material_override.albedo_color = Color(0.25, 0.28, 0.35, 0.8)


func _get_item_color(item: Resource) -> Color:
	"""Get color for item preview (simplified)."""
	if not item:
		return Color.WHITE

	# In production, this would check item type/category
	var hash: int = item.get_instance_id()
	var hue: float = (hash % 360) / 360.0
	return Color.from_hsv(hue, 0.6, 0.9)


func _process(delta: float) -> void:
	"""Process input and updates."""
	if not is_open:
		return

	# Update position to follow controller
	_update_position()

	# Update hover detection
	_update_hover()

	# Handle input
	_handle_input()


func _update_hover() -> void:
	"""Update which cell is being hovered."""
	var previous_hover: int = hover_cell_index
	hover_cell_index = -1

	# Get the non-attached controller for interaction
	var interaction_controller: XRController3D = null
	if attach_to_hand == "left":
		interaction_controller = right_controller
	else:
		interaction_controller = left_controller

	if interaction_controller:
		hover_cell_index = _raycast_cell(interaction_controller)

	# Update cell visuals
	if previous_hover != hover_cell_index:
		if previous_hover >= 0 and previous_hover < grid_cells.size():
			_update_cell_visual(grid_cells[previous_hover], false, false)

		if hover_cell_index >= 0 and hover_cell_index < grid_cells.size():
			_update_cell_visual(grid_cells[hover_cell_index], true, false)
			# Haptic feedback on hover
			if haptic_manager:
				var hand: String = "right" if attach_to_hand == "left" else "left"
				haptic_manager.trigger_haptic(hand, 0.1, 0.05)


func _raycast_cell(controller: XRController3D) -> int:
	"""Raycast from controller to find cell."""
	if not controller:
		return -1

	var ray_start: Vector3 = controller.global_position
	var ray_dir: Vector3 = -controller.global_transform.basis.z

	# Check intersection with inventory plane
	var plane := Plane(global_transform.basis.z, global_position)
	var hit_pos: Variant = plane.intersects_ray(ray_start, ray_dir)

	if hit_pos == null or not hit_pos is Vector3:
		return -1

	# Find closest cell to hit position
	var local_hit: Vector3 = global_transform.affine_inverse() * hit_pos
	var min_dist: float = INF
	var closest_cell: int = -1

	for cell in grid_cells:
		var cell_pos: Vector3 = cell["position"]
		var dist: float = local_hit.distance_to(cell_pos)

		if dist < cell_size * 0.5 and dist < min_dist:
			min_dist = dist
			closest_cell = cell["index"]

	return closest_cell


func _update_cell_visual(cell: Dictionary, is_hover: bool, is_selected: bool) -> void:
	"""Update cell visual appearance."""
	var mesh: MeshInstance3D = cell["mesh"]
	if not mesh or not mesh.material_override is StandardMaterial3D:
		return

	var material: StandardMaterial3D = mesh.material_override

	if is_selected:
		material.albedo_color = selected_highlight_color
		material.emission_enabled = true
		material.emission = selected_highlight_color * 0.8
		material.emission_energy = 0.6
	elif is_hover:
		material.albedo_color = hover_highlight_color
		material.emission_enabled = true
		material.emission = hover_highlight_color * 0.6
		material.emission_energy = 0.4
	elif cell["item"]:
		material.albedo_color = Color(0.25, 0.28, 0.35, 0.8)
		material.emission_enabled = false
	else:
		material.albedo_color = empty_cell_color
		material.emission_enabled = false


func _handle_input() -> void:
	"""Handle controller input."""
	# Get the non-attached controller for interaction
	var interaction_controller: XRController3D = null
	var hand: String = ""

	if attach_to_hand == "left":
		interaction_controller = right_controller
		hand = "right"
	else:
		interaction_controller = left_controller
		hand = "left"

	if not interaction_controller:
		return

	var trigger_now: bool = interaction_controller.is_button_pressed("trigger_click")
	var grip_now: bool = interaction_controller.is_button_pressed("grip_click")

	# Trigger: Select/use item
	if trigger_now and not trigger_pressed:
		_on_trigger_pressed()

	# Grip: Grab item
	if grip_now and not grip_pressed:
		_on_grip_pressed()
	elif not grip_now and grip_pressed:
		_on_grip_released()

	trigger_pressed = trigger_now
	grip_pressed = grip_now


func _on_trigger_pressed() -> void:
	"""Handle trigger press - use/select item."""
	if hover_cell_index < 0 or hover_cell_index >= grid_cells.size():
		return

	var cell = grid_cells[hover_cell_index]
	if not cell["item"]:
		return

	selected_cell_index = hover_cell_index
	_update_cell_visual(cell, false, true)

	# Emit item selected
	item_selected.emit(cell["item"])

	# Haptic feedback
	if haptic_manager:
		var hand: String = "right" if attach_to_hand == "left" else "left"
		haptic_manager.trigger_haptic(hand, 0.4, 0.1)

	print("VRInventoryUI: Item selected at cell %d" % hover_cell_index)


func _on_grip_pressed() -> void:
	"""Handle grip press - grab item."""
	if hover_cell_index < 0 or hover_cell_index >= grid_cells.size():
		return

	var cell = grid_cells[hover_cell_index]
	if not cell["item"]:
		return

	grabbed_item = cell["item"]
	_clear_cell(cell)

	# Haptic feedback
	if haptic_manager:
		var hand: String = "right" if attach_to_hand == "left" else "left"
		haptic_manager.trigger_haptic(hand, 0.5, 0.15)

	print("VRInventoryUI: Item grabbed from cell %d" % hover_cell_index)


func _on_grip_released() -> void:
	"""Handle grip release - place item."""
	if not grabbed_item:
		return

	if hover_cell_index >= 0 and hover_cell_index < grid_cells.size():
		# Place in hovered cell
		var cell = grid_cells[hover_cell_index]
		if not cell["item"]:
			_set_cell_item(cell, grabbed_item)
			grabbed_item = null

			# Haptic feedback
			if haptic_manager:
				var hand: String = "right" if attach_to_hand == "left" else "left"
				haptic_manager.trigger_haptic(hand, 0.3, 0.1)

			print("VRInventoryUI: Item placed in cell %d" % hover_cell_index)
			return

	# Drop item if not placed
	_drop_grabbed_item()


func _drop_grabbed_item() -> void:
	"""Drop grabbed item (emit event)."""
	if not grabbed_item:
		return

	item_dropped.emit(grabbed_item)
	grabbed_item = null

	# Haptic feedback
	if haptic_manager:
		var hand: String = "right" if attach_to_hand == "left" else "left"
		haptic_manager.trigger_haptic(hand, 0.2, 0.08)

	print("VRInventoryUI: Item dropped")


## PUBLIC API

func add_item(item: Resource) -> bool:
	"""Add item to inventory."""
	# Find empty cell
	for cell in grid_cells:
		if not cell["item"]:
			_set_cell_item(cell, item)
			return true

	print("VRInventoryUI: Inventory full, cannot add item")
	return false


func remove_item(item: Resource) -> bool:
	"""Remove item from inventory."""
	for cell in grid_cells:
		if cell["item"] == item:
			_clear_cell(cell)
			return true

	return false


func get_item_at_cell(index: int) -> Resource:
	"""Get item at specific cell."""
	if index < 0 or index >= grid_cells.size():
		return null

	return grid_cells[index]["item"]


func set_attach_hand(hand: String) -> void:
	"""Set which hand to attach inventory to."""
	attach_to_hand = hand
	attached_controller = left_controller if hand == "left" else right_controller
	print("VRInventoryUI: Attached to %s hand" % hand)
