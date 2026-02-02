extends Area2D

var circle_pos : Vector2
@export var sprite_node : Node2D
signal note_precision_message

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sprite_node = $ReceptorAnimation
	circle_pos = $ReceptorAnimation/Sprite.position
	# Center the node for testing purposes
	# position = Vector2(300, 300)

	## Set collision layers to be detected
	collision_layer = GlobalEnums.CollisionMask.Center | GlobalEnums.CollisionMask.Hit_Detect
	
	assert( get_collision_layer_value(GlobalEnums.CollisionMask.Center), "The Center Hitbox needs to be enabled" )
	assert( get_collision_layer_value(GlobalEnums.CollisionMask.Hit_Detect), "The center hitbox needs to be enabled" )

# Called every frame. 'delta' is the elapsed time since the previous frame.
# func _process(delta: float) -> void:
# 	pass
	# if circle_pos != $ReceptorAnimation/Sprite.position:
	# 	circle_pos = $ReceptorAnimation/Sprite.position
	# 	print( "Circle position: ", circle_pos )

func _physics_process( _delta: float ) -> void:
	if ( !$PerfectArea.monitoring ):
		return
	var detect_note : bool = true
	if ( $PerfectArea.has_overlapping_areas( ) ):
		note_precision_message.emit( "Perfect" )
		print( "Perfect!" )
	elif ( $GoodArea.has_overlapping_areas( ) ):
		note_precision_message.emit( "Good!" )
		print( "Good!" )
	elif ( $OkArea.has_overlapping_areas( ) ):
		note_precision_message.emit( "Okay" )
		print( "Okay" )
	else:
		detect_note = false

	if detect_note:
		## Turn off monitoring until the key has been let go of, and pressed again
		set_receptor_monitoring( false ) # 

## Sets position iff it is within bounds
func set_receptor_pos( pos : Vector2 ) -> bool:
	var screen_size = get_viewport( ).size

	var within_bounds : bool = (0 <= pos.x && pos.x <= screen_size.x &&
								0 <= pos.y && pos.y <= screen_size.y )

	if within_bounds:
		position = pos

	return within_bounds

## Perform animations on input...
## Rather than directly calling trigger circle,
## encapsulated as a method to abstract away the
## details revolving animations...
func animate( ) -> void:
	$ReceptorAnimation.trigger_circle( )
	
func check_collisions( ) -> GlobalEnums.Precision:
	return GlobalEnums.Precision.Miss

func set_receptor_monitoring( _monitoring : bool ) -> void:
	$PerfectArea.monitoring = _monitoring
	$GoodArea.monitoring = _monitoring
	$OkArea.monitoring = _monitoring 
