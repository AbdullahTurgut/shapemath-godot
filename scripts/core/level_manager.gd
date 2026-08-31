class_name LevelManager
extends Node

signal level_completed
signal level_reset

@export var levels: Array[LevelData] = []
@export var piece_scene: PackedScene = preload("res://scenes/pieces/draggable_piece.tscn")
@export var current_level_index: int = 0
@export var transition_delay: float = 0.85
@export var summary_delay: float = 1.0

# Containers & Shared Nodes
@export_group("Scene References")
@export var shape_container: Node2D
@export var math_container: Node2D
@export var math_target_zone: Area2D
@export var prompt_label: Label
@export var success_label: Label
@export var level_indicator_label: Label
@export var streak_label: Label
@export var next_button: Button
@export var restart_button: Button

# Run Summary UI References
@export_group("Run Summary UI")
@export var run_complete_overlay: Control
@export var summary_final_streak_label: Label
@export var summary_best_streak_label: Label
@export var play_again_button: Button

# Feedback System
@export_group("Feedback")
@export var feedback_manager: FeedbackManager

var current_level_data: LevelData = null
var is_completed: bool = false
var is_run_completed: bool = false
var current_streak: int = 0
var best_streak_this_run: int = 0

var active_tween: Tween = null
var label_tween: Tween = null
var streak_tween: Tween = null
var transition_tween: Tween = null
var summary_tween: Tween = null

# Active runtime piece references
var math_pieces: Array[DraggablePiece] = []
var shape_pieces: Array[DraggablePiece] = []
var shape_piece_a: DraggablePiece = null
var shape_piece_b: DraggablePiece = null


func _ready() -> void:
	current_streak = 0
	best_streak_this_run = 0
	is_run_completed = false
	if run_complete_overlay:
		run_complete_overlay.visible = false
	_ensure_levels_loaded()
	load_level(current_level_index)


func _ensure_levels_loaded() -> void:
	if levels.is_empty():
		for i in range(1, 6):
			var path: String = "res://data/levels/level_%02d.tres" % i
			if ResourceLoader.exists(path):
				var lvl: LevelData = load(path)
				if lvl:
					levels.append(lvl)


func _cancel_pending_transition() -> void:
	if transition_tween and transition_tween.is_valid():
		transition_tween.kill()
		transition_tween = null
	if summary_tween and summary_tween.is_valid():
		summary_tween.kill()
		summary_tween = null


func load_level(index: int) -> void:
	_ensure_levels_loaded()
	if levels.is_empty():
		push_error("LevelManager: No LevelData resources loaded!")
		return

	if index < 0 or index >= levels.size():
		push_error("LevelManager: Invalid level index %d (max: %d)" % [index, levels.size() - 1])
		return

	_cancel_pending_transition()

	current_level_index = index
	current_level_data = levels[current_level_index]
	is_completed = false
	is_run_completed = false

	if active_tween and active_tween.is_valid():
		active_tween.kill()
		active_tween = null
	if label_tween and label_tween.is_valid():
		label_tween.kill()
		label_tween = null

	# Reset UI
	if run_complete_overlay:
		run_complete_overlay.visible = false
	if restart_button:
		restart_button.visible = true
	if success_label:
		success_label.visible = false
		success_label.scale = Vector2.ONE
		success_label.modulate = Color.WHITE
		success_label.text = "Harika!"
	if next_button:
		next_button.visible = false
	if prompt_label:
		prompt_label.visible = true
		prompt_label.text = current_level_data.prompt_text
	if level_indicator_label:
		level_indicator_label.text = "Bölüm %d / %d" % [current_level_index + 1, levels.size()]

	# Update streak display without animation on level load
	_update_streak_ui(false)

	# Clear previous pieces
	_cleanup_current_pieces()

	# Build puzzle according to type
	match current_level_data.puzzle_type:
		LevelData.PuzzleType.MATH_MATCH:
			_setup_math_level()
		LevelData.PuzzleType.SHAPE_MATCH:
			_setup_shape_level()

	print("LOADED LEVEL %d: %s (%s) [Streak: %d, Best: %d]" % [
		current_level_index + 1,
		current_level_data.prompt_text,
		"MATH_MATCH" if current_level_data.puzzle_type == LevelData.PuzzleType.MATH_MATCH else "SHAPE_MATCH",
		current_streak,
		best_streak_this_run
	])


