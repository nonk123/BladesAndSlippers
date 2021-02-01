extends KinematicBody2D


# Used for meter -> pixel conversions.
const PIXELS_PER_METER = 64.0

# Enemies further away than this don't count.
const PATHFINDING_RANGE = PIXELS_PER_METER * 30.0

# How far can we dash to attack.
const ATTACK_RANGE = PIXELS_PER_METER * 3.0

# We receive this big of a push when we start walking.
const WALK_SPEED = PIXELS_PER_METER * 3.0

# We leap this high into the air.
const JUMP_POWER = PIXELS_PER_METER * 5.0

# Horizontal velocity is multiplied by this much every frame.
const FRICTION_COEFFICIENT = 0.967

const GRAVITY = PIXELS_PER_METER * 9.8

# The HitArea node is this far away in the direction of the attack.
const HIT_AREA_DISTANCE = 40.0

# How much damage we deal if the attack connects.
const BASE_ATTACK = 10.0

# How long you have to wait for after making a turn.
const TURN_WAIT = 1.5

export(bool) var player_controlled = false

# Body's current velocity in px/s.
var velocity = Vector2.ZERO

# If this drops to 0, we die.
var health = 100.0

# The fighter we are targeting.
var enemy

var turn_timer = TURN_WAIT

onready var camera = $Camera

onready var anim_tree = $AnimationTree

onready var walking = $Walking

onready var hit_area = $HitArea

onready var health_bar = $HealthBar


func _ready():
	camera.current = player_controlled
	hit_area.connect("body_entered", self, "hit_a_guy")


func _physics_process(delta):
	turn_timer += delta
	
	enemy = find_enemy()
	
	if player_controlled:
		accept_input()
	else:
		think()
	
	# Simulate friction.
	if is_on_floor():
		velocity.x *= FRICTION_COEFFICIENT
	
	velocity.y += GRAVITY * delta
	velocity = move_and_slide(velocity, Vector2.UP)


func _process(_delta):
	health_bar.value = health


func think():
	if enemy == null:
		make_turn("jump", [0.0]) # victory jump
		return
	
	var distance = abs(enemy.position.x - position.x)
	var direction = sign(enemy.position.x - position.x)
	
	if distance <= ATTACK_RANGE:
		make_turn("attack", [direction])
	else:
		make_turn("walk", [direction])


func accept_input():
	var direction = 0.0
	direction += Input.get_action_strength("walk_right")
	direction -= Input.get_action_strength("walk_left")
	
	var want_to_jump = Input.is_action_pressed("jump")
	
	if want_to_jump:
		make_turn("jump", [direction])
	elif enemy:
		var distance_to_enemy = enemy.position.x - position.x
		var walking_into_them = sign(direction) == sign(distance_to_enemy)
		var in_range = abs(distance_to_enemy) <= ATTACK_RANGE
		
		if walking_into_them and in_range:
			make_turn("attack", [direction])
		else:
			make_turn("walk", [direction])
	else:
		make_turn("walk", [direction])


# If METHOD returns true, count this call as a turn.
func make_turn(method, args):
	if turn_timer >= TURN_WAIT and callv(method, args):
		turn_timer = 0.0


func attack(direction):
	if direction == 0.0:
		return false
	
	velocity.x = direction * ATTACK_RANGE
	hit_area.position.x = direction * HIT_AREA_DISTANCE
	
	anim_tree["parameters/attack/blend_position"] = direction
	anim_tree["parameters/attack_shot/active"] = true
	
	return true


func walk(direction):
	if direction == 0.0:
		return false
	
	velocity.x = direction * WALK_SPEED
	
	anim_tree["parameters/walk/blend_position"] = direction
	anim_tree["parameters/walk_shot/active"] = true
	walking.play()
	
	return true


func jump(direction):
	velocity.y = -JUMP_POWER
	velocity.x = direction * WALK_SPEED
	
	anim_tree["parameters/jump_shot/active"] = true
	walking.play()
	
	return true


func hit_a_guy(node):
	if "health" in node:
		node.deal_damage(BASE_ATTACK)


func deal_damage(how_much):
	health -= how_much
	
	if health <= 0.01:
		queue_free()


func find_enemy():
	var closest
	var closest_distance = PATHFINDING_RANGE
	
	for fighter in get_parent().get_children():
		if fighter.get_rid() != get_rid():
			var distance = fighter.position.distance_to(position)
			
			if distance < closest_distance:
				closest = fighter
				closest_distance = distance
	
	return closest
