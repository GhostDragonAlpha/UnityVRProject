extends Control
class_name AchievementNotification
## Displays achievement unlock notifications
## Slides in from side, displays briefly, then slides out

signal notification_completed

## UI Components
@onready var panel: Panel = $Panel
@onready var icon: TextureRect = $Panel/HBoxContainer/Icon
@onready var achievement_label: Label = $Panel/HBoxContainer/VBoxContainer/AchievementLabel
@onready var name_label: Label = $Panel/HBoxContainer/VBoxContainer/NameLabel
@onready var description_label: Label = $Panel/HBoxContainer/VBoxContainer/DescriptionLabel
@onready var points_label: Label = $Panel/HBoxContainer/PointsLabel

## Animation
var slide_tween: Tween = null
var display_duration: float = 3.0
var slide_duration: float = 0.5

## Position
var start_position: Vector2 = Vector2.ZERO
var display_position: Vector2 = Vector2.ZERO
var off_screen_offset: float = 500.0


func _ready() -> void:
	# Setup UI if not using scene tree nodes
	if not panel:
		_create_ui()

	# Start off-screen
	position.x = get_viewport_rect().size.x + off_screen_offset
	visible = false

	# Calculate positions
	_calculate_positions()


## Create UI programmatically
func _create_ui() -> void:
	# Create panel
	panel = Panel.new()
	panel.name = "Panel"
	add_child(panel)

	# Style panel - gold/achievement theme
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.1, 0.0, 0.95)
	style.border_color = Color(1.0, 0.8, 0.0, 1.0)
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", style)

	# Set panel size
	panel.custom_minimum_size = Vector2(400, 100)
	panel.size = Vector2(400, 100)

	# Create HBoxContainer
	var hbox = HBoxContainer.new()
	hbox.name = "HBoxContainer"
	panel.add_child(hbox)
	hbox.anchor_right = 1.0
	hbox.anchor_bottom = 1.0
	hbox.offset_left = 10
	hbox.offset_right = -10
	hbox.offset_top = 10
	hbox.offset_bottom = -10
	hbox.add_theme_constant_override("separation", 10)

	# Create icon
	icon = TextureRect.new()
	icon.name = "Icon"
	icon.custom_minimum_size = Vector2(64, 64)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hbox.add_child(icon)

	# Create VBoxContainer for text
	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)

	# Create achievement label
	achievement_label = Label.new()
	achievement_label.name = "AchievementLabel"
	achievement_label.text = "ACHIEVEMENT UNLOCKED"
	achievement_label.add_theme_font_size_override("font_size", 14)
	achievement_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
	vbox.add_child(achievement_label)

	# Create name label
	name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(name_label)

	# Create description label
	description_label = Label.new()
	description_label.name = "DescriptionLabel"
	description_label.add_theme_font_size_override("font_size", 12)
	description_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(description_label)

	# Create points label
	points_label = Label.new()
	points_label.name = "PointsLabel"
	points_label.add_theme_font_size_override("font_size", 24)
	points_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
	points_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	points_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hbox.add_child(points_label)


## Calculate slide positions
func _calculate_positions() -> void:
	var viewport_size = get_viewport_rect().size
	display_position = Vector2(viewport_size.x - panel.size.x - 20, 20)
	start_position = Vector2(viewport_size.x + off_screen_offset, 20)


## Show achievement notification
func show_achievement(achievement_data: Dictionary) -> void:
	if not achievement_data:
		return

	# Set achievement info
	if name_label:
		name_label.text = achievement_data.get("name", "Achievement")
	if description_label:
		description_label.text = achievement_data.get("description", "")
	if points_label:
		var points = achievement_data.get("points", 0)
		points_label.text = "+%d" % points

	# TODO: Load achievement icon texture
	# if icon and achievement_data.has("icon_path"):
	#     icon.texture = load(achievement_data["icon_path"])

	# Start animation sequence
	_play_animation()


## Play slide-in, display, slide-out animation
func _play_animation() -> void:
	visible = true

	# Cancel existing tween
	if slide_tween:
		slide_tween.kill()

	# Recalculate positions in case viewport changed
	_calculate_positions()

	# Start off-screen
	position = start_position

	# Create animation sequence
	slide_tween = create_tween()

	# Slide in from right
	slide_tween.tween_property(self, "position", display_position, slide_duration)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)

	# Display for duration
	slide_tween.tween_interval(display_duration)

	# Slide out to right
	slide_tween.tween_property(self, "position", start_position, slide_duration)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_IN)

	# Hide and emit completion
	slide_tween.tween_callback(_on_animation_completed)


## Animation completed
func _on_animation_completed() -> void:
	visible = false
	notification_completed.emit()


## Show multiple achievements in sequence
func show_achievement_queue(achievements: Array) -> void:
	if achievements.is_empty():
		return

	var achievement = achievements[0]
	show_achievement(achievement)

	# Wait for completion, then show next
	if achievements.size() > 1:
		await notification_completed
		show_achievement_queue(achievements.slice(1))
