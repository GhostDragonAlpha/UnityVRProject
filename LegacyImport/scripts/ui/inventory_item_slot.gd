## InventoryItemSlot - Enhanced 3D slot with visual feedback
## Displays item with 3D model, label, quantity badge, and durability
## Requirements: 44.1, 44.2, 44.3

class_name InventoryItemSlot
extends Node3D

signal slot_hovered(slot: InventoryItemSlot)
signal slot_unhovered(slot: InventoryItemSlot)
signal slot_clicked(slot: InventoryItemSlot)
signal slot_grabbed(slot: InventoryItemSlot)
signal slot_released(slot: InventoryItemSlot)

## Slot configuration
@export var slot_index: int = 0
@export var slot_size: float = 0.1  # 10cm
@export var enabled: bool = true

## Visual components
var background: MeshInstance3D = null
var item_model: MeshInstance3D = null
var quantity_label: Label3D = null
var durability_bar: MeshInstance3D = null
var rarity_border: MeshInstance3D = null

## Materials
var default_material: StandardMaterial3D = null
var hover_material: StandardMaterial3D = null
var occupied_material: StandardMaterial3D = null
var disabled_material: StandardMaterial3D = null

## State
var item_data: Dictionary = {}  # {item_id, quantity, durability, rarity}
var is_occupied: bool = false
var is_hovered: bool = false
var is_grabbed: bool = false

## Collision body for interaction
var collision_body: StaticBody3D = null


func _ready() -> void:
	_setup_materials()
	_create_background()
	_create_collision()
	_create_quantity_label()
	_create_durability_bar()
	_create_rarity_border()


func _setup_materials() -> void:
	# Default slot material (transparent blue)
	default_material = StandardMaterial3D.new()
	default_material.albedo_color = Color(0.2, 0.4, 0.6, 0.3)
	default_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	default_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	# Hover material (bright cyan)
	hover_material = StandardMaterial3D.new()
	hover_material.albedo_color = Color(0.3, 0.8, 1.0, 0.6)
	hover_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hover_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hover_material.emission_enabled = true
	hover_material.emission = Color(0.3, 0.8, 1.0)
	hover_material.emission_energy_multiplier = 0.5

	# Occupied material (green tint)
	occupied_material = StandardMaterial3D.new()
	occupied_material.albedo_color = Color(0.3, 0.7, 0.4, 0.5)
	occupied_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	occupied_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	# Disabled material (gray)
	disabled_material = StandardMaterial3D.new()
	disabled_material.albedo_color = Color(0.3, 0.3, 0.3, 0.2)
	disabled_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	disabled_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED


func _create_background() -> void:
	background = MeshInstance3D.new()
	background.name = "Background"

	var box_mesh := BoxMesh.new()
	box_mesh.size = Vector3(slot_size * 0.95, slot_size * 0.95, slot_size * 0.1)
	background.mesh = box_mesh
	background.material_override = default_material

	add_child(background)


func _create_collision() -> void:
	collision_body = StaticBody3D.new()
	collision_body.name = "CollisionBody"

	var collision_shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(slot_size * 0.95, slot_size * 0.95, slot_size * 0.1)
	collision_shape.shape = box_shape

	collision_body.add_child(collision_shape)
	add_child(collision_body)

	# Store reference to this slot
	collision_body.set_meta("inventory_slot", self)


func _create_quantity_label() -> void:
	quantity_label = Label3D.new()
	quantity_label.name = "QuantityLabel"
	quantity_label.pixel_size = 0.001
	quantity_label.font_size = 24
	quantity_label.outline_size = 2
	quantity_label.modulate = Color.WHITE
	quantity_label.position = Vector3(slot_size * 0.3, -slot_size * 0.3, 0.01)
	quantity_label.visible = false

	add_child(quantity_label)


func _create_durability_bar() -> void:
	durability_bar = MeshInstance3D.new()
	durability_bar.name = "DurabilityBar"

	var bar_mesh := BoxMesh.new()
	bar_mesh.size = Vector3(slot_size * 0.8, slot_size * 0.05, slot_size * 0.05)
	durability_bar.mesh = bar_mesh

	var bar_material := StandardMaterial3D.new()
	bar_material.albedo_color = Color.GREEN
	bar_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	durability_bar.material_override = bar_material

	durability_bar.position = Vector3(0, -slot_size * 0.45, 0.01)
	durability_bar.visible = false

	add_child(durability_bar)


func _create_rarity_border() -> void:
	rarity_border = MeshInstance3D.new()
	rarity_border.name = "RarityBorder"

	# Create a thin frame mesh
	var frame_mesh := BoxMesh.new()
	frame_mesh.size = Vector3(slot_size, slot_size, slot_size * 0.08)
	rarity_border.mesh = frame_mesh

	var border_material := StandardMaterial3D.new()
	border_material.albedo_color = Color.WHITE
	border_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rarity_border.material_override = border_material

	rarity_border.position = Vector3(0, 0, -0.005)
	rarity_border.visible = false

	add_child(rarity_border)


