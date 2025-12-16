## SignalManager - Player Health as Signal-to-Noise Ratio
## Manages player health represented as signal coherence, where damage manifests
## as information degradation rather than traditional health loss.
##
## Requirements:
## - 12.1: Reduce SNR when player takes damage
## - 12.2: Calculate SNR using formula signal_strength / (total_noise + 0.001)
## - 12.3: Increase visual glitch effects proportionally with SNR decrease
## - 12.4: Trigger player death when SNR reaches zero
## - 12.5: Apply distance-based signal attenuation using inverse square law
## - 33.1: Render lattice with sharp, bright lines when signal strength is high
## - 33.2: Reduce lattice brightness and increase thickness when signal decreases
## - 33.3: Introduce flickering when signal strength is below 50%
## - 33.4: Use inverse square law based on distance to nearest star node
## - 33.5: Display signal strength percentage in HUD updated every frame
extends Node
class_name SignalManager

## Emitted when SNR changes
signal snr_changed(snr: float, percentage: float)
## Emitted when signal strength changes
signal signal_strength_changed(strength: float)
## Emitted when noise level changes
signal noise_level_changed(noise: float)
## Emitted when entropy level changes
signal entropy_changed(entropy: float)
## Emitted when player dies (SNR reaches zero)
signal player_died()
## Emitted when signal is regenerating
signal signal_regenerating(amount: float)
## Emitted when damage is taken
signal damage_taken(amount: float, source: String)
## Emitted when signal strength is critically low (below 25%)
signal signal_critical(snr_percentage: float)
## Emitted when signal strength is low (below 50%)
signal signal_low(snr_percentage: float)

## Maximum signal strength
@export var max_signal_strength: float = 100.0
## Current signal strength
var signal_strength: float = 100.0

## Current noise level (increases with damage)
var noise_level: float = 0.0

## Current entropy level (affects visual glitches)
## Requirement 12.3: Increase visual glitch effects proportionally
var entropy: float = 0.0

## Maximum SNR value (for percentage calculations)
var max_snr: float = 100.0

## Epsilon value to prevent division by zero
## Requirement 12.2: formula uses (total_noise + 0.001)
const SNR_EPSILON: float = 0.001

## Signal regeneration rate per second (when near star nodes)
@export var base_regeneration_rate: float = 5.0

## Distance-based attenuation parameters
## Requirement 12.5, 33.4: Inverse square law based on distance
@export var attenuation_reference_distance: float = 1000.0
@export var attenuation_coefficient: float = 1.0

## Minimum distance to prevent infinite attenuation
const MIN_ATTENUATION_DISTANCE: float = 10.0

## Distance to nearest star node (updated externally)
var distance_to_nearest_node: float = 0.0

## Whether the player is alive
var _is_alive: bool = true

## Track previous SNR for change detection
var _previous_snr: float = 100.0

## Critical and low thresholds
const CRITICAL_THRESHOLD: float = 0.25  # 25%
const LOW_THRESHOLD: float = 0.50       # 50%

## Track if we've already emitted critical/low signals
var _critical_signal_emitted: bool = false
var _low_signal_emitted: bool = false

## Reference to post-processing for glitch effects
var post_process = null

## Reference to lattice renderer for visual feedback
var lattice_renderer = null


func _ready() -> void:
	# Initialize to full signal strength
	signal_strength = max_signal_strength
	noise_level = 0.0
	entropy = 0.0
	_is_alive = true
	
	# Calculate initial SNR
	_previous_snr = calculate_snr()
	max_snr = _previous_snr
	
	# Try to find rendering systems
	_find_rendering_references()


func _find_rendering_references() -> void:
	"""Find references to rendering systems for visual feedback."""
	var engine_node = get_node_or_null("/root/ResonanceEngine")
	if engine_node:
		if engine_node.has_method("get_post_process"):
			post_process = engine_node.get_post_process()
		if engine_node.has_method("get_lattice_renderer"):
			lattice_renderer = engine_node.get_lattice_renderer()


