extends Control
class_name MenuSystem

## MenuSystem - Main menu and settings management
## Handles main menu, settings, save/load interface, pause menu, and performance metrics
## Requirements: 38.1, 38.2, 38.3, 38.4, 50.1, 50.2, 50.3, 50.4, 50.5

signal menu_action(action: String)
signal settings_changed(setting_name: String, value: Variant)
signal save_selected(save_slot: int)
signal load_selected(save_slot: int)

enum MenuState {
	MAIN_MENU,
	SETTINGS,
	SAVE_LOAD,
	PAUSE,
	PERFORMANCE
}

# Menu state
var current_state: MenuState = MenuState.MAIN_MENU
var is_paused: bool = false

# UI Containers
@onready var main_menu_container: VBoxContainer
@onready var settings_container: VBoxContainer
@onready var save_load_container: VBoxContainer
@onready var pause_container: VBoxContainer
@onready var performance_container: VBoxContainer

# Settings
var graphics_quality: String = "High"  # Low, Medium, High, Ultra
var audio_volume: float = 1.0
var control_mappings: Dictionary = {}

# Save slots
const MAX_SAVE_SLOTS = 10
var save_metadata: Array[Dictionary] = []

func _ready() -> void:
	initialize_ui()
	initialize_ui()
	# Settings are loaded by SettingsManager on startup
	_sync_ui_with_settings()
	refresh_save_metadata()
	hide_all_menus()
	show_menu(MenuState.MAIN_MENU)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if current_state == MenuState.PAUSE:
			resume_game()
		elif not is_paused:
			pause_game()

func initialize_ui() -> void:
	"""Initialize all UI containers and buttons"""
	# Create main menu
	main_menu_container = create_main_menu()
	add_child(main_menu_container)
	
	# Create settings menu
	settings_container = create_settings_menu()
	add_child(settings_container)
	
	# Create save/load interface
	save_load_container = create_save_load_menu()
	add_child(save_load_container)
	
	# Create pause menu
	pause_container = create_pause_menu()
	add_child(pause_container)
	
	# Create performance metrics display
	performance_container = create_performance_display()
	add_child(performance_container)

func create_main_menu() -> VBoxContainer:
	"""Create main menu with New Game, Load, Settings, Quit"""
	var container = VBoxContainer.new()
	container.name = "MainMenu"
	container.anchor_left = 0.5
	container.anchor_top = 0.5
	container.anchor_right = 0.5
	container.anchor_bottom = 0.5
	container.offset_left = -150
	container.offset_top = -200
	container.offset_right = 150
	container.offset_bottom = 200
	
	var title = Label.new()
	title.text = "PROJECT RESONANCE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(title)
	
	var new_game_btn = Button.new()
	new_game_btn.text = "New Game"
	new_game_btn.pressed.connect(_on_new_game_pressed)
	container.add_child(new_game_btn)
	
	var load_btn = Button.new()
	load_btn.text = "Load Game"
	load_btn.pressed.connect(_on_load_menu_pressed)
	container.add_child(load_btn)
	
	var settings_btn = Button.new()
	settings_btn.text = "Settings"
	settings_btn.pressed.connect(_on_settings_pressed)
	container.add_child(settings_btn)
	
	var quit_btn = Button.new()
	quit_btn.text = "Quit"
	quit_btn.pressed.connect(_on_quit_pressed)
	container.add_child(quit_btn)
	
	return container

func create_settings_menu() -> VBoxContainer:
	"""Create settings menu with graphics, audio, controls"""
	var container = VBoxContainer.new()
	container.name = "SettingsMenu"
	container.anchor_left = 0.5
	container.anchor_top = 0.5
	container.anchor_right = 0.5
	container.anchor_bottom = 0.5
	container.offset_left = -200
	container.offset_top = -250
	container.offset_right = 200
	container.offset_bottom = 250
	
	var title = Label.new()
	title.text = "SETTINGS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(title)
	
	# Graphics quality preset
	var graphics_label = Label.new()
	graphics_label.text = "Graphics Quality:"
	container.add_child(graphics_label)
	
	var graphics_option = OptionButton.new()
	graphics_option.add_item("Low")
	graphics_option.add_item("Medium")
	graphics_option.add_item("High")
	graphics_option.add_item("Ultra")
	graphics_option.selected = 2  # Default to High
	graphics_option.item_selected.connect(_on_graphics_quality_changed)
	container.add_child(graphics_option)
	
	# Lattice density control
	var lattice_label = Label.new()
	lattice_label.text = "Lattice Density:"
	container.add_child(lattice_label)
	
	var lattice_slider = HSlider.new()
	lattice_slider.min_value = 1.0
	lattice_slider.max_value = 20.0
	lattice_slider.value = 10.0
	lattice_slider.value_changed.connect(_on_lattice_density_changed)
	container.add_child(lattice_slider)
	
	# LOD distance control
	var lod_label = Label.new()
	lod_label.text = "LOD Distance:"
	container.add_child(lod_label)
	
	var lod_slider = HSlider.new()
	lod_slider.min_value = 100.0
	lod_slider.max_value = 10000.0
	lod_slider.value = 1000.0
	lod_slider.value_changed.connect(_on_lod_distance_changed)
	container.add_child(lod_slider)
	
	# Audio volume
	var audio_label = Label.new()
	audio_label.text = "Audio Volume:"
	container.add_child(audio_label)
	
	var audio_slider = HSlider.new()
	audio_slider.min_value = 0.0
	audio_slider.max_value = 1.0
	audio_slider.value = 1.0
	audio_slider.value_changed.connect(_on_audio_volume_changed)
	container.add_child(audio_slider)
	
	# Back button
	var back_btn = Button.new()
	back_btn.text = "Back"
	back_btn.pressed.connect(_on_settings_back_pressed)
	container.add_child(back_btn)
	
	return container

