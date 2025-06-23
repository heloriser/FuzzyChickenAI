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

@export var messageLabel: RichTextLabel

#Chicken States
var isRoaming: bool = false
var isIdling: bool = false
var isReturning: bool = false
var isReplenishing: bool = false # <-- NEW: State for when eating, drinking, sleeping

#Movement variables
var roaming_radius: float = 500
var target_position: Vector2
var random_angle: float
var random_distance: float



func _ready() -> void:
	isRoaming = true
	RandomizeStats()
	

func _physics_process(delta: float) -> void:
	if isReplenishing:
		velocity = Vector2.ZERO
		move_and_slide()
		return

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

#For Debug
func ResetStats() -> void:
	hunger = 100.0
	thirst = 70.0
	fatigue = 80.0
	
func RandomizeStats() -> void:
	hunger = randf_range(20.0,100.0)
	thirst = randf_range(20.0,100.0)
	fatigue = randf_range(20.0,100.0)

func PrintStats() -> void:
	print("hunger: ", hunger)
	print("thirst: ", thirst)
	print("fatigue: ", fatigue)
	

func Roaming() -> void:
	if not hasPosition:
		random_angle = randf_range(0,2*PI)
		random_distance = randf_range(0,roaming_radius)
		messageLabel.text = "I'm roaming so hard right now"
		print("roaming...")
		
		StatLoss()
		
		target_position = position + Vector2(cos(random_angle), sin(random_angle)) * random_distance
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
		messageLabel.text = "Brain Noise (Idling)"
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
		else:
			isRoaming = false
		
func Contemplate() -> void:
	if hunger < 30:
		isHungry = true
		messageLabel.text = "I could eat some seed"
#		print("I could eat some seed")
	if thirst < 50:
		isThirsty = true
		messageLabel.text = "Water! Give me water!"
#	print("Water! Give me water!")
	if fatigue < 10:
		isDrowsy = true
		messageLabel.text = "Eeeepy..."
#		print("Eeeepy...")
	PrintStats()

func StatLoss() -> void:
	fatigue -= statLossRate
	hunger -= statLossRate
	thirst -= statLossRate

func MoveTowards(collider: CollisionShape2D):
	if not hasPosition:
		target_position = collider.global_position
		print("Moving Towards: ", collider.name)
		hasPosition = true
	
	var direction = (target_position - global_position).normalized()
	velocity = direction * speed
	move_and_slide()
	
	if global_position.distance_to(target_position) < 5.0:
		hasPosition = false
		velocity = Vector2.ZERO

		_start_replenishing(collider)



func _start_replenishing(collider: CollisionShape2D) -> void:
	isReplenishing = true
	
	var action_verb = "interacting"
	if collider.name == "HayCollider": action_verb = "eating"
	elif collider.name == "WaterCollider": action_verb = "drinking"
	elif collider.name == "CoupeCollider": action_verb = "sleeping"
	messageLabel.text = "I'm %s now" % action_verb
#	print("Chicken is now %s for 3 seconds..." % action_verb)

	await get_tree().create_timer(3.0).timeout
	
	print("... finished %s." % action_verb)
	
	ReplenishStat(collider)
	
	isReplenishing = false
	isReturning = true


func ReplenishStat(collider: CollisionShape2D):
	if collider.name == "HayCollider":
		hunger = 100.0
		isHungry = false
	elif collider.name == "WaterCollider":
		thirst = 100.0
		isThirsty = false
	elif collider.name == "CoupeCollider":
		fatigue = 100.0
		isDrowsy = false
	
	# After replenishing, the chicken should go back to its default behavior
	isRoaming = true
