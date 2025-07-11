extends CharacterBody2D

#States
var isRoaming: bool = false
var isIdling: bool = false
var isReturning: bool = false
var isReplenishing: bool = false

#Movement and state variables
var hasPosition: bool = false
var target_position: Vector2
var idle_timer : float = 0.0
var idle_wait_time : float = 0.0
var current_target: CollisionShape2D = null

@export_category("Tweaking Stats")
@export var speed = 50
@export var statLossRate = 10.0

@export_category("Stats")
@export var hunger: float
@export var thirst: float
@export var fatigue: float

@export var isHungry: bool
@export var isThirsty: bool
@export var isDrowsy: bool

@export_category("Scene References")
@export var coops: Array[CollisionShape2D]
@export var water_sources: Array[CollisionShape2D]
@export var hay_piles: Array[CollisionShape2D]

@export var roamingArea: CollisionShape2D
@export var messageLabel: RichTextLabel


func _ready() -> void:
	isRoaming = true
	RandomizeStats()

func _physics_process(delta: float) -> void:
	if isReplenishing:
		velocity = Vector2.ZERO
	elif isReturning:
		ReturningToRoamArea()
	elif isHungry:
		if not current_target:
			current_target = _get_random_target_from_array(hay_piles)

		if current_target:
			MoveTowards(current_target)
			
	elif isThirsty:
		if not current_target:
			current_target = _get_random_target_from_array(water_sources)
		
		if current_target:
			MoveTowards(current_target)
	elif isDrowsy:
		if not current_target:
			current_target = _get_random_target_from_array(coops)

		if current_target:
			MoveTowards(current_target)
			
	elif isRoaming:
		Roaming()
	elif isIdling:
		IdlingForSeconds(delta)
	else:
		velocity = Vector2.ZERO

	move_and_slide()


func _get_random_target_from_array(targets: Array[CollisionShape2D]) -> CollisionShape2D:
	if targets.is_empty():
		return null

	return targets.pick_random()


func Roaming() -> void:
	if not hasPosition:
		var roaming_radius: float = 150
		var random_angle = randf_range(0, 2 * PI)
		var random_distance = randf_range(50, roaming_radius)
		
		messageLabel.text = "I'm roaming so hard right now"
		print("Roaming...")
		
		StatLoss()
		
		var potential_target = position + Vector2(cos(random_angle), sin(random_angle)) * random_distance
		target_position = _get_point_clamped_to_area(potential_target, roamingArea)
		hasPosition = true
	
	var direction = (target_position - position).normalized()
	velocity = direction * speed
	
	if position.distance_to(target_position) < 5.0:
		isRoaming = false
		hasPosition = false
		isIdling = true

func ReturningToRoamArea():
	if not hasPosition:
		target_position = _get_random_point_in_area(roamingArea)
		hasPosition = true
		messageLabel.text = "Heading back to my area..."
		print("Returning to roaming area...")

	var direction = (target_position - global_position).normalized()
	velocity = direction * speed

	if global_position.distance_to(target_position) < 5.0:
		isReturning = false
		hasPosition = false
		isIdling = true

func IdlingForSeconds(delta: float):
	velocity = Vector2.ZERO
	if idle_wait_time == 0.0:
		idle_wait_time = randf_range(2.0, 5.0)
		messageLabel.text = "[shake rate=20.0 level=10]Brain Noise[/shake]"
		print("Idling for %s seconds..." % [idle_wait_time])
		
	idle_timer += delta
	
	if idle_timer >= idle_wait_time:
		idle_timer = 0.0
		idle_wait_time = 0.0
		isIdling = false
		print("Finished Idling")
		Contemplate()
		if not (isHungry or isThirsty or isDrowsy):
			isRoaming = true

func MoveTowards(collider: CollisionShape2D):
	if not hasPosition:
		target_position = collider.global_position
		print("Moving Towards: ", collider.get_parent().name)
		hasPosition = true
	
	var direction = (target_position - global_position).normalized()
	velocity = direction * speed
	
	if global_position.distance_to(target_position) < 5.0:
		hasPosition = false
		velocity = Vector2.ZERO
		_start_replenishing(collider)

func _start_replenishing(collider: CollisionShape2D) -> void:
	isReplenishing = true
	isRoaming = false
	
	var action_verb = "interacting"
	var parent_name = _get_base_name(collider.name)
	if "HayCollider" in parent_name: action_verb = "eating"
	elif "WaterCollider" in parent_name: action_verb = "drinking"
	elif "CoupeCollider" in parent_name: action_verb = "sleeping"
	
	messageLabel.text = "[wave amp=50.0]I'm %s now[/wave]" % action_verb
	print("Chicken is now %s for 3 seconds..." % action_verb)

	await get_tree().create_timer(3.0).timeout
	
	print("... finished %s." % action_verb)
	
	ReplenishStat(collider)
	
	isReplenishing = false
	isReturning = true

func Contemplate() -> void:
	if fatigue < 10:
		isDrowsy = true
		messageLabel.text = "Eeeepy..."
	elif hunger < 30:
		isHungry = true
		messageLabel.text = "I could eat some seed"
	elif thirst < 50:
		isThirsty = true
		messageLabel.text = "Water! Give me water!"
	PrintStats()

func ReplenishStat(collider: CollisionShape2D):
	var parent_name = collider.get_parent().name
	if "Hay" in parent_name:
		hunger = 100.0
		isHungry = false
	elif "Water" in parent_name:
		thirst = 100.0
		isThirsty = false
	elif "Coupe" in parent_name:
		fatigue = 100.0
		isDrowsy = false
		
	current_target = null

func StatLoss() -> void:
	fatigue -= statLossRate
	hunger -= statLossRate
	thirst -= statLossRate

func _get_random_point_in_area(area_shape: CollisionShape2D) -> Vector2:
	var rect: RectangleShape2D = area_shape.shape
	var rect_size = rect.size
	
	var random_x = randf_range(-rect_size.x / 2.0, rect_size.x / 2.0)
	var random_y = randf_range(-rect_size.y / 2.0, rect_size.y / 2.0)
	
	var local_point = Vector2(random_x, random_y)
	return area_shape.global_transform * local_point

func _get_point_clamped_to_area(point: Vector2, area_shape: CollisionShape2D) -> Vector2:
	if not area_shape.shape is RectangleShape2D:
		return point

	var rect: RectangleShape2D = area_shape.shape
	var rect_extents = rect.size / 2.0
	
	var local_point = area_shape.global_transform.affine_inverse() * point
	
	local_point.x = clamp(local_point.x, -rect_extents.x, rect_extents.x)
	local_point.y = clamp(local_point.y, -rect_extents.y, rect_extents.y)
	
	return area_shape.global_transform * local_point

func _get_base_name(full_name: String) -> String:
	var base_name = full_name
	while not base_name.is_empty() and base_name.right(1).is_valid_int():
		base_name = base_name.left(base_name.length() - 1)
	return base_name

func RandomizeStats() -> void:
	hunger = randf_range(20.0, 100.0)
	thirst = randf_range(20.0, 100.0)
	fatigue = randf_range(20.0, 100.0)

func PrintStats() -> void:
	print("hunger: ", hunger, " thirst: ", thirst, " fatigue: ", fatigue)