func create_save_load_menu() -> VBoxContainer:
	"""Create save/load interface with metadata display"""
	var container = VBoxContainer.new()
	container.name = "SaveLoadMenu"
	container.anchor_left = 0.5
	container.anchor_top = 0.5
	container.anchor_right = 0.5
	container.anchor_bottom = 0.5
	container.offset_left = -250
	container.offset_top = -300
	container.offset_right = 250
	container.offset_bottom = 300
	
	var title = Label.new()
	title.text = "LOAD GAME"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(title)
	
	# Scroll container for save slots
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(400, 400)
	container.add_child(scroll)
	
	var slots_container = VBoxContainer.new()
	slots_container.name = "SlotsContainer"
	scroll.add_child(slots_container)
	
	# Create save slot buttons
	for i in range(MAX_SAVE_SLOTS):
		var slot_btn = Button.new()
		slot_btn.text = "Slot %d: Empty" % (i + 1)
		slot_btn.custom_minimum_size = Vector2(380, 60)
		slot_btn.pressed.connect(_on_save_slot_pressed.bind(i))
		slots_container.add_child(slot_btn)
	
	# Back button
	var back_btn = Button.new()
	back_btn.text = "Back"
	back_btn.pressed.connect(_on_save_load_back_pressed)
	container.add_child(back_btn)
	
	return container

func create_pause_menu() -> VBoxContainer:
	"""Create pause menu"""
	var container = VBoxContainer.new()
	container.name = "PauseMenu"
	container.anchor_left = 0.5
	container.anchor_top = 0.5
	container.anchor_right = 0.5
	container.anchor_bottom = 0.5
	container.offset_left = -150
	container.offset_top = -150
	container.offset_right = 150
	container.offset_bottom = 150
	
	var title = Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(title)
	
	var resume_btn = Button.new()
	resume_btn.text = "Resume"
	resume_btn.pressed.connect(_on_resume_pressed)
	container.add_child(resume_btn)
	
	var save_btn = Button.new()
	save_btn.text = "Save Game"
	save_btn.pressed.connect(_on_save_game_pressed)
	container.add_child(save_btn)
	
	var settings_btn = Button.new()
	settings_btn.text = "Settings"
	settings_btn.pressed.connect(_on_settings_pressed)
	container.add_child(settings_btn)
	
	var main_menu_btn = Button.new()
	main_menu_btn.text = "Main Menu"
	main_menu_btn.pressed.connect(_on_main_menu_pressed)
	container.add_child(main_menu_btn)
	
	return container

func create_performance_display() -> VBoxContainer:
	"""Create performance metrics display using Performance singleton"""
	var container = VBoxContainer.new()
	container.name = "PerformanceDisplay"
	container.anchor_left = 0.0
	container.anchor_top = 0.0
	container.offset_left = 10
	container.offset_top = 10
	container.offset_right = 300
	container.offset_bottom = 200
	
	var title = Label.new()
	title.text = "Performance Metrics"
	container.add_child(title)
	
	var fps_label = Label.new()
	fps_label.name = "FPSLabel"
	fps_label.text = "FPS: 0"
	container.add_child(fps_label)
	
	var frame_time_label = Label.new()
	frame_time_label.name = "FrameTimeLabel"
	frame_time_label.text = "Frame Time: 0 ms"
	container.add_child(frame_time_label)
	
	var gpu_label = Label.new()
	gpu_label.name = "GPULabel"
	gpu_label.text = "GPU Usage: 0%"
	container.add_child(gpu_label)
	
	var memory_label = Label.new()
	memory_label.name = "MemoryLabel"
	memory_label.text = "Memory: 0 MB"
	container.add_child(memory_label)
	
	return container

