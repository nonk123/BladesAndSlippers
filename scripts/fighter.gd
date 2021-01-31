extends KinematicBody2D


# Used for meter -> pixel conversions.
const PIXELS_PER_METER = 64.0

# Enemies further away than this don't count.
const PATHFINDING_RANGE = PIXELS_PER_METER * 30.0

# How far can we dash to attack.
const ATTACK_RANGE = PIXELS_PER_METER * 3.0

# We receive this big of a push when we start walking.
const WALK_SPEED = PIXELS_PER_METER * 3.0

# Horizontal velocity is multiplied by this much every frame.
const FRICTION_COEFFICIENT = 0.967

const GRAVITY = PIXELS_PER_METER * 9.8

# How much damage we deal if the attack connects.
const BASE_ATTACK = 10.0

# How long you have to wait for after doing a turn.
const TURN_WAIT = 2.0

# Body's current velocity in px/s.
var velocity = Vector2.ZERO

# If this drops to 0, we die.
var health = 100.0

# The fighter we are targeting.
var enemy

var turn_timer = TURN_WAIT

onready var anim_tree = $AnimationTree

onready var walking = $Walking

onready var hit_left = $HitLeft

onready var hit_right = $HitRight


func _ready():
	hit_left.connect("body_entered", self, "hit_a_guy")
	hit_right.connect("body_entered", self, "hit_a_guy")


func _physics_process(delta):
	turn_timer += delta
	
	enemy = find_enemy()
	
	if enemy and turn_timer >= TURN_WAIT:
		do_turn(delta)
		turn_timer = 0.0
	
	# Simulate friction.
	if is_on_floor():
		velocity.x *= FRICTION_COEFFICIENT
	
	velocity.y += GRAVITY * delta
	velocity = move_and_slide(velocity, Vector2.UP)


func do_turn(_delta):
	var distance = abs(enemy.position.x - position.x)
	var direction = sign(enemy.position.x - position.x)
	
	if direction == 0.0:
		return # not sure what to do here
	
	if distance <= ATTACK_RANGE:
		attack(direction)
	else:
		walk(direction)


func attack(direction):
	velocity.x = direction * ATTACK_RANGE
	
	anim_tree["parameters/attack/blend_position"] = direction
	anim_tree["parameters/attack_shot/active"] = true


func walk(direction):
	velocity.x = direction * WALK_SPEED
	
	anim_tree["parameters/walk/blend_position"] = direction
	anim_tree["parameters/walk_shot/active"] = true
	walking.play()


func hit_a_guy(node):
	if "velocity" in node:
		hit_left.set_deferred("monitoring", false)
		hit_right.set_deferred("monitoring", false)
		node.deal_damage(BASE_ATTACK)


func deal_damage(how_much):
	health -= how_much
	
	if health <= 0.01:
		queue_free()


func find_enemy():
	var closest
	var closest_distance = PATHFINDING_RANGE
	
	for gladiator in get_parent().get_children():
		if gladiator.get_rid() != get_rid():
			var distance = gladiator.position.distance_to(position)
			
			if distance < closest_distance:
				closest = gladiator
				closest_distance = distance
	
	return closest
