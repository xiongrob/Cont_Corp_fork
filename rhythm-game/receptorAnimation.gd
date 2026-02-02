extends Node2D


var original_position : Vector2
var tween : Tween

# Jolt settings
const JOLT_STRENGTH = 3
const JOLT_DURATION = 0.1
# const JOLT_DURATION = 2

## Take in parametizable values based on the particular receptor.
func initialize( circle_color : int ) -> void:

	## Sets the frame coordinate based on the circle color 
	## (mapping of integer as follow:
	## 	Blue  : 0
	## 	Red   : 1
	## 	Green : 2
	## 	Yellow: 3
	## )
	$Sprite.frame = circle_color
	$Sprite.frame_coords = Vector2( circle_color, 0 )

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Record the original position, such that it slowly shift
	# in the case of successions of triggers
	original_position = position


func trigger_circle( ):
	
	# Emit particles
	$GPUParticles2D.restart( )
	$GPUParticles2D.emitting = true
	
	# Apply jolt effect
	apply_jolt( )

func apply_jolt( ):
	# Random jolt direction
	var jolt_offset = Vector2(
		randf_range(-JOLT_STRENGTH, JOLT_STRENGTH),
		randf_range(-JOLT_STRENGTH, JOLT_STRENGTH)
	)
	
	# Create tween for smooth jolt and return
	# https://raw.githubusercontent.com/godotengine/godot-docs/master/img/tween_cheatsheet.webp

	## You should avoid using more than one Tween per object's property. 
	## If two or more tweens animate one property at the same time, 
	## the last one created will take priority and assign the final value. 
	## If you want to interrupt and restart an animation, consider assigning 
	## the Tween to a variable.
	if tween:
		tween.kill( )

	## Note: Tweens are not designed to be reused and trying to do so results 
	## in an undefined behavior. Create a new Tween for each animation and 
	## every time you replay an animation from start. Keep in mind that Tweens 
	## start immediately, so only create a Tween when you want to start animating.
	tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_ELASTIC)
	
	tween.tween_property(
		$Sprite,
		"position",
		original_position + jolt_offset,
		JOLT_DURATION * 0.3
	)
	tween.tween_property(
		$Sprite,
		"position",
		original_position,
		JOLT_DURATION * 0.7
	)