func _process(_delta: float) -> void:
	"""Update performance metrics if display is visible"""
	if performance_container and performance_container.visible:
		update_performance_metrics()

func update_performance_metrics() -> void:
	"""Update real-time performance metrics using Performance singleton"""
	var fps = Engine.get_frames_per_second()
	var frame_time = Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	var memory = Performance.get_monitor(Performance.MEMORY_STATIC) / 1024.0 / 1024.0
	
	var fps_label = performance_container.get_node("FPSLabel")
	var frame_time_label = performance_container.get_node("FrameTimeLabel")
	var memory_label = performance_container.get_node("MemoryLabel")
	
	if fps_label:
		fps_label.text = "FPS: %d" % fps
	if frame_time_label:
		frame_time_label.text = "Frame Time: %.2f ms" % frame_time
	if memory_label:
		memory_label.text = "Memory: %.1f MB" % memory

# Menu navigation functions
func show_menu(state: MenuState) -> void:
	"""Show specific menu and hide others"""
	hide_all_menus()
	current_state = state
	
	match state:
		MenuState.MAIN_MENU:
			main_menu_container.visible = true
		MenuState.SETTINGS:
			settings_container.visible = true
		MenuState.SAVE_LOAD:
			save_load_container.visible = true
			refresh_save_slots()
		MenuState.PAUSE:
			pause_container.visible = true
		MenuState.PERFORMANCE:
			performance_container.visible = true

func hide_all_menus() -> void:
	"""Hide all menu containers"""
	if main_menu_container:
		main_menu_container.visible = false
	if settings_container:
		settings_container.visible = false
	if save_load_container:
		save_load_container.visible = false
	if pause_container:
		pause_container.visible = false
	if performance_container:
		performance_container.visible = false

func pause_game() -> void:
	"""Pause the game and show pause menu"""
	is_paused = true
	get_tree().paused = true
	show_menu(MenuState.PAUSE)
	menu_action.emit("pause")

func resume_game() -> void:
	"""Resume the game from pause"""
	is_paused = false
	get_tree().paused = false
	hide_all_menus()
	menu_action.emit("resume")

func toggle_performance_display() -> void:
	"""Toggle performance metrics display"""
	if performance_container:
		performance_container.visible = not performance_container.visible

# Settings management
func _sync_ui_with_settings() -> void:
	"""Sync UI elements with current settings"""
	var settings = _get_settings_manager()
	if not settings:
		return
		
	# Graphics
	graphics_quality = settings.get_setting("graphics", "quality", "High")
	# Update option button selection... (simplified for now)
	
	# Audio
	audio_volume = settings.get_setting("audio", "master_volume", 1.0)
	
	# Update sliders if they exist
	if settings_container:
		# Find and update sliders...
		pass

func _get_settings_manager() -> Node:
	if has_node("/root/ResonanceEngine"):
		return get_node("/root/ResonanceEngine").get_settings_manager()
	return null

func _get_save_system() -> Node:
	if has_node("/root/ResonanceEngine"):
		return get_node("/root/ResonanceEngine").save_system
	return null

func apply_graphics_preset(preset: String) -> void:
	"""Apply graphics quality preset"""
	graphics_quality = preset
	
	var settings = _get_settings_manager()
	if settings:
		settings.set_setting("graphics", "quality", preset)
		
		match preset:
			"Low":
				settings.set_setting("graphics", "lattice_density", 5.0)
				settings.set_setting("graphics", "lod_distance", 500.0)
				settings.set_setting("graphics", "shadow_quality", 0)
			"Medium":
				settings.set_setting("graphics", "lattice_density", 8.0)
				settings.set_setting("graphics", "lod_distance", 1000.0)
				settings.set_setting("graphics", "shadow_quality", 1)
			"High":
				settings.set_setting("graphics", "lattice_density", 10.0)
				settings.set_setting("graphics", "lod_distance", 2000.0)
				settings.set_setting("graphics", "shadow_quality", 2)
			"Ultra":
				settings.set_setting("graphics", "lattice_density", 15.0)
				settings.set_setting("graphics", "lod_distance", 5000.0)
				settings.set_setting("graphics", "shadow_quality", 3)
		
		settings.save_settings()

# Save/Load management
func refresh_save_metadata() -> void:
	"""Refresh save file metadata"""
	var save_sys = _get_save_system()
	if save_sys:
		save_metadata = save_sys.get_all_save_metadata()
	else:
		save_metadata.clear()
		for i in range(MAX_SAVE_SLOTS):
			save_metadata.append({"exists": false})

