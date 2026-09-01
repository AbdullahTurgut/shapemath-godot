class_name DraggablePiece
extends Area2D

signal drag_started(piece: DraggablePiece)
signal piece_dropped(piece: DraggablePiece)

@export var match_id: String = ""
@export var piece_text: String = "":
	set(value):
		piece_text = value
		if is_node_ready() and value_label:
			value_label.text = piece_text
			_update_label_font_size()

@export var return_duration: float = 0.22
@export var is_draggable: bool = true
@export var touch_lift_offset: float = -45.0
@export var pickup_scale: float = 1.08
@export var piece_color: Color = Color(0.258824, 0.647059, 0.960784, 1):
	set(value):
		piece_color = value
		if is_node_ready() and visual:
			visual.color = piece_color

@export var polygon_points: PackedVector2Array = PackedVector2Array():
	set(value):
		polygon_points = value
		if is_node_ready() and visual and not polygon_points.is_empty():
			visual.polygon = polygon_points

var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var original_position: Vector2 = Vector2.ZERO
var active_touch_index: int = -1
var current_lift: float = 0.0

var return_tween: Tween = null
var scale_tween: Tween = null
var lift_tween: Tween = null
var feedback_tween: Tween = null
var _original_position_captured: bool = false

@onready var visual: Polygon2D = $Visual
@onready var value_label: Label = $ValueLabel


func _ready() -> void:
	if not _original_position_captured:
		original_position = global_position
		_original_position_captured = true

	input_pickable = is_draggable
	if visual:
		visual.color = piece_color
		if not polygon_points.is_empty():
			visual.polygon = polygon_points
	if value_label:
		value_label.text = piece_text
		_update_label_font_size()


func _update_label_font_size() -> void:
	if not value_label:
		return
	if piece_text.length() > 3:
		value_label.add_theme_font_size_override("font_size", 30)
	else:
		value_label.add_theme_font_size_override("font_size", 44)


func set_origin_position(pos: Vector2) -> void:
	original_position = pos
	global_position = pos
	_original_position_captured = true


func set_custom_polygon(points: PackedVector2Array) -> void:
	polygon_points = points
	if visual and not points.is_empty():
		visual.polygon = points


func _kill_active_tweens() -> void:
	if return_tween and return_tween.is_valid():
		return_tween.kill()
		return_tween = null
	if scale_tween and scale_tween.is_valid():
		scale_tween.kill()
		scale_tween = null
	if lift_tween and lift_tween.is_valid():
		lift_tween.kill()
		lift_tween = null
	if feedback_tween and feedback_tween.is_valid():
		feedback_tween.kill()
		feedback_tween = null


func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if not is_draggable or is_dragging:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		_start_drag(-1)
	elif event is InputEventScreenTouch and event.is_pressed():
		_start_drag(event.index)


func _unhandled_input(event: InputEvent) -> void:
	if not is_dragging:
		return

	if active_touch_index != -1:
		if event is InputEventScreenDrag and event.index == active_touch_index:
			_update_drag_position()
		elif event is InputEventScreenTouch and event.index == active_touch_index and not event.is_pressed():
			_end_drag()
	else:
		if event is InputEventMouseMotion:
			_update_drag_position()
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.is_pressed():
			_end_drag()


func _start_drag(touch_index: int) -> void:
	if not is_draggable:
		return

	_kill_active_tweens()
	modulate = Color.WHITE

	is_dragging = true
	active_touch_index = touch_index
	drag_offset = global_position - get_global_mouse_position()
	z_index = 10

	# Pickup scale punch
	scale_tween = create_tween()
	scale_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	scale_tween.tween_property(self, "scale", Vector2.ONE * pickup_scale, 0.12)

	# Touch lift to avoid finger occlusion
	if active_touch_index != -1:
		current_lift = 0.0
		lift_tween = create_tween()
		lift_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		lift_tween.tween_property(self, "current_lift", touch_lift_offset, 0.12)
	else:
		current_lift = 0.0

	drag_started.emit(self)


func _update_drag_position() -> void:
	global_position = get_global_mouse_position() + drag_offset + Vector2(0.0, current_lift)


