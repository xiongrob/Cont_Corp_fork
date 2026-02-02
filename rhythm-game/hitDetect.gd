extends Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Visibility.timeout.connect( one_visibility_timer_timeout )


func show_message( message : String ) -> void:
	text = message
	show( )
	$Visibility.start( )

func connect_receptor( receptor : Area2D ) -> void:
	receptor.connect( "note_precision_message", _on_hit_note )

func _on_hit_note( message : String ) ->void:
	show_message( message )

func one_visibility_timer_timeout( ) -> void:
	hide( )
