class_name CreatureAI
extends CharacterBody3D
## AI-controlled creature with behavior tree
##
## Core creature AI controller that uses behavior trees to determine actions.
## Handles movement, combat, detection, and state management.

## Current AI state
enum State {
	IDLE,      ## Standing still, no target
	WANDER,    ## Moving randomly
	CHASE,     ## Pursuing target
	ATTACK,    ## Attacking target
	FLEE,      ## Running away from target
	DEAD       ## Creature is dead
}

## Creature data resource (stats, behavior type)
@export var creature_data: CreatureData

## Current health points
var current_health: float = 100.0

## Current target (usually player)
var current_target: Node3D = null

## Current AI state
var state: State = State.IDLE

## Behavior tree instance
var behavior_tree: BehaviorTree = null

## Attack cooldown timer
var attack_cooldown_remaining: float = 0.0

## Wander timer and target
var wander_timer: float = 0.0
var wander_direction: Vector3 = Vector3.ZERO
var wander_duration: float = 2.0

## Random number generator for wander behavior
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

## Gravity constant
const GRAVITY: float = 9.8

## Navigation avoidance radius
const AVOIDANCE_RADIUS: float = 1.0

## Telemetry tracking
var telemetry_update_timer: float = 0.0
const TELEMETRY_UPDATE_INTERVAL: float = 1.0

signal creature_died(creature: CreatureAI)
signal creature_attacked(target: Node3D, damage: float)
signal creature_damaged(damage: float, source: Node3D)

func _ready():
	"""Initialize creature"""
	if creature_data == null:
		push_error("CreatureAI: No creature_data assigned to %s" % name)
		return

	current_health = creature_data.max_health
	rng.randomize()

	# Create behavior tree based on creature type
	behavior_tree = create_behavior_tree()

	# Add to creatures group for easy access
	add_to_group("creatures")

	# Start with random wander direction
	randomize_wander_direction()

	print("[CreatureAI] Initialized %s (Type: %s)" % [
		creature_data.creature_name,
		CreatureData.CreatureType.keys()[creature_data.creature_type]
	])

func _physics_process(delta: float):
	"""Update AI and physics"""
	if creature_data == null:
		return

	# Update timers
	if attack_cooldown_remaining > 0:
		attack_cooldown_remaining -= delta

	wander_timer -= delta

	# Execute behavior tree
	if behavior_tree and state != State.DEAD:
		behavior_tree.execute(self)

	# Apply gravity
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0

	# Apply movement
	move_and_slide()

	# Update telemetry
	update_telemetry(delta)

func create_behavior_tree() -> BehaviorTree:
	"""Create behavior tree based on creature type"""
	var tree = BehaviorTree.new()

	# Root selector - try behaviors in priority order
	var root = BehaviorTree.create_selector("Root")

	# Behavior 1: If dead, do nothing
	var dead_sequence = BehaviorTree.create_sequence("DeadBehavior")
	dead_sequence.add_child(BehaviorTree.is_dead_condition())
	dead_sequence.add_child(BehaviorTree.do_nothing_action())

	# Behavior 2: Type-specific behavior
	match creature_data.creature_type:
		CreatureData.CreatureType.PASSIVE:
			# Passive: Always flee when player detected
			root.add_child(dead_sequence)
			root.add_child(create_flee_behavior())
			root.add_child(BehaviorTree.wander_action())

		CreatureData.CreatureType.NEUTRAL:
			# Neutral: Only chase/attack if have target (from being attacked)
			root.add_child(dead_sequence)
			root.add_child(create_attack_behavior())
			root.add_child(create_chase_behavior_simple())
			root.add_child(BehaviorTree.wander_action())

		CreatureData.CreatureType.AGGRESSIVE:
			# Aggressive: Detect player, chase, attack
			root.add_child(dead_sequence)
			root.add_child(create_flee_behavior())  # Flee if low health
			root.add_child(create_attack_behavior())
			root.add_child(create_chase_behavior())
			root.add_child(BehaviorTree.wander_action())

		CreatureData.CreatureType.TAMEABLE:
			# Tameable: Similar to neutral but can be tamed (not implemented yet)
			root.add_child(dead_sequence)
			root.add_child(create_attack_behavior())
			root.add_child(create_chase_behavior_simple())
			root.add_child(BehaviorTree.wander_action())

	tree.root = root
	return tree