func refresh_save_slots() -> void:
	"""Update save slot button text with metadata"""
	refresh_save_metadata()
	
	var slots_container = save_load_container.get_node("ScrollContainer/SlotsContainer")
	if not slots_container:
		return
	
	for i in range(MAX_SAVE_SLOTS):
		var btn = slots_container.get_child(i) as Button
		if not btn:
			continue
		
		var metadata = save_metadata[i]
		if metadata.get("exists", false):
			var location = metadata.get("location", Vector3.ZERO)
			var time = metadata.get("simulation_time", 0.0)
			btn.text = "Slot %d: Position (%.1f, %.1f, %.1f) - Time: %.1f" % [
				i + 1, location.x, location.y, location.z, time
			]
		else:
			btn.text = "Slot %d: Empty" % (i + 1)

# Button callbacks
func _on_new_game_pressed() -> void:
	menu_action.emit("new_game")
	hide_all_menus()

func _on_load_menu_pressed() -> void:
	show_menu(MenuState.SAVE_LOAD)

func _on_settings_pressed() -> void:
	show_menu(MenuState.SETTINGS)

func _on_quit_pressed() -> void:
	menu_action.emit("quit")
	get_tree().quit()

func _on_resume_pressed() -> void:
	resume_game()

func _on_save_game_pressed() -> void:
	menu_action.emit("save_game")
	# Show save slot selection
	show_menu(MenuState.SAVE_LOAD)

func _on_main_menu_pressed() -> void:
	resume_game()
	show_menu(MenuState.MAIN_MENU)

func _on_settings_back_pressed() -> void:
	if is_paused:
		show_menu(MenuState.PAUSE)
	else:
		show_menu(MenuState.MAIN_MENU)

func _on_save_load_back_pressed() -> void:
	if is_paused:
		show_menu(MenuState.PAUSE)
	else:
		show_menu(MenuState.MAIN_MENU)

func _on_save_slot_pressed(slot: int) -> void:
	var save_sys = _get_save_system()
	if not save_sys:
		return

	if is_paused:
		# Save to this slot
		if save_sys.save_game(slot):
			save_selected.emit(slot)
			menu_action.emit("save_to_slot_%d" % slot)
			refresh_save_slots() # Refresh to show new save
	else:
		# Load from this slot
		if save_metadata[slot].get("exists", false):
			if save_sys.load_game(slot):
				load_selected.emit(slot)
				menu_action.emit("load_from_slot_%d" % slot)
				hide_all_menus()

# Settings callbacks
func _on_graphics_quality_changed(index: int) -> void:
	var presets = ["Low", "Medium", "High", "Ultra"]
	apply_graphics_preset(presets[index])

func _on_lattice_density_changed(value: float) -> void:
	var settings = _get_settings_manager()
	if settings:
		settings.set_setting("graphics", "lattice_density", value)
		settings.save_settings()
	settings_changed.emit("lattice_density", value)

func _on_lod_distance_changed(value: float) -> void:
	var settings = _get_settings_manager()
	if settings:
		settings.set_setting("graphics", "lod_distance", value)
		settings.save_settings()
	settings_changed.emit("lod_distance", value)

func _on_audio_volume_changed(value: float) -> void:
	audio_volume = value
	var settings = _get_settings_manager()
	if settings:
		settings.set_setting("audio", "master_volume", value)
		settings.save_settings()
	settings_changed.emit("audio_volume", value)


## Show main menu
func show_main_menu() -> void:
	"""Display main menu."""
	show_menu(MenuState.MAIN_MENU)
	print("MenuSystem: Showed main menu")


## Show settings menu
func show_settings_menu() -> void:
	"""Display settings menu."""
	show_menu(MenuState.SETTINGS)
	print("MenuSystem: Showed settings menu")


## Show save/load menu
func show_save_load_menu() -> void:
	"""Display save/load menu."""
	show_menu(MenuState.SAVE_LOAD)
	refresh_save_slots()
	print("MenuSystem: Showed save/load menu")


## Show pause menu
func show_pause_menu() -> void:
	"""Display pause menu."""
	show_menu(MenuState.PAUSE)
	print("MenuSystem: Showed pause menu")


## Show performance metrics
func show_performance_metrics() -> void:
	"""Display performance metrics."""
	show_menu(MenuState.PERFORMANCE)
	print("MenuSystem: Showed performance metrics")


## Navigate to specific menu path
func navigate_to(menu_path: String) -> void:
	"""Navigate to specific menu path."""
	match menu_path:
		"main":
			show_main_menu()
		"settings":
			show_settings_menu()
		"save_load":
			show_save_load_menu()
		"pause":
			show_pause_menu()
		"performance":
			show_performance_metrics()
		_:
			print("MenuSystem: Unknown menu path - %s" % menu_path)
	
	print("MenuSystem: Navigated to %s" % menu_path)
