class_name DraggablePiece
extends Area2D

signal drag_started(piece: DraggablePiece)
signal piece_dropped(piece: DraggablePiece)

@export var match_id: String = ""
@export var piece_id: int = -1
@export var target_slot_index: int = -1
@export var is_locked: bool = false
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

static var active_drag_piece: DraggablePiece = null

static func clear_active_drag() -> void:
	active_drag_piece = null

var return_tween: Tween = null
var scale_tween: Tween = null
var lift_tween: Tween = null
var feedback_tween: Tween = null
var _original_position_captured: bool = false

@onready var visual: Polygon2D = $Visual
@onready var shadow: Polygon2D = get_node_or_null("Shadow") as Polygon2D
@onready var border: Line2D = get_node_or_null("Border") as Line2D
@onready var value_label: Label = $ValueLabel


func set_hitbox_size(box_size: Vector2) -> void:
	var cs: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if cs:
		var rect_shape := RectangleShape2D.new()
		rect_shape.size = box_size
		cs.shape = rect_shape


func _ready() -> void:
	if not _original_position_captured:
		original_position = global_position
		_original_position_captured = true

	input_pickable = is_draggable
	if visual:
		visual.color = piece_color
		if not polygon_points.is_empty():
			visual.polygon = polygon_points
	if shadow and not polygon_points.is_empty():
		shadow.polygon = polygon_points
	if border and not polygon_points.is_empty():
		var line_pts := polygon_points.duplicate()
		line_pts.append(line_pts[0])
		border.points = line_pts

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
	if shadow and not points.is_empty():
		shadow.polygon = points
	if border and not points.is_empty():
		var line_pts := points.duplicate()
		line_pts.append(line_pts[0])
		border.points = line_pts


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
	if not is_draggable or is_dragging or is_locked:
		return

	# Enforce single active drag piece ownership
	if is_instance_valid(active_drag_piece) and active_drag_piece != self:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		_start_drag(-1)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch and event.is_pressed():
		_start_drag(event.index)
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if not is_dragging:
		return
	if active_drag_piece != self:
		return

	if active_touch_index != -1:
		if event is InputEventScreenDrag and event.index == active_touch_index:
			_update_drag_position()
			get_viewport().set_input_as_handled()
		elif event is InputEventScreenTouch and event.index == active_touch_index and not event.is_pressed():
			_end_drag()
			get_viewport().set_input_as_handled()
	else:
		if event is InputEventMouseMotion:
			_update_drag_position()
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.is_pressed():
			_end_drag()
			get_viewport().set_input_as_handled()


func _start_drag(touch_index: int) -> void:
	if not is_draggable or is_locked:
		return
	if is_instance_valid(active_drag_piece) and active_drag_piece != self:
		return

	active_drag_piece = self
	_kill_active_tweens()
	modulate = Color.WHITE

	is_dragging = true
	active_touch_index = touch_index
	drag_offset = global_position - get_global_mouse_position()
	z_index = 10

	# Pickup scale punch & shadow depth
	scale_tween = create_tween()
	scale_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	scale_tween.tween_property(self, "scale", Vector2.ONE * pickup_scale, 0.12)
	if shadow:
		var shadow_tween := create_tween()
		shadow_tween.tween_property(shadow, "position", Vector2(0.0, 8.0), 0.12)
		shadow_tween.parallel().tween_property(shadow, "color:a", 0.38, 0.12)

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
	if active_drag_piece == self:
		active_drag_piece = null

	is_dragging = false
	active_touch_index = -1
	current_lift = 0.0

	if lift_tween and lift_tween.is_valid():
		lift_tween.kill()
		lift_tween = null
	if scale_tween and scale_tween.is_valid():
		scale_tween.kill()
		scale_tween = null

	# Release scale recovery & shadow reset
	scale_tween = create_tween()
	scale_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	scale_tween.tween_property(self, "scale", Vector2.ONE, 0.12)
	if shadow:
		var shadow_tween := create_tween()
		shadow_tween.tween_property(shadow, "position", Vector2(0.0, 4.0), 0.12)
		shadow_tween.parallel().tween_property(shadow, "color:a", 0.28, 0.12)

	piece_dropped.emit(self)


