class_name SaveManager
extends Node

const DEFAULT_SAVE_PATH: String = "user://save.cfg"

@export var save_path: String = DEFAULT_SAVE_PATH

var sound_enabled: bool = true
var haptics_enabled: bool = true
var personal_best_streak: int = 0


func _ready() -> void:
	load_data()


func load_data() -> void:
	var config := ConfigFile.new()

	if not FileAccess.file_exists(save_path):
		sound_enabled = true
		haptics_enabled = true
		personal_best_streak = 0
		return

	var err: Error = config.load(save_path)
	if err != OK:
		push_warning("SaveManager: Failed to load config file at '%s' (Error %d), using safe defaults." % [save_path, err])
		sound_enabled = true
		haptics_enabled = true
		personal_best_streak = 0
		return

	sound_enabled = bool(config.get_value("settings", "sound_enabled", true))
	haptics_enabled = bool(config.get_value("settings", "haptics_enabled", true))
	personal_best_streak = int(config.get_value("progress", "personal_best_streak", 0))


func save_data() -> bool:
	var config := ConfigFile.new()
	config.set_value("settings", "sound_enabled", sound_enabled)
	config.set_value("settings", "haptics_enabled", haptics_enabled)
	config.set_value("progress", "personal_best_streak", personal_best_streak)

	var err: Error = config.save(save_path)
	if err != OK:
		push_error("SaveManager: Failed to save config file at '%s' (Error %d)." % [save_path, err])
		return false
	return true


func get_sound_enabled() -> bool:
	return sound_enabled


func set_sound_enabled(value: bool) -> void:
	if sound_enabled != value:
		sound_enabled = value
		save_data()


func get_haptics_enabled() -> bool:
	return haptics_enabled


func set_haptics_enabled(value: bool) -> void:
	if haptics_enabled != value:
		haptics_enabled = value
		save_data()


func get_personal_best_streak() -> int:
	return personal_best_streak


func update_personal_best_streak(value: int) -> bool:
	if value > personal_best_streak:
		personal_best_streak = value
		save_data()
		return true
	return false