func create_attack_behavior() -> BehaviorTree.BTNode:
	"""Create attack behavior sequence"""
	var sequence = BehaviorTree.create_sequence("AttackBehavior")

	# Must have target in attack range and be able to attack
	sequence.add_child(BehaviorTree.target_in_range_condition("attack"))
	sequence.add_child(BehaviorTree.can_attack_condition())
	sequence.add_child(BehaviorTree.attack_action())

	return sequence

func create_chase_behavior() -> BehaviorTree.BTNode:
	"""Create chase behavior sequence (with detection)"""
	var sequence = BehaviorTree.create_sequence("ChaseBehavior")

	# Detect player and chase
	sequence.add_child(BehaviorTree.detect_player_action())
	sequence.add_child(BehaviorTree.chase_action())

	return sequence

func create_chase_behavior_simple() -> BehaviorTree.BTNode:
	"""Create chase behavior (without detection, requires existing target)"""
	var sequence = BehaviorTree.create_sequence("ChaseExistingTarget")

	# Check if we have a target
	var has_target = BehaviorTree.create_condition(
		func(c): return c.current_target != null,
		"HasTarget"
	)

	sequence.add_child(has_target)
	sequence.add_child(BehaviorTree.chase_action())

	return sequence

func create_flee_behavior() -> BehaviorTree.BTNode:
	"""Create flee behavior sequence"""
	var sequence = BehaviorTree.create_sequence("FleeBehavior")

	# Flee if health below 30% and have target
	sequence.add_child(BehaviorTree.health_below_threshold_condition(0.3))
	var has_target = BehaviorTree.create_condition(
		func(c): return c.current_target != null,
		"HasTarget"
	)
	sequence.add_child(has_target)
	sequence.add_child(BehaviorTree.flee_action())

	return sequence

## Core AI Actions

func detect_player() -> bool:
	"""Detect player within range and line of sight"""
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return false

	var distance = global_position.distance_to(player.global_position)
	if distance > creature_data.detection_range:
		return false

	# Line of sight check
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		global_position + Vector3(0, 1, 0),  # Start from center
		player.global_position + Vector3(0, 1, 0)
	)
	query.exclude = [self]

	var result = space_state.intersect_ray(query)

	if result:
		# Check if we hit the player or something else
		if result.collider == player or result.collider.is_in_group("player"):
			current_target = player
			return true

	return false

func move_towards_target(target: Node3D):
	"""Move towards target position"""
	if not target:
		return

	var direction = (target.global_position - global_position).normalized()
	direction.y = 0  # Stay on ground plane

	velocity.x = direction.x * creature_data.movement_speed
	velocity.z = direction.z * creature_data.movement_speed

	# Rotate to face target
	if direction.length() > 0.01:
		var target_rotation = atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, 0.1)

func flee_from_target(target: Node3D):
	"""Flee away from target"""
	if not target:
		return

	var direction = (global_position - target.global_position).normalized()
	direction.y = 0

	velocity.x = direction.x * creature_data.movement_speed * 1.5  # Flee faster
	velocity.z = direction.z * creature_data.movement_speed * 1.5

	# Rotate to face away from target
	if direction.length() > 0.01:
		var target_rotation = atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, 0.1)

func wander():
	"""Wander randomly"""
	# Get new direction if timer expired
	if wander_timer <= 0:
		randomize_wander_direction()

	# Apply wander movement
	velocity.x = wander_direction.x * creature_data.movement_speed * 0.5
	velocity.z = wander_direction.z * creature_data.movement_speed * 0.5

	# Rotate to face direction
	if wander_direction.length() > 0.01:
		var target_rotation = atan2(wander_direction.x, wander_direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, 0.05)