func play_invalid_feedback() -> Tween:
	if active_drag_piece == self:
		active_drag_piece = null

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

	# Subtle coral/red tint
	feedback_tween.tween_property(self, "modulate", Color(1.0, 0.45, 0.45, 1.0), 0.05)

	# Horizontal springy shake around drop position (±10px, -8px, +5px)
	feedback_tween.parallel().tween_property(self, "global_position", drop_pos + Vector2(10.0, 0.0), 0.04).set_trans(Tween.TRANS_SINE)
	feedback_tween.tween_property(self, "global_position", drop_pos + Vector2(-8.0, 0.0), 0.04).set_trans(Tween.TRANS_SINE)
	feedback_tween.tween_property(self, "global_position", drop_pos + Vector2(5.0, 0.0), 0.04).set_trans(Tween.TRANS_SINE)
	feedback_tween.tween_property(self, "global_position", drop_pos, 0.04).set_trans(Tween.TRANS_SINE)

	# Restore color and glide back to origin
	feedback_tween.parallel().tween_property(self, "modulate", Color.WHITE, 0.14)
	feedback_tween.tween_property(self, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	feedback_tween.parallel().tween_property(self, "global_position", original_position, return_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if shadow:
		feedback_tween.parallel().tween_property(shadow, "position", Vector2(0.0, 4.0), return_duration)
		feedback_tween.parallel().tween_property(shadow, "color:a", 0.28, return_duration)

	feedback_tween.finished.connect(_on_invalid_feedback_finished)
	return feedback_tween


func _on_invalid_feedback_finished() -> void:
	z_index = 0
	modulate = Color.WHITE
	scale = Vector2.ONE
	if shadow:
		shadow.position = Vector2(0.0, 4.0)
		shadow.color.a = 0.28
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
		if shadow:
			shadow.position = Vector2(0.0, 4.0)
			shadow.color.a = 0.28
		z_index = 0
	)

	return feedback_tween


func disable_drag() -> void:
	if active_drag_piece == self:
		active_drag_piece = null

	is_draggable = false
	input_pickable = false
	is_dragging = false
	active_touch_index = -1
	current_lift = 0.0
	z_index = 0

	_kill_active_tweens()
	scale = Vector2.ONE
	modulate = Color.WHITE
	if shadow:
		shadow.position = Vector2(0.0, 4.0)
		shadow.color.a = 0.28


func reset_piece() -> void:
	if active_drag_piece == self:
		active_drag_piece = null

	_kill_active_tweens()

	is_dragging = false
	active_touch_index = -1
	current_lift = 0.0
	is_locked = false
	is_draggable = true
	input_pickable = true
	scale = Vector2.ONE
	modulate = Color.WHITE
	z_index = 0
	if shadow:
		shadow.position = Vector2(0.0, 4.0)
		shadow.color.a = 0.28

	if _original_position_captured:
		global_position = original_position
	else:
		original_position = global_position
		_original_position_captured = true


func return_neutral(duration: float = 0.20) -> Tween:
	if active_drag_piece == self:
		active_drag_piece = null

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
	if shadow:
		feedback_tween.parallel().tween_property(shadow, "position", Vector2(0.0, 4.0), duration)
		feedback_tween.parallel().tween_property(shadow, "color:a", 0.28, duration)
	feedback_tween.finished.connect(_on_invalid_feedback_finished)
	return feedback_tween


func cancel_drag() -> void:
	if active_drag_piece == self:
		active_drag_piece = null
	is_dragging = false
	active_touch_index = -1
	current_lift = 0.0
	_kill_active_tweens()
	return_neutral()


func return_to_origin() -> void:
	play_invalid_feedback()
