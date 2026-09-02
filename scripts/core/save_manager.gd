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

# Daily Challenge State
var daily_date_key: int = 0
var daily_completed: bool = false
var daily_best_solved: int = 0
var daily_best_streak: int = 0
var daily_perfect: bool = false
var daily_next_available_at_unix: int = 0


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
		daily_date_key = 0
		daily_completed = false
		daily_best_solved = 0
		daily_best_streak = 0
		daily_perfect = false
		daily_next_available_at_unix = 0
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
		daily_date_key = 0
		daily_completed = false
		daily_best_solved = 0
		daily_best_streak = 0
		daily_perfect = false
		daily_next_available_at_unix = 0
		return

	sound_enabled = bool(config.get_value("settings", "sound_enabled", true))
	haptics_enabled = bool(config.get_value("settings", "haptics_enabled", true))
	personal_best_streak = int(config.get_value("progress", "personal_best_streak", 0))
	tutorial_completed = bool(config.get_value("progress", "tutorial_completed", false))
	total_runs_started = int(config.get_value("progress", "total_runs_started", 0))
	total_runs_completed = int(config.get_value("progress", "total_runs_completed", 0))
	total_perfect_runs = int(config.get_value("progress", "total_perfect_runs", 0))
	total_puzzles_solved = int(config.get_value("progress", "total_puzzles_solved", 0))

	# Daily State with safe defaults for legacy saves
	daily_date_key = int(config.get_value("daily", "daily_date_key", 0))
	daily_completed = bool(config.get_value("daily", "daily_completed", false))
	daily_best_solved = int(config.get_value("daily", "daily_best_solved", 0))
	daily_best_streak = int(config.get_value("daily", "daily_best_streak", 0))
	daily_perfect = bool(config.get_value("daily", "daily_perfect", false))
	daily_next_available_at_unix = int(config.get_value("daily", "daily_next_available_at_unix", 0))


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

	# Daily State
	config.set_value("daily", "daily_date_key", daily_date_key)
	config.set_value("daily", "daily_completed", daily_completed)
	config.set_value("daily", "daily_best_solved", daily_best_solved)
	config.set_value("daily", "daily_best_streak", daily_best_streak)
	config.set_value("daily", "daily_perfect", daily_perfect)
	config.set_value("daily", "daily_next_available_at_unix", daily_next_available_at_unix)

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


# ==============================================================================
# DAILY CHALLENGE PERSISTENCE METHODS
# ==============================================================================

func get_daily_date_key() -> int:
	return daily_date_key


func get_daily_completed() -> bool:
	return daily_completed


func get_daily_best_solved() -> int:
	return daily_best_solved


func get_daily_best_streak() -> int:
	return daily_best_streak


func get_daily_perfect() -> bool:
	return daily_perfect


func get_daily_next_available_at_unix() -> int:
	return daily_next_available_at_unix


func is_daily_available(current_unix: int = 0) -> bool:
	if current_unix <= 0:
		current_unix = int(Time.get_unix_time_from_system())
	if daily_next_available_at_unix <= 0:
		return true
	return current_unix >= daily_next_available_at_unix


func start_new_daily_cycle(date_key: int) -> void:
	daily_date_key = date_key
	daily_completed = false
	daily_best_solved = 0
	daily_best_streak = 0
	daily_perfect = false
	daily_next_available_at_unix = 0
	save_data()


func record_daily_started(date_key: int, current_unix: int = 0) -> void:
	if is_daily_available(current_unix):
		if daily_completed or daily_date_key <= 0:
			start_new_daily_cycle(date_key)
		elif daily_date_key <= 0:
			daily_date_key = date_key
			save_data()


func record_daily_progress(solved_count: int, streak_val: int) -> void:
	var changed: bool = false
	if solved_count > daily_best_solved:
		daily_best_solved = solved_count
		changed = true
	if streak_val > daily_best_streak:
		daily_best_streak = streak_val
		changed = true
	if changed:
		save_data()


func record_daily_completed(is_perfect: bool, streak_val: int, current_unix: int = 0) -> void:
	if current_unix <= 0:
		current_unix = int(Time.get_unix_time_from_system())

	var changed: bool = false
	if not daily_completed:
		daily_completed = true
		changed = true

	# Guard: Only set/extend cooldown if no active unexpired cooldown exists
	if daily_next_available_at_unix <= 0 or current_unix >= daily_next_available_at_unix:
		daily_next_available_at_unix = current_unix + 86400
		changed = true

	if daily_best_solved < 10:
		daily_best_solved = 10
		changed = true
	if streak_val > daily_best_streak:
		daily_best_streak = streak_val
		changed = true
	if is_perfect and not daily_perfect:
		daily_perfect = true
		changed = true
	if changed:
		save_data()


