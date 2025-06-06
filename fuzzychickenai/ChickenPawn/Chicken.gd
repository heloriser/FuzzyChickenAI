extends CharacterBody2D

var isAlive = true

var idle_timer : float = 0.0
var idle_wait_time : float = 0.0
var hasPosition: bool = false
#Chicken Stats
@export_category("Tweaking Stats")
@export var speed = 50
@export var statLossRate = 0.1

@export_category("Stats")
@export var hunger: int
@export var thirst: int
@export var fatigue: int

@export_category("Emotional States")
@export var isHungry: bool
@export var isThirsty: bool
@export var isDrousy: bool

var is_roaming: bool = false
var is_idling: bool = false
var is_traveling: bool = false
var is_sleeping: bool = false
var is_eating: bool = false
var is_drinking: bool = false

#Chickens States
var is_hungry: bool = false
var is_tired: bool = false
var is_thirsty: bool = false

#Movement variables
var roaming_radius: float = 800
var target_position: Vector2
var random_angle: float
var random_distance: float



func _ready() -> void:
	is_roaming = true
	
	

#also a decission making method
func _physics_process(delta: float) -> void:
	if is_roaming:
		Roaming()
		move_and_slide()
	if is_idling:
		IdlingForSeconds(delta)
	
	
	
	
	
# While the chicken is idling it decides where it's going to move next or roam around
func Idle() -> void:
	is_idling = true
	PrintStats()
	if hunger < 50:
		is_hungry = true
		is_roaming = false
		target_position = position + Vector2(cos(random_angle), sin(random_angle)) * random_distance
		
		
		pass
	elif fatigue > 90:
		is_tired = true
		is_roaming = false
		target_position = $"../Coupe_CollisionPolygon2D".get_global_transform()
		pass
	elif thirst > 80:
		is_thirsty = true
		is_roaming = false
		target_position = $"../Lake_CollisionShape2D2".get_global_transform()
		pass
		
	await get_tree().create_timer(3).timeout
	is_idling = false
	

func PrintStats() -> void:
	print(hunger)
	print(thirst)
	print(fatigue)

func Roaming() -> void:
	if not hasPosition:
		random_angle = randf_range(0,2*PI)
		random_distance = randf_range(0,roaming_radius)
		
		target_position = position + Vector2(cos(random_angle), sin(random_angle)) * random_distance
#		TODO: Potentially clamp to screen so the chicken doesn't wonder OfflineMultiplayerPeer
		hasPosition = true
	
	var direction = (target_position - position).normalized()
	velocity = direction * speed
	
	if position.distance_to(target_position) < 5.0:
		is_roaming = false
		hasPosition = false
		velocity = Vector2.ZERO
		PrintStats()
		is_idling = true

func IdlingForSeconds(delta: float):
	if idle_wait_time == 0.0:
		idle_wait_time = randf_range(2.0, 5.0)
		print("Idling... %s seconds" % [idle_wait_time])
	idle_timer += delta
	
	if idle_timer >= idle_wait_time:
		idle_timer = 0.0
		idle_wait_time = 0.0
		is_idling = false
		print("Finished Idling")
		PrintStats()
		is_roaming = true
		
	
	
	
	
	
	
	
