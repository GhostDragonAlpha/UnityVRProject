class_name BehaviorTree
extends Node
## Simple behavior tree implementation for creature AI
##
## Provides a composable behavior tree system with sequences, selectors,
## conditions, and actions. Evaluated each frame to determine AI behavior.

## Behavior tree node types
enum NodeType {
	SEQUENCE,    ## Execute children in order, fail if any fails
	SELECTOR,    ## Try children until one succeeds
	CONDITION,   ## Boolean check
	ACTION       ## Execute action
}

## Individual behavior tree node
class BTNode:
	var node_type: NodeType
	var children: Array = []  ## Array of BTNode (typed arrays don't work with inner classes)
	var condition_func: Callable
	var action_func: Callable
	var node_name: String = ""

	func _init(type: NodeType, name: String = ""):
		node_type = type
		node_name = name

	func execute(creature) -> bool:
		## Execute this node and return success/failure
		match node_type:
			NodeType.SEQUENCE:
				return execute_sequence(creature)
			NodeType.SELECTOR:
				return execute_selector(creature)
			NodeType.CONDITION:
				if condition_func.is_valid():
					return condition_func.call(creature)
				return false
			NodeType.ACTION:
				if action_func.is_valid():
					return action_func.call(creature)
				return false
		return false

	func execute_sequence(creature) -> bool:
		## Execute all children in order, fail if any fails
		for child in children:
			if not child.execute(creature):
				return false
		return true

	func execute_selector(creature) -> bool:
		## Try each child until one succeeds
		for child in children:
			if child.execute(creature):
				return true
		return false

	func add_child(child: BTNode):
		## Add a child node
		children.append(child)

## Root node of the tree
var root: BTNode = null

## Debug mode - prints execution trace
var debug_mode: bool = false

## Last executed node name (for debugging)
var last_executed_node: String = ""

func _init():
	pass

func execute(creature) -> bool:
	## Execute the behavior tree from root
	if root == null:
		push_error("BehaviorTree: No root node set")
		return false

	var result = root.execute(creature)

	if debug_mode:
		print("[BehaviorTree] Executed for %s, result: %s" % [creature.name, result])

	return result

## Helper functions for creating common node patterns

static func create_sequence(name: String = "Sequence") -> BTNode:
	## Create a sequence node
	return BTNode.new(BehaviorTree.NodeType.SEQUENCE, name)

static func create_selector(name: String = "Selector") -> BTNode:
	## Create a selector node
	return BTNode.new(BehaviorTree.NodeType.SELECTOR, name)

static func create_condition(check_func: Callable, name: String = "Condition") -> BTNode:
	## Create a condition node
	var node = BTNode.new(BehaviorTree.NodeType.CONDITION, name)
	node.condition_func = check_func
	return node

static func create_action(do_func: Callable, name: String = "Action") -> BTNode:
	## Create an action node
	var node = BTNode.new(BehaviorTree.NodeType.ACTION, name)
	node.action_func = do_func
	return node

## Predefined common conditions

static func is_dead_condition() -> BTNode:
	## Condition: Creature is dead
	return create_condition(
		func(c): return c.state == c.State.DEAD,
		"IsDead"
	)

static func target_in_range_condition(range_check: String) -> BTNode:
	## Condition: Target is within specified range
	var check_func = func(c):
		if c.current_target == null:
			return false
		var distance = c.global_position.distance_to(c.current_target.global_position)
		match range_check:
			"attack":
				return distance < c.creature_data.attack_range
			"detection":
				return distance < c.creature_data.detection_range
			_:
				return false
	return create_condition(check_func, "TargetInRange(%s)" % range_check)

static func health_below_threshold_condition(threshold: float) -> BTNode:
	## Condition: Health is below threshold percentage
	var check_func = func(c):
		var health_percent = c.current_health / c.creature_data.max_health
		return health_percent < threshold
	return create_condition(check_func, "HealthBelow(%d%%)" % (threshold * 100))

static func can_attack_condition() -> BTNode:
	## Condition: Can perform attack (cooldown ready)
	return create_condition(
		func(c): return c.can_attack(),
		"CanAttack"
	)

## Predefined common actions

static func do_nothing_action() -> BTNode:
	## Action: Do nothing (for dead state)
	return create_action(
		func(c): return true,
		"DoNothing"
	)

static func attack_action() -> BTNode:
	## Action: Perform attack
	var action_func = func(c):
		c.perform_attack()
		return true
	return create_action(action_func, "Attack")

static func chase_action() -> BTNode:
	## Action: Chase current target
	var action_func = func(c):
		if c.current_target:
			c.move_towards_target(c.current_target)
			c.state = c.State.CHASE
			return true
		return false
	return create_action(action_func, "Chase")

static func flee_action() -> BTNode:
	## Action: Flee from current target
	var action_func = func(c):
		if c.current_target:
			c.flee_from_target(c.current_target)
			c.state = c.State.FLEE
			return true
		return false
	return create_action(action_func, "Flee")

static func wander_action() -> BTNode:
	## Action: Wander randomly
	var action_func = func(c):
		c.wander()
		c.state = c.State.WANDER
		return true
	return create_action(action_func, "Wander")

static func detect_player_action() -> BTNode:
	## Action: Attempt to detect player
	var action_func = func(c):
		return c.detect_player()
	return create_action(action_func, "DetectPlayer")
