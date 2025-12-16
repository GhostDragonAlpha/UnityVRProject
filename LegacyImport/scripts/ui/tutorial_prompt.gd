extends Control
class_name TutorialPrompt
## Floating tutorial UI element that displays instructions and hints
## Appears as a semi-transparent panel with title, instruction, and hint text

signal skip_requested

## UI Components
@onready var panel: Panel = $Panel
@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var instruction_label: Label = $Panel/VBoxContainer/InstructionLabel
@onready var hint_label: Label = $Panel/VBoxContainer/HintLabel
@onready var progress_bar: ProgressBar = $Panel/VBoxContainer/ProgressBar
@onready var skip_button: Button = $Panel/VBoxContainer/SkipButton

## Animation
var fade_tween: Tween = null
var shake_tween: Tween = null

## Configuration
@export var auto_hide_time: float = 0.0  # 0 = don't auto-hide
@export var fade_duration: float = 0.3
var auto_hide_timer: float = 0.0


func _ready() -> void:
	# Setup UI if not using scene tree nodes
	if not panel:
		_create_ui()

	# Connect skip button
	if skip_button:
		skip_button.pressed.connect(_on_skip_pressed)

	# Start hidden
	modulate.a = 0.0
	visible = false


func _process(delta: float) -> void:
	# Auto-hide timer
	if auto_hide_time > 0.0 and visible and modulate.a > 0.0:
		auto_hide_timer += delta
		if auto_hide_timer >= auto_hide_time:
			hide_prompt()


## Create UI programmatically if not in scene
func _create_ui() -> void:
	# Create panel
	panel = Panel.new()
	panel.name = "Panel"
	add_child(panel)

	# Style panel
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.9)
	style.border_color = Color(0.3, 0.6, 1.0, 1.0)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", style)

	# Set panel size and position
	panel.custom_minimum_size = Vector2(400, 200)
	panel.position = Vector2(20, 20)

	# Create VBoxContainer
	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	panel.add_child(vbox)
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.offset_left = 10
	vbox.offset_right = -10
	vbox.offset_top = 10
	vbox.offset_bottom = -10

	# Create title label
	title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", Color(0.3, 0.6, 1.0))
	vbox.add_child(title_label)

	# Create instruction label
	instruction_label = Label.new()
	instruction_label.name = "InstructionLabel"
	instruction_label.add_theme_font_size_override("font_size", 16)
	instruction_label.add_theme_color_override("font_color", Color.WHITE)
	instruction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(instruction_label)

	# Create hint label
	hint_label = Label.new()
	hint_label.name = "HintLabel"
	hint_label.add_theme_font_size_override("font_size", 14)
	hint_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.6))
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(hint_label)

	# Create progress bar
	progress_bar = ProgressBar.new()
	progress_bar.name = "ProgressBar"
	progress_bar.min_value = 0.0
	progress_bar.max_value = 1.0
	progress_bar.visible = false
	vbox.add_child(progress_bar)

	# Create skip button
	skip_button = Button.new()
	skip_button.name = "SkipButton"
	skip_button.text = "Skip Tutorial (ESC)"
	skip_button.custom_minimum_size = Vector2(0, 30)
	vbox.add_child(skip_button)


## Show tutorial step
func show_tutorial_step(title: String, instruction: String, hint: String = "") -> void:
	if title_label:
		title_label.text = title
	if instruction_label:
		instruction_label.text = instruction
	if hint_label:
		hint_label.text = hint if hint != "" else ""
		hint_label.visible = hint != ""

	auto_hide_timer = 0.0
	show_prompt()


## Show prompt with fade in
func show_prompt() -> void:
	visible = true

	# Cancel existing tween
	if fade_tween:
		fade_tween.kill()

	# Fade in
	fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 1.0, fade_duration)

	# Shake animation for attention
	_play_shake_animation()


## Hide prompt with fade out
func hide_prompt() -> void:
	# Cancel existing tween
	if fade_tween:
		fade_tween.kill()

	# Fade out
	fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	fade_tween.tween_callback(func(): visible = false)


## Play shake animation for attention
func _play_shake_animation() -> void:
	if not panel:
		return

	# Cancel existing shake
	if shake_tween:
		shake_tween.kill()

	var original_position = panel.position

	shake_tween = create_tween()
	shake_tween.set_loops(3)
	shake_tween.tween_property(panel, "position", original_position + Vector2(5, 0), 0.05)
	shake_tween.tween_property(panel, "position", original_position + Vector2(-5, 0), 0.05)
	shake_tween.tween_property(panel, "position", original_position, 0.05)


## Update progress bar
func update_progress(progress: float) -> void:
	if progress_bar:
		progress_bar.visible = progress > 0.0 and progress < 1.0
		progress_bar.value = progress


## Pulse animation for emphasis
func pulse() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.2)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2)


## Signal handlers

func _on_skip_pressed() -> void:
	skip_requested.emit()


## Utility methods

func set_position_preset(preset: int) -> void:
	"""Set position using Control preset constants."""
	match preset:
		0:  # PRESET_TOP_LEFT
			anchor_left = 0.0
			anchor_top = 0.0
			anchor_right = 0.0
			anchor_bottom = 0.0
			offset_left = 20
			offset_top = 20
		1:  # PRESET_TOP_RIGHT
			anchor_left = 1.0
			anchor_top = 0.0
			anchor_right = 1.0
			anchor_bottom = 0.0
			offset_right = -20
			offset_top = 20
		2:  # PRESET_BOTTOM_LEFT
			anchor_left = 0.0
			anchor_top = 1.0
			anchor_right = 0.0
			anchor_bottom = 1.0
			offset_left = 20
			offset_bottom = -20
		3:  # PRESET_BOTTOM_RIGHT
			anchor_left = 1.0
			anchor_top = 1.0
			anchor_right = 1.0
			anchor_bottom = 1.0
			offset_right = -20
			offset_bottom = -20
		8:  # PRESET_CENTER
			anchor_left = 0.5
			anchor_top = 0.5
			anchor_right = 0.5
			anchor_bottom = 0.5
			offset_left = -200
			offset_right = 200
			offset_top = -100
			offset_bottom = 100


func set_auto_hide(time: float) -> void:
	"""Set auto-hide time in seconds. 0 = don't auto-hide."""
	auto_hide_time = time
	auto_hide_timer = 0.0