func randomize_wander_direction():
	"""Choose new random wander direction"""
	wander_direction = Vector3(
		rng.randf_range(-1.0, 1.0),
		0,
		rng.randf_range(-1.0, 1.0)
	).normalized()
	wander_timer = wander_duration
	wander_duration = rng.randf_range(1.0, 3.0)

func perform_attack():
	"""Execute attack on current target"""
	if not current_target:
		return

	state = State.ATTACK

	# Deal damage to target
	if current_target.has_method("take_damage"):
		current_target.take_damage(creature_data.attack_damage, self)
		creature_attacked.emit(current_target, creature_data.attack_damage)

	# Start cooldown
	attack_cooldown_remaining = creature_data.attack_cooldown

	# TODO: Play attack animation when animation system is available

	print("[CreatureAI] %s attacked %s for %.1f damage" % [
		creature_data.creature_name,
		current_target.name,
		creature_data.attack_damage
	])

func can_attack() -> bool:
	"""Check if attack is off cooldown"""
	return attack_cooldown_remaining <= 0

## Health and Damage

func take_damage(amount: float, source: Node3D = null):
	"""Take damage from source"""
	if state == State.DEAD:
		return

	current_health -= amount
	creature_damaged.emit(amount, source)

	print("[CreatureAI] %s took %.1f damage (%.1f/%.1f HP)" % [
		creature_data.creature_name,
		amount,
		current_health,
		creature_data.max_health
	])

	# TODO: Play hurt animation/sound when available

	# Become aggressive if neutral and not already targeting
	if creature_data.creature_type == CreatureData.CreatureType.NEUTRAL and current_target == null:
		current_target = source
		print("[CreatureAI] %s became aggressive!" % creature_data.creature_name)

	# Set attacker as target if we don't have one
	if source and current_target == null:
		current_target = source

	# Die if health depleted
	if current_health <= 0:
		die()

func heal(amount: float):
	"""Heal creature"""
	current_health = min(current_health + amount, creature_data.max_health)

func die():
	"""Handle creature death"""
	if state == State.DEAD:
		return

	state = State.DEAD
	current_health = 0

	print("[CreatureAI] %s died" % creature_data.creature_name)

	# Disable collision
	collision_layer = 0
	collision_mask = 0

	# Stop movement
	velocity = Vector3.ZERO

	# TODO: Play death animation when available
	# TODO: Spawn loot when loot system is available

	creature_died.emit(self)

	# Remove after delay
	await get_tree().create_timer(5.0).timeout
	queue_free()

## Utility

func get_state_name() -> String:
	"""Get current state as string"""
	return State.keys()[state]

func get_stats() -> Dictionary:
	"""Get current stats as dictionary"""
	return {
		"name": creature_data.creature_name,
		"health": current_health,
		"max_health": creature_data.max_health,
		"health_percent": (current_health / creature_data.max_health) * 100.0,
		"state": get_state_name(),
		"has_target": current_target != null,
		"position": {
			"x": global_position.x,
			"y": global_position.y,
			"z": global_position.z
		},
		"velocity": {
			"x": velocity.x,
			"y": velocity.y,
			"z": velocity.z
		}
	}

func update_telemetry(delta: float):
	"""Send telemetry updates"""
	telemetry_update_timer += delta
	if telemetry_update_timer >= TELEMETRY_UPDATE_INTERVAL:
		telemetry_update_timer = 0.0

		# Send telemetry if TelemetryServer exists
		# Use get_node_or_null to safely check for autoload without script validation errors
		var engine = get_node_or_null("/root/ResonanceEngine")
		if engine and engine.has_node("TelemetryServer"):
			var telemetry = engine.get_node("TelemetryServer")
			if telemetry.has_method("send_event"):
				telemetry.send_event("creature_update", get_stats())
