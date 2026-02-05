extends Area2D

var circle_pos : Vector2
var hit_circles : Array[Area2D]
@export var sprite_node : Node2D
signal note_precision_message

const hits : Array[String] = [ "Perfect!", "Good!", "Okay" ]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sprite_node = $ReceptorAnimation
	circle_pos = $ReceptorAnimation/Sprite.position

	hit_circles.resize( 3 )
	hit_circles[ 0 ] = $PerfectArea
	hit_circles[ 1 ] = $GoodArea
	hit_circles[ 2 ] = $OkArea
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

func get_closest_node( hit_circle : Area2D ) -> Area2D:
	assert( hit_circle.has_overlapping_areas( ), "Should have overlapping areas" )
	var closest_note : Area2D = hit_circle.get_overlapping_areas( )[ 0 ]

	for note in hit_circle.get_overlapping_areas( ):
		if ( note.get_receptor_time_stamp( ) < closest_note.get_receptor_time_stamp( ) ):
			closest_note = note
	return closest_note

func _physics_process( _delta: float ) -> void:
	## Do nothing if the receptor isn't monitoring
	## or OkaArea doesn't detect any overlapping areas 
	## (which implies no notes are in the vicinity).
	if ( !hit_circles[ 0 ].monitoring || !$OkArea.has_overlapping_areas( ) ):
		return
	var idx : int = 0
	for hit_circle in hit_circles:
		if ( hit_circle.has_overlapping_areas( ) ):
			print( "Detected a note in : ", hits[ idx ], " area." )
			var note : Area2D = get_closest_node( hit_circle )
			assert( !note.center_reached || GlobalEnums.entered != GlobalEnums.exited, "A note should'nt have the same number of enters and exits." )
			assert( note.exited == false, "Note should have not have exited." )
			note.acknowledge_receptor( ) # Trigger note
			call_deferred( "set_receptor_monitoring", false )
			note_precision_message.emit( hits[ idx ] )
			return
		idx += 1

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
	for hit_circle in hit_circles:
		hit_circle.monitoring = _monitoring