func _cleanup_current_pieces() -> void:
	for piece in math_pieces:
		if is_instance_valid(piece):
			if piece.piece_dropped.is_connected(_on_math_piece_dropped):
				piece.piece_dropped.disconnect(_on_math_piece_dropped)
			piece.disable_drag()
			piece.visible = false
			piece.queue_free()
	math_pieces.clear()

	for piece in shape_pieces:
		if is_instance_valid(piece):
			if piece.piece_dropped.is_connected(_on_shape_piece_dropped):
				piece.piece_dropped.disconnect(_on_shape_piece_dropped)
			piece.disable_drag()
			piece.visible = false
			piece.queue_free()
	shape_pieces.clear()
	shape_piece_a = null
	shape_piece_b = null


func _setup_math_level() -> void:
	if shape_container:
		shape_container.visible = false
	if math_container:
		math_container.visible = true

	var choices: Array[String] = current_level_data.answer_choices
	var count: int = choices.size()
	if count == 0:
		return

	var step_x: float = 720.0 / float(count + 1)
	var default_palette: Array[Color] = [
		Color(0.258824, 0.647059, 0.960784, 1),
		Color(0.14902, 0.65098, 0.603922, 1),
		Color(1.0, 0.439216, 0.262745, 1),
		Color(0.68, 0.38, 0.94, 1)
	]

	for i in range(count):
		var piece: DraggablePiece = piece_scene.instantiate() as DraggablePiece
		var spawn_pos: Vector2 = Vector2(step_x * (i + 1), 920.0)
		piece.piece_text = choices[i]

		if i < current_level_data.choice_colors.size() and current_level_data.choice_colors[i] != Color.BLACK:
			piece.piece_color = current_level_data.choice_colors[i]
		else:
			piece.piece_color = default_palette[i % default_palette.size()]

		if math_container:
			math_container.add_child(piece)
		else:
			add_child(piece)

		piece.set_origin_position(spawn_pos)
		piece.piece_dropped.connect(_on_math_piece_dropped)
		math_pieces.append(piece)


func _setup_shape_level() -> void:
	if math_container:
		math_container.visible = false
	if shape_container:
		shape_container.visible = true

	# Spawn Piece A
	var piece_a: DraggablePiece = piece_scene.instantiate() as DraggablePiece
	piece_a.name = "PieceA"
	piece_a.match_id = current_level_data.match_id
	piece_a.piece_color = current_level_data.piece_a_color
	piece_a.piece_text = ""
	if shape_container:
		shape_container.add_child(piece_a)
	else:
		add_child(piece_a)
	piece_a.set_origin_position(current_level_data.shape_a_spawn_pos)
	if not current_level_data.piece_a_polygon.is_empty():
		piece_a.set_custom_polygon(current_level_data.piece_a_polygon)
	piece_a.piece_dropped.connect(_on_shape_piece_dropped)
	shape_pieces.append(piece_a)
	shape_piece_a = piece_a

	# Spawn Piece B
	var piece_b: DraggablePiece = piece_scene.instantiate() as DraggablePiece
	piece_b.name = "PieceB"
	piece_b.match_id = current_level_data.match_id
	piece_b.piece_color = current_level_data.piece_b_color
	piece_b.piece_text = ""
	if shape_container:
		shape_container.add_child(piece_b)
	else:
		add_child(piece_b)
	piece_b.set_origin_position(current_level_data.shape_b_spawn_pos)
	if not current_level_data.piece_b_polygon.is_empty():
		piece_b.set_custom_polygon(current_level_data.piece_b_polygon)
	piece_b.piece_dropped.connect(_on_shape_piece_dropped)
	shape_pieces.append(piece_b)
	shape_piece_b = piece_b


