class_name SequenceValidator
extends RefCounted

## Result dictionary structure:
## {
##   "valid": bool,
##   "error": String,
##   "family": String, # "CONSTANT_ADDITIVE", "CONSTANT_DESCENDING", "GEOMETRIC_X2", "INCREASING_DIFFERENCES", "ALTERNATING_ADDITIVE"
##   "expected": int,
##   "terms": Array[int]
## }

static func validate_sequence_level(level: LevelData) -> Dictionary:
	var result := {
		"valid": false,
		"error": "",
		"family": "",
		"expected": 0,
		"terms": [] as Array[int]
	}

	if level == null:
		result.error = "LevelData is null"
		return result

	if level.puzzle_type != LevelData.PuzzleType.NUMBER_SEQUENCE:
		result.error = "puzzle_type is not NUMBER_SEQUENCE (expected %d, got %d)" % [LevelData.PuzzleType.NUMBER_SEQUENCE, level.puzzle_type]
		return result

	if level.tier < 1 or level.tier > 3:
		result.error = "Tier must be 1, 2, or 3 (got %d)" % level.tier
		return result

	# Validate prompt text format
	if level.prompt_text.is_empty():
		result.error = "prompt_text is empty"
		return result

	var prompt: String = level.prompt_text.strip_edges()

	# Final-missing format check: must end in "?"
	if not prompt.ends_with("?"):
		result.error = "Sequence prompt must end with '?' (final-missing format)"
		return result

	# Must contain separator ", ?"
	if not prompt.contains(", ?") and not prompt.ends_with(",?"):
		result.error = "Sequence prompt must end with ', ?'"
		return result

	# Check no internal '?' exists before the final slot
	var question_count: int = prompt.count("?")
	if question_count != 1:
		result.error = "Sequence must contain exactly 1 '?' in final position (found %d '?')" % question_count
		return result

	# Validate correct_answer and answer_choices
	if level.correct_answer.is_empty():
		result.error = "correct_answer is empty"
		return result

	if not level.correct_answer.strip_edges().is_valid_int():
		result.error = "correct_answer '%s' is not a valid integer" % level.correct_answer
		return result

	var correct_val: int = int(level.correct_answer.strip_edges())

	if level.answer_choices.is_empty():
		result.error = "answer_choices is empty"
		return result

	var choice_values: Array[int] = []
	var correct_count: int = 0
	for choice_str in level.answer_choices:
		var c_str: String = choice_str.strip_edges()
		if not c_str.is_valid_int():
			result.error = "answer_choice '%s' is not a valid integer" % choice_str
			return result
		var val: int = int(c_str)
		if choice_values.has(val):
			result.error = "Duplicate answer choice found: %d" % val
			return result
		choice_values.append(val)
		if val == correct_val:
			correct_count += 1

	if correct_count == 0:
		result.error = "correct_answer '%s' is not present in answer_choices" % level.correct_answer
		return result
	if correct_count > 1:
		result.error = "correct_answer '%s' appears multiple times in answer_choices" % level.correct_answer
		return result

	# Parse terms from prompt
	var prefix: String = prompt.substr(0, prompt.rfind("?")).strip_edges()
	if prefix.ends_with(","):
		prefix = prefix.substr(0, prefix.length() - 1).strip_edges()

	var parts: PackedStringArray = prefix.split(",")
	if parts.size() < 3:
		result.error = "Sequence must have at least 3 given terms for pattern deduction (found %d)" % parts.size
		return result

	var terms: Array[int] = []
	for p in parts:
		var term_str: String = p.strip_edges()
		if not term_str.is_valid_int():
			result.error = "Sequence term '%s' is not a valid integer" % term_str
			return result
		terms.append(int(term_str))

	result.terms = terms

	# Pattern Family Deduction & Validation
	var pattern_res: Dictionary = _deduce_pattern(terms, level.tier)
	if not pattern_res.valid:
		result.error = pattern_res.error
		return result

	var expected_next: int = pattern_res.expected
	result.family = pattern_res.family
	result.expected = expected_next

	if correct_val != expected_next:
		result.error = "correct_answer '%d' does not match expected sequence continuation '%d' (family: %s)" % [correct_val, expected_next, pattern_res.family]
		return result

	result.valid = true
	return result


