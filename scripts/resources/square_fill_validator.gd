class_name SquareFillValidator
extends RefCounted

## Validates a LevelData resource configured for PuzzleType.SQUARE_FILL.
## Returns an Array of error strings. If empty, the resource is valid.
static func validate(data: LevelData) -> Array[String]:
	var errors: Array[String] = []

	if data == null:
		errors.append("LevelData resource is null")
		return errors

	if data.puzzle_type != LevelData.PuzzleType.SQUARE_FILL:
		errors.append("PuzzleType is not SQUARE_FILL (found %s)" % str(data.puzzle_type))

	if data.tier < 1 or data.tier > 3:
		errors.append("Invalid tier %d (must be 1, 2, or 3)" % data.tier)

	if data.square_fill_hint_mode < 0 or data.square_fill_hint_mode > 2:
		errors.append("Invalid square_fill_hint_mode %d (must be 0, 1, or 2)" % data.square_fill_hint_mode)

	if data.square_fill_piece_colors.size() != 9:
		errors.append("square_fill_piece_colors must have exactly 9 entries (found %d)" % data.square_fill_piece_colors.size())

	if data.square_fill_piece_symbols.size() != 9:
		errors.append("square_fill_piece_symbols must have exactly 9 entries (found %d)" % data.square_fill_piece_symbols.size())
	else:
		for i in range(9):
			if data.square_fill_piece_symbols[i].strip_edges().is_empty():
				errors.append("square_fill_piece_symbols[%d] is empty" % i)

	# Visual uniqueness: each of the 9 pieces must have a distinguishable (color, symbol) combination
	if data.square_fill_piece_colors.size() == 9 and data.square_fill_piece_symbols.size() == 9:
		var visual_signatures: Dictionary = {}
		for i in range(9):
			var sig: String = "%s|%s" % [data.square_fill_piece_colors[i].to_html(false), data.square_fill_piece_symbols[i]]
			if visual_signatures.has(sig):
				errors.append("Pieces %d and %d have identical visual appearance (color '%s', symbol '%s')" % [
					visual_signatures[sig], i, data.square_fill_piece_colors[i].to_html(false), data.square_fill_piece_symbols[i]
				])
			visual_signatures[sig] = i

	if not data.square_fill_shelf_order.is_empty():
		if data.square_fill_shelf_order.size() != 9:
			errors.append("square_fill_shelf_order must have exactly 9 entries when specified (found %d)" % data.square_fill_shelf_order.size())
		else:
			var seen := {}
			for i in range(9):
				var val: int = data.square_fill_shelf_order[i]
				if val < 0 or val > 8:
					errors.append("square_fill_shelf_order[%d] = %d is out of range 0..8" % [i, val])
				if seen.has(val):
					errors.append("square_fill_shelf_order contains duplicate index %d" % val)
				seen[val] = true

	return errors