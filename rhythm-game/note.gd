extends Area2D


## List of receptors that need to be 
var dest_receptors : Array[Area2D] # Implements a queue (meant for combos)
var time_stamps : Array[float]
var dir_vec : Vector2 # Normal vector providing direction for the dest_receptor( )
var velocity : Vector2 # Calculated based on the initial distance from either 
					   # the center or the source receptor, to the distance to the destination receptor
var center_reached : bool = false # Used to detect when the center has been reached on a frame
@export var speed : int = 500
@onready var acked : bool = false
@onready var exited : bool = false
# @export var hitbox_detect_node : Area2D
# @export var receptor_detect_node : Area2D

func dest_receptor( ) -> Area2D:
	assert( dest_receptors.size( ) != 0, "Should have a destination receptor" )
	return dest_receptors[ dest_receptors.size( ) - 1 ]


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group( "notes" )

	## Used to indirectly reference a node along a path.
	## This creates a single point of maintainence if the path needs to be changed...
	# hitbox_detect_node = $HitBoxOverlapping
	# receptor_detect_node = $ReceptorDetect

	
	$VisibleOnScreenNotifier2D.screen_exited.connect( _on_visible_on_screen_notifier_2d_screen_exited )
	# Area_entered will trigger when another Area2D enters Area2D, 
	# whereas body_entered will trigger when a PhysicsBody2D enters the Area2D.
	area_entered.connect( _on_center_of_receptor_reached )
	area_exited.connect( _on_exiting_receptor )

	## CollisionShape2D.get_parent( ) == CollisionObject2D
	## assert( $CollisionShape2D.get_parent( ).collision_layer == int(GlobalEnums.CollisionMask.Center), "Note should only detect the center at the moment" )

##TODO: Implement full functionalities once timestamps are inserted...
func get_receptor_time_stamp( ) -> float:
	return 0

func set_new_velociy( source_pos : Vector2, dest_pos : Vector2, time_elapsed_beg : float ) -> void:
	var dist : Vector2 = dest_pos - source_pos


##TODO: Implement velocity to depend on the timestamp
func curr_velocity( ) -> Vector2:
	assert(false)
	var speed = 500
	return Vector2(0,0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	## No processing is needed
	if ( dest_receptors.size( ) == 0 ):
		return
	var distance : Vector2 = curr_velocity( )
	var new_position : Vector2 = position + dir_vec * speed * delta

	# The idea here is that the normal vector when combined will tell us, if the
	# two vectors dir_vector and the direction to the new positions to the receptor's vector's
	# normal vector are at different directions. If they are, then it must be the case
	# that during this frame the note passes through the center of the receptor. 
	# Likewise, the resultant vector itself must be zero (1 + -1 == 0).
	##NOTE: An edge case is in the very slim case that position is already at the center, traveling to it on the
	## the previous frame, check that against, the target receptor.
	var result_normal_vec = dir_vec + ( dest_receptor( ).position - new_position ).normalized( )
	var passes_through_receptor_center : bool = position == dest_receptor( ).position || result_normal_vec == Vector2( 0, 0 )

	## This essentially checks a range of positions relative to the receptor's position. If it is the case
	## that on this frame, the note would have passed the center of the receptor, then 
	## check if this a combo so that the note can change directions, according to the next receptor.
	## Calculate the rest of the positioning based on the leftover time on delta, and travel in that direction.
	if passes_through_receptor_center:
		## V = D / delta -> D = recep_pos - curr_pos, V = dir_vec * speed
		## delta -= dest_receptor( ).position ( dir_vec * speed )
		position = dest_receptor( ).position
		if ( dest_receptors.size( ) > 1 ):
			dest_receptors.pop_back( )
			dir_vec = ( dest_receptor( ).position - position ).normalized( )

	position = position + dir_vec * speed * delta

## Used to initialize note.
## start position: From where on the view port should a note start.
## Dests: array of receptors the note needs to travel to
## time_stamps: array of time_stamps necessary for prioritizing which note the receptor detects for (Ordered from most negative, to most positive)
func start( start_pos : Vector2, dests : Array[Area2D], curr_time_stamp : float, time_stamps : Array[float] ) -> void:
	assert( dests.size( ) != 0, "Destintation receptors should not be empty" )

	$"CollisionShape2D".disabled = false
	# receptor_detect_node.get_node( "CollisionShape2D" ).disabled = false
	position = start_pos
	dest_receptors = dests

	dir_vec = ( dest_receptor( ).position - start_pos ).normalized( )

## Signals to the note that the receptor has acceptted this note. Hence, setting note to no longer be monitorable, if there still are 
## 
func acknowledge_receptor( ) -> void:
	assert( !acked, "Should have yet to have triggered." )
	acked = true
	if dest_receptors.size( ) == 1: # No more receptors to travel to...
		exited = true
		# Needs to be called at the end of the current frame to avoid physics calculations
		call_deferred( "queue_free" ) # need to schedule this method to occur at the end of the current frame
		if ( center_reached ):
			GlobalEnums.exited += 1
		print( "Exiting Receptor(via being triggered): ", GlobalEnums.exited, " times" )
	else:
		$CollisionShape2D.get_parent( ).call_deferred( "set_collision_layer_value", 2, false )
		# $CollisionShape2D.get_parent( ).set_collision_layer_value( 2, false )
		# hitbox_detect_node.get_node( "CollisionShape2D" ).set_deferred( "disabled", true )

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
	if ( area.name == "OkArea" ):
		return
	assert( center_reached, "Center should have been reached" )
	GlobalEnums.entered += 1
	print( "Center Reached: ", GlobalEnums.entered, " times" )
	print( "Area Node Entered: ", area.name )
	assert( area.get_parent( ) == dest_receptor( ), "The destination receptor should be the one at the center" )
	
	## It is very likely due to needing change the hitbox of the note, that I will need to put this
	## in the physics_process section due to it being prematurely called before the center has been
	## passed over, as evident when center_reached was still false when I increased the hitbox size.
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
	if ( area.name == "CenterArea" || exited ):
		return
	print( "Exiting area: ", area.name )
	GlobalEnums.exited += 1
	print( "Exiting Receptor: ", GlobalEnums.exited, " times" )
	assert( center_reached, "Center should have reached" )
	assert( GlobalEnums.entered == GlobalEnums.exited, "A note needs to enter and exit the same amount of times." )
	# var not_triggered : bool = $CollisionShape2D.get_parent( ).get_collision_layer_value( 2 )
	
	# hitbox_detect_node.get_node( "CollisionShape2D" ).disabled = false # This may have been turned off 
	# hitbox_detect_node.get_parent( ).collision_layer |= GlobalEnums.CollisionMask.Hit_Detect
	if ( !acked ):
		area.get_parent( ).note_precision_message.emit( "Missed..." )
	acked = false
	$CollisionShape2D.get_parent( ).set_collision_mask_value( 3, false )
	exited = true
func _on_visible_on_screen_notifier_2d_screen_exited( ):
	queue_free( )
