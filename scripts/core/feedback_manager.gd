class_name FeedbackManager
extends Node

const SFX_WRONG = preload("res://assets/audio/sfx_wrong.wav")
const SFX_CORRECT = preload("res://assets/audio/sfx_correct.wav")
const SFX_LEVEL_COMPLETE = preload("res://assets/audio/sfx_level_complete.wav")
const SFX_RUN_COMPLETE = preload("res://assets/audio/sfx_run_complete.wav")

@export var pool_size: int = 3
@export var sound_enabled: bool = true
@export var haptics_enabled: bool = true
var _players: Array[AudioStreamPlayer] = []
var _current_player_idx: int = 0


func _ready() -> void:
	_init_player_pool()


func _init_player_pool() -> void:
	_players.clear()
	for i in range(pool_size):
		var player := AudioStreamPlayer.new()
		player.name = "AudioPlayer_%d" % i
		player.bus = "Master"
		add_child(player)
		_players.append(player)


func _get_available_player() -> AudioStreamPlayer:
	if _players.is_empty():
		_init_player_pool()

	for player in _players:
		if not player.playing:
			return player

	# Round-robin fallback if all are busy
	var player: AudioStreamPlayer = _players[_current_player_idx]
	_current_player_idx = (_current_player_idx + 1) % _players.size()
	return player


func _play_sfx(stream: AudioStream, volume_db: float = 0.0) -> void:
	if not sound_enabled or not stream:
		return
	var player: AudioStreamPlayer = _get_available_player()
	player.stream = stream
	player.volume_db = volume_db
	player.play()


func _vibrate(duration_ms: int) -> void:
	if not haptics_enabled:
		return
	Input.vibrate_handheld(duration_ms)
	print("[FEEDBACK] Vibrate: %d ms" % duration_ms)


func set_sound_enabled(enabled: bool) -> void:
	sound_enabled = enabled


func set_haptics_enabled(enabled: bool) -> void:
	haptics_enabled = enabled


func play_wrong() -> void:
	_play_sfx(SFX_WRONG, -2.0)
	_vibrate(25)


func play_correct() -> void:
	_play_sfx(SFX_CORRECT, -1.0)
	_vibrate(40)


func play_level_complete() -> void:
	_play_sfx(SFX_LEVEL_COMPLETE, 0.0)
	_vibrate(55)


func play_record_break() -> void:
	_play_sfx(SFX_LEVEL_COMPLETE, 1.0)
	_vibrate(75)


func play_run_complete() -> void:
	_play_sfx(SFX_RUN_COMPLETE, 1.0)
	_vibrate(85)
