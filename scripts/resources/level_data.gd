class_name LevelData
extends Resource

enum PuzzleType {
	MATH_MATCH,
	SHAPE_MATCH,
	MISSING_NUMBER,
	EQUIVALENT_EXPRESSION,
	NUMBER_SEQUENCE,
}

@export var puzzle_type: PuzzleType = PuzzleType.MATH_MATCH
@export var prompt_text: String = ""
@export_range(1, 3) var tier: int = 1

# Math & Expression Match Fields
@export_group("Math Match")
@export var correct_answer: String = ""
@export var answer_choices: Array[String] = []
@export var choice_colors: Array[Color] = []
@export var target_display: String = ""

# Shape Match Fields
@export_group("Shape Match")
@export var match_id: String = "pair_1"
@export var piece_a_color: Color = Color(0.258824, 0.647059, 0.960784, 1)
@export var piece_b_color: Color = Color(1.0, 0.439216, 0.262745, 1)
@export var piece_a_polygon: PackedVector2Array = PackedVector2Array()
@export var piece_b_polygon: PackedVector2Array = PackedVector2Array()
@export var shape_a_spawn_pos: Vector2 = Vector2(220, 900)
@export var shape_b_spawn_pos: Vector2 = Vector2(500, 900)
@export var shape_a_target_pos: Vector2 = Vector2(300, 640)
@export var shape_b_target_pos: Vector2 = Vector2(420, 640)
