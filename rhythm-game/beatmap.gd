extends Node

## Used to Hold references to the receptors
var receptors : Array[Area2D]
var labels : Array[Label]
@onready var note_scene : PackedScene

## Used to Position the receptors from the center
## Used as relative positioning to ensure only a single point of maintainablity, as only
## the viewpoint needs to be changed have the positioning reflected respectively.

const scalar_offset = 400 # Used to change the scaling across all pos_offsets
var pos_offsets : Array[Vector2] = [ Vector2(-scalar_offset,0), Vector2(0, -scalar_offset), Vector2(scalar_offset, 0), Vector2(0, scalar_offset) ]
const text_offset = 100 # Used to change the scaling across all pos_offsets
var text_offsets : Array[Vector2] = [ Vector2(0, text_offset), Vector2(text_offset, 0) ]

## Used to define circles as an enumeration
enum Circle { Blue, Red, Green, Yellow, Undefined }
const NUM_CIRCLES = int(Circle.Undefined)

## Some control data to help with managing each receptor
class ReceptorControl:
	var triggered : bool = false # Ensures that triggering happens at most once key press to avoid pressing down from triggering all notes

# var receptors_ctrl : Array[ReceptorControl]
var receptors_ctrl : Array[bool]

func get_circle( key : Key ) -> Circle:
	match key:
		KEY_D:
			return Circle.Blue
		KEY_F:
			return Circle.Red
		KEY_J:
			return Circle.Green
		KEY_K:
			return Circle.Yellow
	return Circle.Undefined
	
func get_center_pos( ) -> Vector2:
	var screen_size = get_viewport( ).size
	return screen_size / 2

func _init( ) -> void:
	TimingWindow.verify_boundaries_of_timing_windows( )

	receptors.resize( NUM_CIRCLES )
	receptors_ctrl.resize( NUM_CIRCLES )
	labels.resize( NUM_CIRCLES )

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for circle in Circle.values( ).slice( 0, NUM_CIRCLES ):
		labels[ circle ] = preload( "res://hitDetect.tscn" ).instantiate( )
		add_child( labels[ circle ] )
	note_scene = preload("res://note.tscn")
	## Map receptors manually once, would be easier to do all of this
	## algorithmically, but this is done for simplicity and 
	## ease of inspection in the editor
	receptors[ int( Circle.Blue ) ]   = $ReceptorBlue
	receptors[ int( Circle.Red ) ]    = $ReceptorRed
	receptors[ int( Circle.Green ) ]  = $ReceptorGreen
	receptors[ int( Circle.Yellow ) ] = $ReceptorYellow

	var screen_size = get_viewport( ).size
	print( "screen_size", screen_size )
	var center_pos : Vector2 = screen_size / 2
	print( "center pos", center_pos )

	## Initialize based on the sprite from the targets_neutral png file.
	# as well as set the starting positions
	for circle in Circle.values( ).slice( 0, NUM_CIRCLES ):
		receptors[ circle ].sprite_node.initialize( circle )
		var receptor_pos : Vector2 = center_pos + pos_offsets[ circle ]
		print( "Receptor Pos: ", receptor_pos )
		var succ = receptors[ circle ].set_receptor_pos( receptor_pos )
		assert( succ, "Should succeed in setting position" )

		## Succinctly, takes the receptors position for the label it represents and offsets it. It turns that out there are only really two offsets so
		## we only need to offset based the last bit on the index.
		labels[ circle ].global_position = receptor_pos + text_offsets[ circle & 0b1 ]
		labels[ circle ].add_theme_font_size_override("font_size", 30 )
		labels[ circle ].connect_receptor( receptors[ circle ] )
		#receptors[ circle ].connect( "note_precision_message", labels[ circle ], _on_hit_note )
		print( "Label position: ", labels[ circle].global_position )

		
	# $ColorRect.hide( )
	## Connect Signals Here
	$NoteEmitter.timeout.connect( _on_note_emitter_timeout )

	## Start Timers
	$NoteEmitter.start( )

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		var key = event.keycode
		var circle : Circle = get_circle( key )
		if circle != Circle.Undefined:
			receptors[ int(circle) ].animate( )

## Runs every time the trigger occurs at most once. Any further events will ensure that trigger_receptor does not occur twice
## to avoid holds from counting across multiple notes 
## (notes and receptors will take care of turning off collision masks when they detect collisions to prevent holds across notes)
func trigger_receptor( receptor_arr : Array[Area2D], control_arr : Array[bool], circle : Circle ) -> void:
	var idx : int = int( circle )
	if ( !control_arr[ idx ] ):
		# print("Triggered")
		receptor_arr[ idx ].set_receptor_monitoring( true )
		control_arr[ idx ] = true

func untrigger_receptor( receptor_arr : Array[Area2D], control_arr : Array[bool], circle : Circle ) -> void:
	var idx : int = int( circle )
	receptor_arr[ idx ].set_receptor_monitoring( false )
	control_arr[ idx ] = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process( _delta: float ) -> void:
	if Input.is_action_pressed( "trigger_blue_receptor" ):
		trigger_receptor( receptors, receptors_ctrl, Circle.Blue )
	elif Input.is_action_just_released( "trigger_blue_receptor" ):
		untrigger_receptor( receptors, receptors_ctrl, Circle.Blue )

	if Input.is_action_pressed( "trigger_red_receptor" ):
		trigger_receptor( receptors, receptors_ctrl, Circle.Red )
	elif Input.is_action_just_released( "trigger_red_receptor" ):
		untrigger_receptor( receptors, receptors_ctrl, Circle.Red )

	if Input.is_action_pressed( "trigger_green_receptor" ):
		trigger_receptor( receptors, receptors_ctrl, Circle.Green )
	elif Input.is_action_just_released( "trigger_green_receptor" ):
		untrigger_receptor( receptors, receptors_ctrl, Circle.Green )

	if Input.is_action_pressed( "trigger_yellow_receptor" ):
		trigger_receptor( receptors, receptors_ctrl, Circle.Yellow )
	elif Input.is_action_just_released( "trigger_yellow_receptor" ):
		untrigger_receptor( receptors, receptors_ctrl, Circle.Yellow )

func display_hit( hit_text : String ) -> void:
	$HitDetect.text = hit_text
	$HitDetect.show( )
	$HitDetect.start( )

## Signal functions
func _on_timer_timeout( ) -> void:
	pass

func _on_hit_detect_timer_timeout( ) -> void:
	$HitDetect.hide( )

func _on_note_emitter_timeout( ) -> void:
	# var random_receptor = receptors.pick_random( )
	var random_receptor = receptors[ 0 ]
	var note = note_scene.instantiate( )
	var destination_receptors : Array[Area2D] = [ random_receptor ]
	var center_pos : Vector2 = get_center_pos( )
	var timestamps : Array[float]
	
	add_child( note )
	note.start( center_pos, destination_receptors, timestamps )