func _on_shape_piece_dropped(piece: DraggablePiece) -> void:
	if is_completed:
		return

	var overlapping_areas: Array[Area2D] = piece.get_overlapping_areas()
	var matched_piece: DraggablePiece = null

	for area in overlapping_areas:
		if area is DraggablePiece and area != piece:
			if not piece.match_id.is_empty() and piece.match_id == area.match_id:
				matched_piece = area
				break

	if matched_piece != null:
		_process_shape_success(piece, matched_piece)
	else:
		print("MATCH FAILED: No valid match found for %s" % piece.name)
		if feedback_manager:
			feedback_manager.play_wrong()
		_reset_streak()
		piece.return_to_origin()


func _process_shape_success(_piece1: DraggablePiece, _piece2: DraggablePiece) -> void:
	is_completed = true
	print("MATCH SUCCESS: Level %d shape matched!" % [current_level_index + 1])

	var target_a: Vector2 = current_level_data.shape_a_target_pos
	var target_b: Vector2 = current_level_data.shape_b_target_pos

	var tween_a: Tween = null
	var tween_b: Tween = null

	if shape_piece_a:
		tween_a = shape_piece_a.play_success_feedback(target_a, 0.35)
	if shape_piece_b:
		tween_b = shape_piece_b.play_success_feedback(target_b, 0.35)

	if tween_a:
		tween_a.finished.connect(_on_completion)
	elif tween_b:
		tween_b.finished.connect(_on_completion)
	else:
		_on_completion()


func _on_math_piece_dropped(piece: DraggablePiece) -> void:
	if is_completed:
		return

	var overlapping_areas: Array[Area2D] = piece.get_overlapping_areas()
	var dropped_on_target: bool = false

	for area in overlapping_areas:
		if area == math_target_zone:
			dropped_on_target = true
			break

	if dropped_on_target and piece.piece_text == current_level_data.correct_answer:
		_process_math_success(piece)
	else:
		if dropped_on_target:
			print("MATCH FAILED: '%s' is incorrect (expected '%s')" % [piece.piece_text, current_level_data.correct_answer])
		else:
			print("MATCH FAILED: Not dropped on target zone")
		if feedback_manager:
			feedback_manager.play_wrong()
		_reset_streak()
		piece.return_to_origin()


func _process_math_success(correct_piece: DraggablePiece) -> void:
	is_completed = true
	print("MATCH SUCCESS: Correct answer '%s' placed on Level %d!" % [correct_piece.piece_text, current_level_index + 1])

	for piece in math_pieces:
		if is_instance_valid(piece) and piece != correct_piece:
			piece.disable_drag()

	var target_pos: Vector2 = math_target_zone.global_position
	var tween: Tween = correct_piece.play_success_feedback(target_pos, 0.32)
	tween.finished.connect(_on_completion)