static func _deduce_pattern(terms: Array[int], tier: int) -> Dictionary:
	var n: int = terms.size()
	if n < 3:
		return {"valid": false, "error": "Insufficient terms", "family": "", "expected": 0}

	# Check Family 1: Constant Additive Step (+d, d > 0)
	var diff0: int = terms[1] - terms[0]
	if diff0 > 0:
		var is_constant_add: bool = true
		for i in range(1, n - 1):
			if (terms[i + 1] - terms[i]) != diff0:
				is_constant_add = false
				break
		if is_constant_add:
			return {
				"valid": true,
				"error": "",
				"family": "CONSTANT_ADDITIVE",
				"expected": terms[n - 1] + diff0
			}

	# Check Family 2: Constant Descending Step (-d, d > 0) [Tier 2, 3]
	if diff0 < 0:
		var is_constant_desc: bool = true
		for i in range(1, n - 1):
			if (terms[i + 1] - terms[i]) != diff0:
				is_constant_desc = false
				break
		if is_constant_desc:
			if tier < 2:
				return {"valid": false, "error": "Descending patterns are only allowed in Tier 2 or 3", "family": "", "expected": 0}
			return {
				"valid": true,
				"error": "",
				"family": "CONSTANT_DESCENDING",
				"expected": terms[n - 1] + diff0
			}

	# Check Family 3: Geometric x2 Multiplication (terms[i+1] == terms[i] * 2) [Tier 2, 3]
	if terms[0] > 0 and terms[1] == terms[0] * 2:
		var is_geom_x2: bool = true
		for i in range(1, n - 1):
			if terms[i + 1] != terms[i] * 2:
				is_geom_x2 = false
				break
		if is_geom_x2:
			if tier < 2:
				return {"valid": false, "error": "Geometric x2 patterns are only allowed in Tier 2 or 3", "family": "", "expected": 0}
			return {
				"valid": true,
				"error": "",
				"family": "GEOMETRIC_X2",
				"expected": terms[n - 1] * 2
			}

	# Check Family 4: Increasing Additive Differences (diffs: +d, +(d+k), +(d+2k)... with k > 0) [Tier 3]
	var diffs: Array[int] = []
	for i in range(n - 1):
		diffs.append(terms[i + 1] - terms[i])

	if diffs.size() >= 3:
		var second_diff: int = diffs[1] - diffs[0]
		if second_diff > 0:
			var is_increasing_diff: bool = true
			for i in range(1, diffs.size() - 1):
				if (diffs[i + 1] - diffs[i]) != second_diff:
					is_increasing_diff = false
					break
			if is_increasing_diff:
				if tier < 3:
					return {"valid": false, "error": "Increasing differences are only allowed in Tier 3", "family": "", "expected": 0}
				var next_diff: int = diffs[diffs.size() - 1] + second_diff
				return {
					"valid": true,
					"error": "",
					"family": "INCREASING_DIFFERENCES",
					"expected": terms[n - 1] + next_diff
				}

	# Check Family 5: Alternating Additive Pattern (+a, -b, +a, -b... with a > 0, b > 0) [Tier 3]
	if diffs.size() >= 3:
		var a: int = diffs[0]
		var b: int = diffs[1]
		if a > 0 and b < 0:
			var is_alternating: bool = true
			for i in range(diffs.size()):
				var expected_d: int = a if (i % 2 == 0) else b
				if diffs[i] != expected_d:
					is_alternating = false
					break
			if is_alternating:
				if tier < 3:
					return {"valid": false, "error": "Alternating patterns are only allowed in Tier 3", "family": "", "expected": 0}
				var next_d: int = a if (diffs.size() % 2 == 0) else b
				return {
					"valid": true,
					"error": "",
					"family": "ALTERNATING_ADDITIVE",
					"expected": terms[n - 1] + next_d
				}

	return {
		"valid": false,
		"error": "Sequence pattern does not match any approved pattern family for Step 17 (terms: %s, tier: %d)" % [str(terms), tier],
		"family": "",
		"expected": 0
	}
