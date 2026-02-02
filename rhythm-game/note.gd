extends Area2D


## List of receptors that need to be 
var dest_receptors : Array[Area2D] # Implements a queue (meant for combos)
var time_stamps : Array[float]
var dir_vec : Vector2 # Normal vector providing direction for the dest_receptor( )
var center_reached : bool = false # Used to detect when the center has been reached on a frame
@export var speed : int = 500
@onready var triggered : bool = false
@export var hitbox_detect_node : Area2D
@export var receptor_detect_node : Area2D

func dest_receptor( ) -> Area2D:
	assert( dest_receptors.size( ) != 0, "Should have a destination receptor" )
	return dest_receptors[ dest_receptors.size( ) - 1 ]


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group( "notes" )

	## Used to indirectly reference a node along a path.
	## This creates a single point of maintainence if the path needs to be changed...
	hitbox_detect_node = $HitBoxOverlapping
	receptor_detect_node = $ReceptorDetect

	
	$VisibleOnScreenNotifier2D.screen_exited.connect( _on_visible_on_screen_notifier_2d_screen_exited )
	# Area_entered will trigger when another Area2D enters Area2D, 
	# whereas body_entered will trigger when a PhysicsBody2D enters the Area2D.
	hitbox_detect_node.area_entered.connect( _on_center_of_receptor_reached )
	receptor_detect_node.area_exited.connect( _on_exiting_receptor )

	## CollisionShape2D.get_parent( ) == CollisionObject2D
	## assert( $CollisionShape2D.get_parent( ).collision_layer == int(GlobalEnums.CollisionMask.Center), "Note should only detect the center at the moment" )

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	# if ( dest_receptors.size( ) < 1 ):
	# 	return
	var new_position : Vector2 = position + dir_vec * speed * delta

	# The idea here is that the normal vector when combined will tell us, if the
	# two vectors dir_vector and the direction to the new positions to the receptor's vector's
	# normal vector are at different directions. If they are, then it must be the case
	# that during this frame the note passes through the center of the receptor. 
	# Likewise, the resultant vector itself must be zero (1 + -1 == 0).
	var result_normal_vec = dir_vec + ( dest_receptor( ).position - new_position ).normalized( )

	# Momentarily set position to the center for a frame
	## This essentially checks a range of positions relative to the receptor's position. If it is the case
	## that on this frame, the note would have passed the center of the receptor, then mark is true 
	## (as to prevent the note from getting stuck at the receptor position),
	## and for the current frame, set the position to the receptor's position, in order for signals
	## that need to be emitted when passing the center can be done. This is important since
	## in the case that the direction needs to be changed, due to combos, it can be change directions accurately.
	if !center_reached && result_normal_vec == Vector2(0,0):
		center_reached = true
		position = dest_receptor( ).position
	else:
		position = new_position

## Used to initialize note.
## start position: From where on the view port should a note start.
## Dests: array of receptors the note needs to travel to
## time_stamps: array of time_stamps necessary for prioritizing which note the receptor detects for (Ordered from most negative, to most positive)
func start( start_pos : Vector2, dests : Array[Area2D], time_stamps : Array[float] ) -> void:
	assert( dests.size( ) != 0, "Destintation receptors should not be empty" )

	hitbox_detect_node.get_node( "CollisionShape2D" ).disabled = false
	receptor_detect_node.get_node( "CollisionShape2D" ).disabled = false
	position = start_pos
	dest_receptors = dests

	dir_vec = ( dest_receptor( ).position - start_pos ).normalized( )

## For handling when the center of the receptor has been reached
## Fix this such that once a trigger has occured, need to check for release of key, depending on
## the kind of note such that successive key presses doesn't always register for future notes
## (or else, then holding down notes would count for something)
## This kind of logic infers that it is best that collision checks are done through receptors, not
## notes to help keep track of this.

## In addition, we should probably move the checks for overlapping bodies through receptors on
## each frame. That way, we can deterministically check the order of hitboxes, such that if
## the note is within the perfect hitbox, of course prioritize it over good, and okay.
## This may not be guaranteed for just the area_entered signal, as even the order may not be deterministic...

## Since overlappping areas are
func _on_center_of_receptor_reached( area: Node2D ):
	GlobalEnums.entered += 1
	# print( "Center Reached: ", GlobalEnums.entered, " times" )
	assert( area.get_parent( ) == dest_receptor( ), "The destination receptor should be the one at the center" )
	if ( dest_receptors.size( ) > 1 ):
		dest_receptors.pop_back( )
		dir_vec = ( dest_receptor( ).position - position ).normalized( )
	# if ( area.name == "CenterArea" ):
	# 	# print( "Center Reached" )
	# 	assert( area.get_parent( ) == dest_receptor( ), "The destination receptor should be the one at the center" )
	# 	if ( dest_receptors.size( ) > 1 ):
	# 		dest_receptors.pop_back( )
	# 		dir_vec = ( dest_receptor( ).position - position ).normalized( )
	# else: # It must be the case that these areas are associated with the hitboxes
	# 	var 
	# elif( area.name == "PerfectArea" ):
	# 	print( "Perfect" )
	# elif( area.name == "GoodArea" ):
	# 	print( "Good" )
	# elif( area.name == "OkArea" ):
	# 	print( "Okay" )


	# if triggered:
	# 	queue_free( )

## Idiomatically turn on detect hitbox detection, turned off once
## the receptor has triggered on it. Once the receptor leaves, 
## detection is to be turned back on.
func _on_exiting_receptor( area: Node2D ):
	GlobalEnums.exited += 1
	# print( "Exiting Receptor: ", GlobalEnums.exited, " times" )
	assert( center_reached, "Center should have reached" )
	assert( GlobalEnums.entered == GlobalEnums.exited, "A note needs to enter and exit the same amount of times." )
	hitbox_detect_node.get_parent( ).collision_layer |= GlobalEnums.CollisionMask.Hit_Detect

func _on_visible_on_screen_notifier_2d_screen_exited( ):
	queue_free( )
