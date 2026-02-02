# Main.gd
# Attach this to the root node of your game scene
extends Node3D

# Map data
var map_data: Dictionary = {}
var active_notes: Array = []
var note_scene: PackedScene

# Game state
var game_time: float = 0.0
var is_playing: bool = false
var score: int = 0
var combo: int = 0

# Timing settings
const NOTE_TRAVEL_TIME: float = 2.0  # seconds for note to reach corner
const SPAWN_DISTANCE: float = -100.0   # Z distance where notes spawn
const HIT_WINDOW_PERFECT: float = 0.05  # seconds
const HIT_WINDOW_GOOD: float = 0.10
const HIT_WINDOW_OK: float = 0.15

# Corner positions (X, Y, Z at camera plane)
var corners: Array = [
	{"pos": Vector3(-5, 5, 0) , "key": KEY_Q, "lane": 0, "name": "TopLeft"},
	{"pos": Vector3(5, 5, 0)  , "key": KEY_P, "lane": 1, "name": "TopRight"},
	{"pos": Vector3(-5, -5, 0), "key": KEY_Z, "lane": 2, "name": "BottomLeft"},
	{"pos": Vector3(5, -5, 0) , "key": KEY_M, "lane": 3, "name": "BottomRight"}
]

# Node references
@onready var camera: Camera3D = $Camera3D
@onready var audio_player: AudioStreamPlayer = $AudioPlayer
@onready var ui: Control = $UI
@onready var notes_container: Node3D = $Notes

func _ready():
	# Since note_scene is an abstraction of a serialized scene, the godot engine needs to
	# allocate memory to understand the kind of scene, i.e. by preloading or loading a tscn file.
	note_scene = preload("res://note_3D.tscn")
	setup_corner_targets()

func _process(delta: float):
	if is_playing:
		game_time += delta
		spawn_notes()
		update_notes(delta)
		check_missed_notes()

func _input(event: InputEvent):
	if event is InputEventKey and event.pressed and is_playing:
		for corner in corners:
			if event.keycode == corner.key:
				hit_note(corner.lane)

# Load map from JSON file
func load_map(json_path: String) -> bool:
	var file = FileAccess.open(json_path, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var error = json.parse(json_string)
		if error == OK:
			map_data = json.data
			print("Map loaded: ", map_data.get("title", "Unknown"))
			return true
	return false

# Load audio file
func load_audio(audio_path: String):
	var audio_stream = load(audio_path)
	if audio_stream:
		audio_player.stream = audio_stream
		return true
	return false

func start_game():
	if map_data.is_empty():
		print("No map loaded!")
		return
	
	is_playing = true
	game_time = 0.0
	score = 0
	combo = 0
	active_notes.clear()
	
	# Clear any existing notes
	for child in notes_container.get_children():
		child.queue_free()
	
	if audio_player.stream:
		audio_player.play()

func pause_game():
	is_playing = false
	audio_player.stream_paused = true

func resume_game():
	is_playing = true
	audio_player.stream_paused = false

func spawn_notes():
	if not map_data.has("hit_objects"):
		return
	
	var spawn_window_end = game_time + NOTE_TRAVEL_TIME + 0.5
	
	for hit_object in map_data.hit_objects:
		var note_time = hit_object.time / 1000.0  # Convert ms to seconds
		
		# Check if note should spawn
		if note_time > game_time and note_time <= spawn_window_end:
			var note_id = str(hit_object.time) + "_" + str(hit_object.x)
			
			# Check if already spawned
			var already_spawned = false
			for note in active_notes:
				if note.id == note_id:
					already_spawned = true
					break
			
			if not already_spawned:
				create_note(hit_object, note_id)

func create_note(hit_object: Dictionary, note_id: String):
	var note_instance = note_scene.instantiate()
	notes_container.add_child(note_instance)
	
	var lane = hit_object.x  # 0-3 for 4k maps
	var target_corner = corners[lane]
	
	# Start position (far away, centered at target corner's X,Y)
	var start_pos = Vector3(
		target_corner.pos.x,
		target_corner.pos.y,
		SPAWN_DISTANCE
	)
	
	note_instance.position = start_pos
	
	var note_data = {
		"id": note_id,
		"instance": note_instance,
		"lane": lane,
		"time": hit_object.time / 1000.0,
		"start_pos": start_pos,
		"end_pos": target_corner.pos,
		"spawn_time": game_time,
		"hit": false,
		"duration": 0.0
	}
	
	# Handle long notes (holds)
	if hit_object.has("end_time"):
		note_data.duration = (hit_object.end_time - hit_object.time) / 1000.0
	
	active_notes.append(note_data)
	
	# Initialize note
	if note_instance.has_method("initialize"):
		note_instance.initialize(note_data.duration > 0)

func update_notes(delta: float):
	for note in active_notes:
		if note.hit:
			continue
		
		# Calculate progress (0 to 1)
		var time_alive = game_time - note.spawn_time
		var progress = clamp(time_alive / NOTE_TRAVEL_TIME, 0.0, 1.0)
		
		# Interpolate position
		note.instance.position = note.start_pos.lerp(note.end_pos, progress)
		
		# Update note visual (can add rotation, scale, etc.)
		if note.instance.has_method("update_visual"):
			note.instance.update_visual(progress)

func hit_note(lane: int):
	# Find closest unhit note in this lane
	var closest_note = null
	var closest_time_diff = INF
	
	for note in active_notes:
		if note.lane == lane and not note.hit:
			var time_diff = abs(note.time - game_time)
			if time_diff < closest_time_diff:
				closest_time_diff = time_diff
				closest_note = note
	
	if closest_note == null:
		return
	
	# Check if within hit window
	if closest_time_diff <= HIT_WINDOW_OK:
		var points = 0
		var judgment = ""
		
		if closest_time_diff <= HIT_WINDOW_PERFECT:
			points = 300
			judgment = "PERFECT"
		elif closest_time_diff <= HIT_WINDOW_GOOD:
			points = 100
			judgment = "GOOD"
		else:
			points = 50
			judgment = "OK"
		
		score += points
		combo += 1
		closest_note.hit = true
		
		# Visual feedback
		if closest_note.instance.has_method("play_hit_effect"):
			closest_note.instance.play_hit_effect(judgment)
		
		# Remove note after brief delay
		await get_tree().create_timer(0.1).timeout
		remove_note(closest_note)
		
		# Update UI
		update_ui()

func check_missed_notes():
	var notes_to_remove = []
	
	for note in active_notes:
		if not note.hit and note.time < game_time - HIT_WINDOW_OK:
			# Missed note
			combo = 0
			notes_to_remove.append(note)
			update_ui()
	
	for note in notes_to_remove:
		remove_note(note)

func remove_note(note: Dictionary):
	active_notes.erase(note)
	if is_instance_valid(note.instance):
		note.instance.queue_free()

func setup_corner_targets():
	# Create visual targets at each corner
	for corner in corners:
		var target = MeshInstance3D.new()
		var mesh = BoxMesh.new()
		mesh.size = Vector3(1, 1, 0.2)
		target.mesh = mesh
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(1, 1, 1, 0.5)
		material.emission_enabled = true
		material.emission = Color(0.5, 0.5, 1.0)
		target.material_override = material
		
		target.position = corner.pos
		add_child(target)
		
		# Add label
		var label = Label3D.new()
		label.text = corner.name + "\n[" + OS.get_keycode_string(corner.key) + "]"
		label.position = corner.pos + Vector3(0, 1.5, 0)
		label.font_size = 32
		add_child(label)

func update_ui():
	if ui and ui.has_method("update_score"):
		ui.update_score(score, combo)
