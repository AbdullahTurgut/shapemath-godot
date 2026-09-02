class_name SquareFillSlot
extends Area2D

@export var slot_index: int = 0
@export var is_occupied: bool = false
@export var placed_piece: DraggablePiece = null

var default_border_color: Color = Color(0.25098, 0.321569, 0.439216, 1.0)
var default_slot_color: Color = Color(0.121569, 0.141176, 0.2, 1.0)
var flash_tween: Tween = null

@onready var border: Polygon2D = get_node_or_null("Border") as Polygon2D
@onready var slot: Polygon2D = get_node_or_null("Slot") as Polygon2D
@onready var hint_visual: Polygon2D = get_node_or_null("HintVisual") as Polygon2D
@onready var hint_label: Label = get_node_or_null("HintLabel") as Label


func _ready() -> void:
	reset_slot()


func reset_slot() -> void:
	is_occupied = false
	placed_piece = null
	if flash_tween and flash_tween.is_valid():
		flash_tween.kill()
		flash_tween = null

	if border:
		border.color = default_border_color
		border.scale = Vector2.ONE
	if slot:
		slot.color = default_slot_color
		slot.scale = Vector2.ONE
	if hint_visual:
		hint_visual.visible = false
		hint_visual.modulate = Color.WHITE
	if hint_label:
		hint_label.visible = false
		hint_label.text = ""
		hint_label.modulate = Color.WHITE


func set_hint(piece_color: Color, symbol: String, hint_mode: int) -> void:
	reset_slot()
	match hint_mode:
		0: # Full / Easy
			if hint_visual:
				hint_visual.visible = true
				hint_visual.color = Color(piece_color.r, piece_color.g, piece_color.b, 0.22)
			if hint_label and not symbol.is_empty():
				hint_label.visible = true
				hint_label.text = symbol
				hint_label.modulate = Color(piece_color.r, piece_color.g, piece_color.b, 0.8)
		1: # Subtle / Medium
			if hint_visual:
				hint_visual.visible = true
				hint_visual.color = Color(1.0, 1.0, 1.0, 0.05)
			if hint_label and not symbol.is_empty():
				hint_label.visible = true
				hint_label.text = symbol
				hint_label.modulate = Color(0.5, 0.6, 0.75, 0.35)
		_: # None / Hard (hint_mode >= 2)
			if hint_visual:
				hint_visual.visible = false
			if hint_label:
				hint_label.visible = false


func flash_correct() -> void:
	if flash_tween and flash_tween.is_valid():
		flash_tween.kill()
	if not border:
		return

	flash_tween = create_tween()
	flash_tween.tween_property(border, "color", Color(0.28, 0.85, 0.45, 1.0), 0.08)
	flash_tween.chain().tween_property(border, "color", Color(0.18, 0.55, 0.35, 1.0), 0.25)


func flash_wrong() -> void:
	if flash_tween and flash_tween.is_valid():
		flash_tween.kill()
	if not border:
		return

	flash_tween = create_tween()
	flash_tween.tween_property(border, "color", Color(1.0, 0.38, 0.48, 1.0), 0.08)
	flash_tween.chain().tween_property(border, "color", default_border_color, 0.25)
