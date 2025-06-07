extends CharacterBody2D

var isAlive = true

var idle_timer : float = 0.0
var idle_wait_time : float = 0.0
var hasPosition: bool = false
#Chicken Stats
@export_category("Tweaking Stats")
@export var speed = 50
@export var statLossRate = 10.0

@export_category("Stats")
@export var hunger: float
@export var thirst: float
@export var fatigue: float

@export_category("Emotional States")
@export var isHungry: bool
@export var isThirsty: bool
@export var isDrowsy: bool

@export_category("Replenishing Points")
@export var coupe: CollisionShape2D
@export var water: CollisionShape2D
@export var hay: CollisionShape2D
@export var roamingArea: CollisionShape2D

var isRoaming: bool = false
var isIdling: bool = false
var isReturning: bool = false
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
	isRoaming = true
	ResetStats()
	

func _physics_process(delta: float) -> void:
	if isRoaming:
		Roaming()
		move_and_slide()
	if isIdling:
		IdlingForSeconds(delta)
	
	if isHungry:
		MoveTowards(hay)
	if isThirsty: 
		MoveTowards(water)
	if isDrowsy:
		MoveTowards(coupe)
	
	if isReturning:
		MoveTowards(roamingArea)
		isReturning = false

func ResetStats() -> void:
	hunger = 100.0
	thirst = 70.0
	fatigue = 80.0

func PrintStats() -> void:
	print("hunger: ", hunger)
	print("thirst: ", thirst)
	print("fatigue: ", fatigue)
	

func Roaming() -> void:
	if not hasPosition:
		random_angle = randf_range(0,2*PI)
		random_distance = randf_range(0,roaming_radius)
		print("roaming...")
		
		StatLoss()
		
		target_position = position + Vector2(cos(random_angle), sin(random_angle)) * random_distance
#		TODO: Potentially clamp to screen so the chicken doesn't wonder OfflineMultiplayerPeer
		hasPosition = true
	
	var direction = (target_position - position).normalized()
	velocity = direction * speed
	
	if position.distance_to(target_position) < 5.0:
		isRoaming = false
		hasPosition = false
		velocity = Vector2.ZERO
		isIdling = true

func IdlingForSeconds(delta: float):
	if idle_wait_time == 0.0:
		idle_wait_time = randf_range(2.0, 5.0)
		print("Idling... %s seconds" % [idle_wait_time])
	idle_timer += delta
	
	if idle_timer >= idle_wait_time:
		idle_timer = 0.0
		idle_wait_time = 0.0
		isIdling = false
		print("Finished Idling")
		Contemplate()
		if not isHungry or isThirsty or isDrowsy:
			isRoaming = true
		else:
			isRoaming = false
		
func Contemplate() -> void:
	if hunger < 30:
		isHungry = true
		print("I could eat some seed")
		pass
	if thirst < 50:
		isThirsty = true
		print("Water! Give me water!")
		pass
	if fatigue < 10:
		isDrowsy = true
		print("Eeeepy...")
		pass
	PrintStats()

func StatLoss() -> void:
	fatigue -= statLossRate
	hunger -= statLossRate
	thirst -= statLossRate

func MoveTowards(collider: CollisionShape2D):
	if not hasPosition:
		target_position = collider.position
		print("Moving Towards: ", collider.name)
#		TODO: Potentially clamp to screen so the chicken doesn't wonder OfflineMultiplayerPeer
		hasPosition = true
	
	var direction = (target_position - global_position).normalized()
	velocity = direction * speed
	
	if position.distance_to(target_position) < 5.0:
		hasPosition = false
		velocity = Vector2.ZERO
		ReplenishStat(collider)

func ReplenishStat(collider: CollisionShape2D):
	if collider.name == "HayCollider":
		hunger = 100.0
		isHungry = false
		isReturning = true
	elif collider.name == "WaterCollider":
		thirst = 100.0
		isThirsty = false
		isReturning = true
	elif collider.name == "CoupeCollider":
		fatigue = 100.0
		isDrowsy = false
		isReturning = true
	else:
		pass
		
