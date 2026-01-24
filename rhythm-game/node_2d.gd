extends Node2D

@onready var circle_d = $Circle_D
@onready var circle_f = $Circle_F
@onready var circle_j = $Circle_J
@onready var circle_k = $Circle_K

# Store original positions
var original_positions = {}

# Jolt settings
const JOLT_STRENGTH = 3
const JOLT_DURATION = 0.1

func _ready():
	# Store original positions for each circle
	original_positions[circle_d] = circle_d.position
	original_positions[circle_f] = circle_f.position
	original_positions[circle_j] = circle_j.position
	original_positions[circle_k] = circle_k.position

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		var key = event.keycode
		
		match key:
			KEY_D:
				trigger_circle(circle_d)
			KEY_F:
				trigger_circle(circle_f)
			KEY_J:
				trigger_circle(circle_j)
			KEY_K:
				trigger_circle(circle_k)

func trigger_circle(circle: Node2D):
	# Get the particles node (assumes it's a child of the circle)
	var particles = circle.get_node("GPUParticles2D")
	
	# Emit particles
	particles.restart()
	particles.emitting = true
	
	# Apply jolt effect
	apply_jolt(circle)

func apply_jolt(circle: Node2D):
	# Random jolt direction
	var jolt_offset = Vector2(
		randf_range(-JOLT_STRENGTH, JOLT_STRENGTH),
		randf_range(-JOLT_STRENGTH, JOLT_STRENGTH)
	)
	
	# Create tween for smooth jolt and return
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_ELASTIC)
	
	tween.tween_property(
		circle,
		"position",
		original_positions[circle] + jolt_offset,
		JOLT_DURATION * 0.3
	)
	tween.tween_property(
		circle,
		"position",
		original_positions[circle],
		JOLT_DURATION * 0.7
	)
