class_name SaveManager
extends Node

const DEFAULT_SAVE_PATH: String = "user://save.cfg"

@export var save_path: String = DEFAULT_SAVE_PATH

var sound_enabled: bool = true
var haptics_enabled: bool = true
var personal_best_streak: int = 0
var tutorial_completed: bool = false
var total_runs_started: int = 0
var total_runs_completed: int = 0
var total_perfect_runs: int = 0
var total_puzzles_solved: int = 0


func _ready() -> void:
	load_data()


func load_data() -> void:
	var config := ConfigFile.new()

	if not FileAccess.file_exists(save_path):
		sound_enabled = true
		haptics_enabled = true
		personal_best_streak = 0
		tutorial_completed = false
		total_runs_started = 0
		total_runs_completed = 0
		total_perfect_runs = 0
		total_puzzles_solved = 0
		return

	var err: Error = config.load(save_path)
	if err != OK:
		push_warning("SaveManager: Failed to load config file at '%s' (Error %d), using safe defaults." % [save_path, err])
		sound_enabled = true
		haptics_enabled = true
		personal_best_streak = 0
		tutorial_completed = false
		total_runs_started = 0
		total_runs_completed = 0
		total_perfect_runs = 0
		total_puzzles_solved = 0
		return

	sound_enabled = bool(config.get_value("settings", "sound_enabled", true))
	haptics_enabled = bool(config.get_value("settings", "haptics_enabled", true))
	personal_best_streak = int(config.get_value("progress", "personal_best_streak", 0))
	tutorial_completed = bool(config.get_value("progress", "tutorial_completed", false))
	total_runs_started = int(config.get_value("progress", "total_runs_started", 0))
	total_runs_completed = int(config.get_value("progress", "total_runs_completed", 0))
	total_perfect_runs = int(config.get_value("progress", "total_perfect_runs", 0))
	total_puzzles_solved = int(config.get_value("progress", "total_puzzles_solved", 0))


func save_data() -> bool:
	var config := ConfigFile.new()
	config.set_value("settings", "sound_enabled", sound_enabled)
	config.set_value("settings", "haptics_enabled", haptics_enabled)
	config.set_value("progress", "personal_best_streak", personal_best_streak)
	config.set_value("progress", "tutorial_completed", tutorial_completed)
	config.set_value("progress", "total_runs_started", total_runs_started)
	config.set_value("progress", "total_runs_completed", total_runs_completed)
	config.set_value("progress", "total_perfect_runs", total_perfect_runs)
	config.set_value("progress", "total_puzzles_solved", total_puzzles_solved)

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


func get_tutorial_completed() -> bool:
	return tutorial_completed


func set_tutorial_completed(value: bool) -> void:
	if tutorial_completed != value:
		tutorial_completed = value
		save_data()


func get_total_runs_started() -> int:
	return total_runs_started


func get_total_runs_completed() -> int:
	return total_runs_completed


func get_total_perfect_runs() -> int:
	return total_perfect_runs


func get_total_puzzles_solved() -> int:
	return total_puzzles_solved


func get_success_rate_percentage() -> int:
	if total_runs_started <= 0:
		return 0
	return int(round((float(total_runs_completed) / float(total_runs_started)) * 100.0))


func record_run_started() -> void:
	total_runs_started += 1
	save_data()


func record_puzzle_solved() -> void:
	total_puzzles_solved += 1
	save_data()


func record_run_completed(is_perfect: bool) -> void:
	total_runs_completed += 1
	if is_perfect:
		total_perfect_runs += 1
	save_data()