func _on_completion() -> void:
	print("LEVEL COMPLETED: Level %d / %d" % [current_level_index + 1, levels.size()])

	# Trigger level completion feedback (SFX + haptic)
	if feedback_manager:
		feedback_manager.play_level_complete()

	# Increment streak and update best streak
	current_streak += 1
	best_streak_this_run = max(best_streak_this_run, current_streak)
	_update_streak_ui(true)

	if success_label:
		success_label.visible = true
		if current_level_index == levels.size() - 1:
			success_label.text = "Harika! Tur Tamamlandı!"
		else:
			success_label.text = "Harika!"

		# Animate "Perfect!" entrance
		if label_tween and label_tween.is_valid():
			label_tween.kill()

		success_label.pivot_offset = success_label.size / 2.0
		success_label.scale = Vector2(0.6, 0.6)
		success_label.modulate.a = 0.0

		label_tween = create_tween()
		label_tween.tween_property(success_label, "modulate:a", 1.0, 0.15)
		label_tween.parallel().tween_property(success_label, "scale", Vector2(1.15, 1.15), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		label_tween.chain().tween_property(success_label, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	if next_button:
		next_button.visible = false

	# Schedule automatic transition for Levels 1 to 4, or summary overlay for Level 5
	if current_level_index < levels.size() - 1:
		_cancel_pending_transition()
		transition_tween = create_tween()
		transition_tween.tween_interval(transition_delay)
		transition_tween.finished.connect(_on_transition_delay_finished)
	else:
		_cancel_pending_transition()
		is_run_completed = true
		summary_tween = create_tween()
		summary_tween.tween_interval(summary_delay)
		summary_tween.finished.connect(_show_run_complete_overlay)

	level_completed.emit()


func _on_transition_delay_finished() -> void:
	transition_tween = null
	if current_level_index + 1 < levels.size():
		advance_to_next_level()


func _show_run_complete_overlay() -> void:
	summary_tween = null
	if not is_run_completed:
		return

	print("SHOWING RUN COMPLETE OVERLAY - Final Streak: %d, Best Streak: %d" % [current_streak, best_streak_this_run])

	# Trigger run completion fanfare (SFX + haptic)
	if feedback_manager:
		feedback_manager.play_run_complete()

	if restart_button:
		restart_button.visible = false
	if prompt_label:
		prompt_label.visible = false
	if success_label:
		success_label.visible = false
	if streak_label:
		streak_label.visible = false
	if math_container:
		math_container.visible = false
	if shape_container:
		shape_container.visible = false

	if summary_final_streak_label:
		summary_final_streak_label.text = "Son Seri: x%d" % current_streak
	if summary_best_streak_label:
		summary_best_streak_label.text = "En İyi Seri: x%d" % best_streak_this_run

	if run_complete_overlay:
		run_complete_overlay.visible = true
		run_complete_overlay.modulate.a = 0.0

		var overlay_tween: Tween = create_tween()
		overlay_tween.tween_property(run_complete_overlay, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func start_new_run() -> void:
	print("STARTING NEW RUN (Play Again)")
	_cancel_pending_transition()

	is_run_completed = false
	current_streak = 0
	best_streak_this_run = 0

	if run_complete_overlay:
		run_complete_overlay.visible = false
		run_complete_overlay.modulate.a = 1.0

	if restart_button:
		restart_button.visible = true
	if prompt_label:
		prompt_label.visible = true

	load_level(0)


func _reset_streak() -> void:
	if current_streak != 0:
		print("STREAK RESET to 0 (Best streak preserved: %d)" % best_streak_this_run)
		current_streak = 0
		_update_streak_ui(false)


func _update_streak_ui(animate: bool = false) -> void:
	if not streak_label:
		return

	if streak_tween and streak_tween.is_valid():
		streak_tween.kill()
		streak_tween = null

	if current_streak <= 0:
		streak_label.visible = false
		streak_label.text = ""
		streak_label.scale = Vector2.ONE
		streak_label.modulate = Color.WHITE
		return

	streak_label.text = "Seri x%d" % current_streak
	streak_label.visible = true

	if animate:
		streak_label.pivot_offset = streak_label.size / 2.0
		streak_label.scale = Vector2.ONE
		streak_label.modulate = Color(1.3, 1.3, 1.3, 1.0)

		streak_tween = create_tween()
		streak_tween.tween_property(streak_label, "scale", Vector2(1.2, 1.2), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		streak_tween.parallel().tween_property(streak_label, "modulate", Color.WHITE, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		streak_tween.chain().tween_property(streak_label, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		streak_label.scale = Vector2.ONE
		streak_label.modulate = Color.WHITE


func advance_to_next_level() -> void:
	if current_level_index + 1 < levels.size():
		load_level(current_level_index + 1)
	else:
		print("Already at final level (Level %d / %d)" % [current_level_index + 1, levels.size()])


func reset_level() -> void:
	print("RESTARTING CURRENT LEVEL: %d (Resetting streak)" % [current_level_index + 1])
	_cancel_pending_transition()
	is_run_completed = false
	current_streak = 0

	if run_complete_overlay:
		run_complete_overlay.visible = false
	if restart_button:
		restart_button.visible = true
	if prompt_label:
		prompt_label.visible = true

	load_level(current_level_index)
	level_reset.emit()
