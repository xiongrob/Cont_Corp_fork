# UI.gd
# Attach this to a Control node for the game UI
extends Control

@onready var score_label: Label = $ScoreLabel
@onready var combo_label: Label = $ComboLabel
@onready var file_dialog: FileDialog = $FileDialog
@onready var start_button: Button = $MenuPanel/StartButton
@onready var load_map_button: Button = $MenuPanel/LoadMapButton
@onready var load_audio_button: Button = $MenuPanel/LoadAudioButton
@onready var menu_panel: Panel = $MenuPanel

var main_game: Node3D

func _ready():
	main_game = get_parent()
	
	# Setup file dialog
	if not file_dialog:
		file_dialog = FileDialog.new()
		add_child(file_dialog)
		file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	
	# Connect signals
	if start_button:
		start_button.pressed.connect(_on_start_pressed)
	if load_map_button:
		load_map_button.pressed.connect(_on_load_map_pressed)
	if load_audio_button:
		load_audio_button.pressed.connect(_on_load_audio_pressed)
	
	file_dialog.file_selected.connect(_on_file_selected)
	
	# Initial UI state
	show_menu()

func show_menu():
	if menu_panel:
		menu_panel.visible = true
	if score_label:
		score_label.visible = false
	if combo_label:
		combo_label.visible = false

func hide_menu():
	if menu_panel:
		menu_panel.visible = false
	if score_label:
		score_label.visible = true
	if combo_label:
		combo_label.visible = true

func _on_start_pressed():
	hide_menu()
	if main_game and main_game.has_method("start_game"):
		main_game.start_game()

var loading_mode: String = ""  # "map" or "audio"

func _on_load_map_pressed():
	loading_mode = "map"
	file_dialog.filters = ["*.json ; JSON Files"]
	file_dialog.popup_centered(Vector2i(800, 600))

func _on_load_audio_pressed():
	loading_mode = "audio"
	file_dialog.filters = ["*.ogg ; OGG Files", "*.mp3 ; MP3 Files", "*.wav ; WAV Files"]
	file_dialog.popup_centered(Vector2i(800, 600))

func _on_file_selected(path: String):
	if loading_mode == "map":
		if main_game and main_game.has_method("load_map"):
			var success = main_game.load_map(path)
			if success:
				print("Map loaded successfully!")
			else:
				print("Failed to load map")
	elif loading_mode == "audio":
		if main_game and main_game.has_method("load_audio"):
			var success = main_game.load_audio(path)
			if success:
				print("Audio loaded successfully!")
			else:
				print("Failed to load audio")

func update_score(new_score: int, new_combo: int):
	if score_label:
		score_label.text = "Score: " + str(new_score)
	if combo_label:
		combo_label.text = "Combo: " + str(new_combo) + "x"

func _input(event: InputEvent):
	if event.is_action_pressed("ui_cancel"):
		if menu_panel and menu_panel.visible:
			get_tree().quit()
		else:
			show_menu()
			if main_game and main_game.has_method("pause_game"):
				main_game.pause_game()
