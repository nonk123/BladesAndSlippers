extends KinematicBody2D


# Used for meter -> pixel conversions.
const PIXELS_PER_METER = 32.0

# Gravity in m/s.
export(float) var gravity = 9.8

# Body's current velocity in pixels/s.
var velocity = Vector2.ZERO


func _physics_process(delta):
	velocity.y += PIXELS_PER_METER * gravity * delta
	velocity = move_and_slide(velocity, Vector2.UP)