func _process(delta: float) -> void:
	"""Update signal manager every frame."""
	if not _is_alive:
		return
	
	# Apply distance-based signal attenuation
	# Requirement 12.5, 33.4: Inverse square law
	_apply_distance_attenuation(delta)
	
	# Regenerate signal over time (when conditions are favorable)
	_regenerate_signal(delta)
	
	# Update entropy based on current state
	_update_entropy()
	
	# Calculate current SNR
	var current_snr := calculate_snr()
	
	# Check for death condition
	# Requirement 12.4: Trigger player death when SNR reaches zero
	if current_snr <= 0.0:
		_trigger_death()
		return
	
	# Emit signals for SNR changes
	# Requirement 33.5: Display signal strength percentage updated every frame
	var snr_percentage := get_snr_percentage()
	snr_changed.emit(current_snr, snr_percentage)
	
	# Check for critical/low thresholds
	_check_thresholds(snr_percentage)
	
	# Update visual effects
	# Requirement 12.3, 33.1-33.3: Visual feedback based on signal strength
	_update_visual_effects(snr_percentage)
	
	_previous_snr = current_snr


## Calculate Signal-to-Noise Ratio
## Requirement 12.2: SNR = signal_strength / (total_noise + 0.001)
func calculate_snr() -> float:
	"""Calculate the current Signal-to-Noise Ratio."""
	return signal_strength / (noise_level + SNR_EPSILON)


## Get SNR as a percentage (0.0 to 1.0)
func get_snr_percentage() -> float:
	"""Get SNR as a percentage of maximum."""
	var current_snr := calculate_snr()
	if max_snr <= 0.0:
		return 0.0
	return clampf(current_snr / max_snr, 0.0, 1.0)


## Add noise (damage) to the signal
## Requirement 12.1: Reduce SNR when player takes damage
func add_noise(amount: float, source: String = "unknown") -> void:
	"""Add noise to the signal, reducing SNR."""
	if amount <= 0.0 or not _is_alive:
		return
	
	noise_level += amount
	noise_level = maxf(noise_level, 0.0)
	
	noise_level_changed.emit(noise_level)
	damage_taken.emit(amount, source)


## Take damage (convenience method that adds noise)
## Requirement 12.1: Reduce SNR when player takes damage
func take_damage(amount: float, source: String = "unknown") -> void:
	"""Take damage by adding noise to the signal."""
	add_noise(amount, source)


## Reduce signal strength directly
func reduce_signal(amount: float) -> void:
	"""Reduce signal strength directly."""
	if amount <= 0.0 or not _is_alive:
		return
	
	signal_strength -= amount
	signal_strength = maxf(signal_strength, 0.0)
	
	signal_strength_changed.emit(signal_strength)


## Regenerate signal strength
func regenerate_signal(amount: float) -> void:
	"""Regenerate signal strength."""
	if amount <= 0.0 or not _is_alive:
		return
	
	var old_strength := signal_strength
	signal_strength += amount
	signal_strength = minf(signal_strength, max_signal_strength)
	
	var actual_regen := signal_strength - old_strength
	if actual_regen > 0.0:
		signal_strength_changed.emit(signal_strength)
		signal_regenerating.emit(actual_regen)


## Reduce noise level (healing)
func reduce_noise(amount: float) -> void:
	"""Reduce noise level (healing effect)."""
	if amount <= 0.0 or not _is_alive:
		return
	
	noise_level -= amount
	noise_level = maxf(noise_level, 0.0)
	
	noise_level_changed.emit(noise_level)
	
	# Reset threshold flags if we've recovered
	var snr_percentage := get_snr_percentage()
	if snr_percentage > LOW_THRESHOLD:
		_low_signal_emitted = false
	if snr_percentage > CRITICAL_THRESHOLD:
		_critical_signal_emitted = false


## Set distance to nearest star node (called by external systems)
## Requirement 33.4: Use inverse square law based on distance to nearest star node
func set_distance_to_nearest_node(distance: float) -> void:
	"""Set the distance to the nearest star node."""
	distance_to_nearest_node = maxf(distance, 0.0)