## Set item data and update visuals
func set_item(data: Dictionary) -> void:
	item_data = data.duplicate()
	is_occupied = not item_data.is_empty()

	if is_occupied:
		_show_item()
	else:
		_hide_item()

	_update_visual_state()


## Show item visuals
func _show_item() -> void:
	# Create or update item model
	if item_model == null:
		item_model = MeshInstance3D.new()
		item_model.name = "ItemModel"
		add_child(item_model)

	# Create a simple icon mesh (can be replaced with actual 3D models)
	var icon_mesh := SphereMesh.new()
	icon_mesh.radius = slot_size * 0.3
	icon_mesh.height = slot_size * 0.6
	item_model.mesh = icon_mesh

	# Set color based on item type or rarity
	var item_material := StandardMaterial3D.new()
	item_material.albedo_color = _get_item_color()
	item_material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	item_model.material_override = item_material

	item_model.position = Vector3(0, 0, 0.02)
	item_model.visible = true

	# Update quantity label
	if item_data.has("quantity") and item_data.quantity > 1:
		quantity_label.text = str(item_data.quantity)
		quantity_label.visible = true
	else:
		quantity_label.visible = false

	# Update durability bar
	if item_data.has("durability"):
		var durability_percent: float = item_data.durability
		durability_bar.scale.x = durability_percent

		# Color based on durability
		var bar_material := durability_bar.material_override as StandardMaterial3D
		if durability_percent > 0.5:
			bar_material.albedo_color = Color.GREEN
		elif durability_percent > 0.25:
			bar_material.albedo_color = Color.YELLOW
		else:
			bar_material.albedo_color = Color.RED

		durability_bar.visible = true
	else:
		durability_bar.visible = false

	# Update rarity border
	if item_data.has("rarity"):
		var border_material := rarity_border.material_override as StandardMaterial3D
		border_material.albedo_color = _get_rarity_color(item_data.rarity)
		border_material.emission_enabled = true
		border_material.emission = _get_rarity_color(item_data.rarity)
		border_material.emission_energy_multiplier = 0.3
		rarity_border.visible = true
	else:
		rarity_border.visible = false


## Hide item visuals
func _hide_item() -> void:
	if item_model != null:
		item_model.visible = false
	quantity_label.visible = false
	durability_bar.visible = false
	rarity_border.visible = false


## Get item color based on type
func _get_item_color() -> Color:
	if item_data.has("item_id"):
		var item_id: String = item_data.item_id
		# Simple hash-based coloring
		var hash := item_id.hash()
		var hue := (hash % 360) / 360.0
		return Color.from_hsv(hue, 0.7, 0.9)
	return Color.WHITE


## Get rarity color
func _get_rarity_color(rarity: String) -> Color:
	match rarity.to_lower():
		"common":
			return Color.WHITE
		"uncommon":
			return Color.GREEN
		"rare":
			return Color.BLUE
		"epic":
			return Color.PURPLE
		"legendary":
			return Color.ORANGE
		_:
			return Color.WHITE


## Update visual state based on hover/occupied
func _update_visual_state() -> void:
	if not enabled:
		background.material_override = disabled_material
	elif is_hovered:
		background.material_override = hover_material
	elif is_occupied:
		background.material_override = occupied_material
	else:
		background.material_override = default_material


## Set hover state
func set_hovered(hovered: bool) -> void:
	if is_hovered == hovered:
		return

	is_hovered = hovered
	_update_visual_state()

	if hovered:
		# Pulse animation
		var tween := create_tween()
		tween.set_loops()
		tween.tween_property(background, "scale", Vector3(1.1, 1.1, 1.0), 0.5)
		tween.tween_property(background, "scale", Vector3(1.0, 1.0, 1.0), 0.5)
		tween.set_trans(Tween.TRANS_SINE)
		set_meta("hover_tween", tween)

		slot_hovered.emit(self)
	else:
		# Stop pulse animation
		if has_meta("hover_tween"):
			var tween = get_meta("hover_tween") as Tween
			if tween:
				tween.kill()
			remove_meta("hover_tween")
		background.scale = Vector3.ONE

		slot_unhovered.emit(self)


## Set grabbed state
func set_grabbed(grabbed: bool) -> void:
	is_grabbed = grabbed

	if grabbed:
		# Make semi-transparent when grabbed
		if item_model:
			item_model.transparency = 0.5
		slot_grabbed.emit(self)
	else:
		# Restore opacity
		if item_model:
			item_model.transparency = 0.0
		slot_released.emit(self)


## Get item data
func get_item_data() -> Dictionary:
	return item_data.duplicate()


## Clear slot
func clear() -> void:
	set_item({})


## Check if slot is empty
func is_empty() -> bool:
	return not is_occupied


## Get slot index
func get_slot_index() -> int:
	return slot_index


## Set enabled state
func set_enabled(enable: bool) -> void:
	enabled = enable
	_update_visual_state()
	collision_body.set_deferred("process_mode", Node.PROCESS_MODE_INHERIT if enable else Node.PROCESS_MODE_DISABLED)