func _end_drag() -> void:
	is_dragging = false
	active_touch_index = -1
	current_lift = 0.0

	if lift_tween and lift_tween.is_valid():
		lift_tween.kill()
		lift_tween = null
	if scale_tween and scale_tween.is_valid():
		scale_tween.kill()
		scale_tween = null

	# Release scale recovery
	scale_tween = create_tween()
	scale_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	scale_tween.tween_property(self, "scale", Vector2.ONE, 0.12)

	piece_dropped.emit(self)


func play_invalid_feedback() -> Tween:
	_kill_active_tweens()

	is_draggable = false
	input_pickable = false
	is_dragging = false
	active_touch_index = -1
	current_lift = 0.0
	z_index = 8

	var drop_pos: Vector2 = global_position
	if not _original_position_captured:
		original_position = global_position
		_original_position_captured = true

	feedback_tween = create_tween()

	# Subtle red tint
	feedback_tween.tween_property(self, "modulate", Color(1.0, 0.45, 0.45, 1.0), 0.05)

	# Horizontal shake around drop position (±12px, ±8px, ±4px)
	feedback_tween.parallel().tween_property(self, "global_position", drop_pos + Vector2(12.0, 0.0), 0.04).set_trans(Tween.TRANS_SINE)
	feedback_tween.tween_property(self, "global_position", drop_pos + Vector2(-10.0, 0.0), 0.04).set_trans(Tween.TRANS_SINE)
	feedback_tween.tween_property(self, "global_position", drop_pos + Vector2(6.0, 0.0), 0.04).set_trans(Tween.TRANS_SINE)
	feedback_tween.tween_property(self, "global_position", drop_pos, 0.04).set_trans(Tween.TRANS_SINE)

	# Restore color and glide back to origin
	feedback_tween.parallel().tween_property(self, "modulate", Color.WHITE, 0.14)
	feedback_tween.tween_property(self, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	feedback_tween.parallel().tween_property(self, "global_position", original_position, return_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	feedback_tween.finished.connect(_on_invalid_feedback_finished)
	return feedback_tween


func _on_invalid_feedback_finished() -> void:
	z_index = 0
	modulate = Color.WHITE
	scale = Vector2.ONE
	is_draggable = true
	input_pickable = true


func play_success_feedback(target_pos: Vector2, duration: float = 0.32) -> Tween:
	_kill_active_tweens()
	disable_drag()
	z_index = 5

	feedback_tween = create_tween()

	# Snap movement across full duration in parallel
	feedback_tween.tween_property(self, "global_position", target_pos, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Brightness flash & scale punch in parallel with movement
	feedback_tween.parallel().tween_property(self, "modulate", Color(1.3, 1.3, 1.3, 1.0), duration * 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	feedback_tween.parallel().tween_property(self, "scale", Vector2.ONE * 1.15, duration * 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# Return to standard modulate and scale
	feedback_tween.chain().tween_property(self, "modulate", Color.WHITE, duration * 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	feedback_tween.parallel().tween_property(self, "scale", Vector2.ONE, duration * 0.65).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	feedback_tween.finished.connect(func():
		modulate = Color.WHITE
		scale = Vector2.ONE
		z_index = 0
	)

	return feedback_tween


func disable_drag() -> void:
	is_draggable = false
	input_pickable = false
	is_dragging = false
	active_touch_index = -1
	current_lift = 0.0
	z_index = 0

	_kill_active_tweens()
	scale = Vector2.ONE
	modulate = Color.WHITE


func reset_piece() -> void:
	_kill_active_tweens()

	is_dragging = false
	active_touch_index = -1
	current_lift = 0.0
	is_draggable = true
	input_pickable = true
	scale = Vector2.ONE
	modulate = Color.WHITE
	z_index = 0

	if _original_position_captured:
		global_position = original_position
	else:
		original_position = global_position
		_original_position_captured = true


func return_neutral(duration: float = 0.20) -> Tween:
	_kill_active_tweens()
	is_draggable = false
	input_pickable = false
	is_dragging = false
	active_touch_index = -1
	current_lift = 0.0
	z_index = 2

	if not _original_position_captured:
		original_position = global_position
		_original_position_captured = true

	feedback_tween = create_tween()
	feedback_tween.tween_property(self, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	feedback_tween.parallel().tween_property(self, "global_position", original_position, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	feedback_tween.finished.connect(_on_invalid_feedback_finished)
	return feedback_tween


func return_to_origin() -> void:
	play_invalid_feedback()