## Apply distance-based signal attenuation
## Requirement 12.5: Apply distance-based signal attenuation using inverse square law
## Requirement 33.4: Use inverse square law based on distance to nearest star node
func _apply_distance_attenuation(delta: float) -> void:
	"""Apply signal attenuation based on distance from star nodes."""
	if distance_to_nearest_node <= MIN_ATTENUATION_DISTANCE:
		return  # No attenuation when very close to a node
	
	# Calculate attenuation using inverse square law
	# attenuation = coefficient * (reference_distance / distance)²
	var distance_ratio := attenuation_reference_distance / distance_to_nearest_node
	var attenuation_factor := attenuation_coefficient * (distance_ratio * distance_ratio)
	
	# Apply attenuation as noise increase over time
	# The further from a node, the more noise accumulates
	var noise_increase := (1.0 - attenuation_factor) * delta * 0.5
	if noise_increase > 0.0:
		noise_level += noise_increase
		noise_level = maxf(noise_level, 0.0)


## Regenerate signal over time
func _regenerate_signal(delta: float) -> void:
	"""Regenerate signal strength over time when near star nodes."""
	# Regeneration is stronger when closer to star nodes
	if distance_to_nearest_node <= 0.0:
		distance_to_nearest_node = attenuation_reference_distance  # Default
	
	# Calculate regeneration rate based on distance
	# Closer to nodes = faster regeneration
	var distance_factor := attenuation_reference_distance / maxf(distance_to_nearest_node, MIN_ATTENUATION_DISTANCE)
	distance_factor = clampf(distance_factor, 0.0, 2.0)  # Cap at 2x regeneration
	
	var regen_rate := base_regeneration_rate * distance_factor * delta
	
	# Regenerate signal strength
	if signal_strength < max_signal_strength:
		regenerate_signal(regen_rate * 0.5)
	
	# Slowly reduce noise over time (natural decay)
	if noise_level > 0.0:
		var noise_decay := regen_rate * 0.3
		reduce_noise(noise_decay)


## Update entropy based on current state
## Requirement 12.3: Increase visual glitch effects proportionally
func _update_entropy() -> void:
	"""Update entropy level based on SNR."""
	var snr_percentage := get_snr_percentage()
	
	# Entropy increases as SNR decreases
	# At 100% SNR, entropy = 0
	# At 0% SNR, entropy = 1
	entropy = 1.0 - snr_percentage
	entropy = clampf(entropy, 0.0, 1.0)
	
	entropy_changed.emit(entropy)


## Check and emit threshold signals
func _check_thresholds(snr_percentage: float) -> void:
	"""Check SNR thresholds and emit appropriate signals."""
	# Check critical threshold (25%)
	if snr_percentage <= CRITICAL_THRESHOLD and not _critical_signal_emitted:
		_critical_signal_emitted = true
		signal_critical.emit(snr_percentage)
	
	# Check low threshold (50%)
	if snr_percentage <= LOW_THRESHOLD and not _low_signal_emitted:
		_low_signal_emitted = true
		signal_low.emit(snr_percentage)


## Update visual effects based on signal strength
## Requirements 12.3, 33.1-33.3
func _update_visual_effects(snr_percentage: float) -> void:
	"""Update visual effects based on signal strength."""
	# Update post-processing glitch effects
	# Requirement 12.3: Increase visual glitch effects proportionally
	if post_process != null and post_process.has_method("set_entropy"):
		post_process.set_entropy(entropy)
	
	# Update lattice renderer
	# Requirement 33.1-33.3: Lattice visual feedback
	if lattice_renderer != null:
		# Requirement 33.1: Sharp, bright lines when signal is high
		# Requirement 33.2: Reduce brightness, increase thickness when signal decreases
		if lattice_renderer.has_method("set_signal_strength"):
			lattice_renderer.set_signal_strength(snr_percentage)
		
		# Requirement 33.3: Introduce flickering below 50%
		if lattice_renderer.has_method("set_flickering"):
			lattice_renderer.set_flickering(snr_percentage < LOW_THRESHOLD)


## Trigger player death
## Requirement 12.4: Trigger player death when SNR reaches zero
func _trigger_death() -> void:
	"""Trigger player death due to signal loss."""
	if not _is_alive:
		return
	
	_is_alive = false
	signal_strength = 0.0
	entropy = 1.0
	
	player_died.emit()
	
	_log_info("Player died - signal lost")


