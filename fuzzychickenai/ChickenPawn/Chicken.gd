extends CharacterBody2D

#Chicken Stats
@export var speed = 50
var Hunger: int
var Thirst: int
var Fatigue: int

#State Booleans
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
var roaming_radius: float = 500
var target_position: Vector2
var random_angle: float
var random_distance: float



func _ready() -> void:
	ResetVariables()
	
func _physics_process(delta: float) -> void:
	Idle()
	move_and_slide()
	
func ResetVariables() -> void:
	Hunger = 100
	Thirst = 0
	Fatigue = 50

# While the chicken is idling it decides where it's going to move next or roam around
func Idle() -> void:
	is_idling = true
	PrintStats()
	if Hunger < 50:
		is_hungry = true
		is_roaming = false
		target_position = $"../HayField_CollisionPolygon2D2".get_global_transform()
		pass
	elif Fatigue > 90:
		is_tired = true
		is_roaming = false
		target_position = $"../Coupe_CollisionPolygon2D".get_global_transform()
		pass
	elif Thirst > 80:
		is_thirsty = true
		is_roaming = false
		target_position = $"../Lake_CollisionShape2D2".get_global_transform()
		pass
	else:
		roamArea()
		pass
	

func PrintStats() -> void:
	print(Hunger)
	print(Thirst)
	print(Fatigue)
func roamArea() -> void:
	if not is_roaming:
		random_angle = randf_range(0,2*PI)
		random_distance = randf_range(0,roaming_radius)
		
		target_position = position + Vector2(cos(random_angle), sin(random_angle)) * random_distance
#		Potentially clamp to screen so the chicken doesn't wonder OfflineMultiplayerPeer
		is_roaming = true
		
#	Moving Towards the target_position
	var direction = (target_position - position).normalized()
	velocity = direction * speed
#	Checking if we reached the target_position
	if position.distance_to(target_position) < 5.0:
		is_roaming = false
		velocity = Vector2.ZERO