## Check if player is alive
func is_alive() -> bool:
	"""Check if the player is still alive."""
	return _is_alive


## Get current signal strength
func get_signal_strength() -> float:
	"""Get current signal strength."""
	return signal_strength


## Get current noise level
func get_noise_level() -> float:
	"""Get current noise level."""
	return noise_level


## Get current entropy level
func get_entropy() -> float:
	"""Get current entropy level."""
	return entropy


## Get current SNR value
func get_snr() -> float:
	"""Get current SNR value."""
	return calculate_snr()


## Reset to full health
func reset() -> void:
	"""Reset signal manager to full health."""
	signal_strength = max_signal_strength
	noise_level = 0.0
	entropy = 0.0
	_is_alive = true
	_critical_signal_emitted = false
	_low_signal_emitted = false
	_previous_snr = calculate_snr()
	
	signal_strength_changed.emit(signal_strength)
	noise_level_changed.emit(noise_level)
	entropy_changed.emit(entropy)
	snr_changed.emit(calculate_snr(), 1.0)


## Respawn player (reset with partial health)
func respawn(initial_snr_percentage: float = 0.5) -> void:
	"""Respawn player with partial health."""
	signal_strength = max_signal_strength * initial_snr_percentage
	noise_level = max_signal_strength * (1.0 - initial_snr_percentage) * 0.5
	entropy = 1.0 - initial_snr_percentage
	_is_alive = true
	_critical_signal_emitted = false
	_low_signal_emitted = false
	_previous_snr = calculate_snr()
	
	signal_strength_changed.emit(signal_strength)
	noise_level_changed.emit(noise_level)
	entropy_changed.emit(entropy)
	snr_changed.emit(calculate_snr(), get_snr_percentage())


## Get state for saving
func get_state() -> Dictionary:
	"""Get signal manager state for saving."""
	return {
		"signal_strength": signal_strength,
		"noise_level": noise_level,
		"entropy": entropy,
		"is_alive": _is_alive,
		"max_signal_strength": max_signal_strength,
		"distance_to_nearest_node": distance_to_nearest_node
	}


## Set state from loaded data
func set_state(state: Dictionary) -> void:
	"""Set signal manager state from loaded data."""
	if state.has("signal_strength"):
		signal_strength = state.signal_strength
	if state.has("noise_level"):
		noise_level = state.noise_level
	if state.has("entropy"):
		entropy = state.entropy
	if state.has("is_alive"):
		_is_alive = state.is_alive
	if state.has("max_signal_strength"):
		max_signal_strength = state.max_signal_strength
	if state.has("distance_to_nearest_node"):
		distance_to_nearest_node = state.distance_to_nearest_node
	
	_previous_snr = calculate_snr()
	
	# Reset threshold flags based on current state
	var snr_percentage := get_snr_percentage()
	_critical_signal_emitted = snr_percentage <= CRITICAL_THRESHOLD
	_low_signal_emitted = snr_percentage <= LOW_THRESHOLD


## Get statistics for debugging/HUD
## Requirement 33.5: Display signal strength percentage in HUD
func get_statistics() -> Dictionary:
	"""Get signal statistics for debugging or HUD display."""
	return {
		"signal_strength": signal_strength,
		"max_signal_strength": max_signal_strength,
		"noise_level": noise_level,
		"snr": calculate_snr(),
		"snr_percentage": get_snr_percentage(),
		"entropy": entropy,
		"is_alive": _is_alive,
		"distance_to_nearest_node": distance_to_nearest_node,
		"is_critical": get_snr_percentage() <= CRITICAL_THRESHOLD,
		"is_low": get_snr_percentage() <= LOW_THRESHOLD
	}


## Logging helpers

func _log_info(message: String) -> void:
	var engine := get_node_or_null("/root/ResonanceEngine")
	if engine != null and engine.has_method("log_info"):
		engine.log_info("[SignalManager] " + message)
	else:
		print("[INFO] [SignalManager] " + message)


func _log_debug(message: String) -> void:
	var engine := get_node_or_null("/root/ResonanceEngine")
	if engine != null and engine.has_method("log_debug"):
		engine.log_debug("[SignalManager] " + message)
	else:
		print("[DEBUG] [SignalManager] " + message)
