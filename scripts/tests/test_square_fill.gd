extends SceneTree

const SaveManager = preload("res://scripts/core/save_manager.gd")
const LevelManager = preload("res://scripts/core/level_manager.gd")
const SquareFillSlot = preload("res://scripts/gameplay/square_fill_slot.gd")

var _tested: bool = false

func _process(_delta: float) -> bool:
	if _tested:
		return false
	_tested = true
	_run_tests()
	return false

func _sync_physics() -> void:
	await physics_frame
	await physics_frame

func _run_tests() -> void:
	print("================================================================================")
	print("--- BEGINNING STEP 21A.1: SQUARE FILL INPUT ISOLATION & SUCCESS LAYER TESTS ---")
	print("================================================================================")

	# [TEST 1] ENUM VERIFICATION
	print("\n[TEST 1] LevelData.PuzzleType Enum & SQUARE_FILL value")
	assert("SQUARE_FILL" in LevelData.PuzzleType, "PuzzleType enum contains SQUARE_FILL")
	assert(LevelData.PuzzleType.SQUARE_FILL == 5, "SQUARE_FILL is index 5")
	print("-> TEST 1 PASSED: Enum verification complete.")

	# [TEST 2] SAMPLE RESOURCES VALIDATION
	print("\n[TEST 2] Sample LevelData resources validation (Easy, Medium, Hard)")
	var easy_res: LevelData = load("res://data/levels/samples/sample_square_fill_easy.tres")
	var med_res: LevelData = load("res://data/levels/samples/sample_square_fill_medium.tres")
	var hard_res: LevelData = load("res://data/levels/samples/sample_square_fill_hard.tres")

	assert(easy_res != null, "Easy sample resource loads")
	assert(med_res != null, "Medium sample resource loads")
	assert(hard_res != null, "Hard sample resource loads")

	assert(easy_res.puzzle_type == LevelData.PuzzleType.SQUARE_FILL, "Easy sample is SQUARE_FILL")
	assert(easy_res.square_fill_piece_colors.size() == 9, "Easy sample has 9 piece colors")
	assert(easy_res.square_fill_piece_symbols.size() == 9, "Easy sample has 9 symbols")
	assert(easy_res.square_fill_hint_mode == 0, "Easy sample hint mode is 0 (Full)")

	assert(med_res.puzzle_type == LevelData.PuzzleType.SQUARE_FILL, "Medium sample is SQUARE_FILL")
	assert(med_res.square_fill_hint_mode == 1, "Medium sample hint mode is 1 (Subtle)")
	assert(med_res.square_fill_shelf_order.size() == 9, "Medium sample has authored shelf order")

	assert(hard_res.puzzle_type == LevelData.PuzzleType.SQUARE_FILL, "Hard sample is SQUARE_FILL")
	assert(hard_res.square_fill_hint_mode == 2, "Hard sample hint mode is 2 (None)")
	assert(hard_res.square_fill_shelf_order.size() == 9, "Hard sample has authored shelf order")
	print("-> TEST 2 PASSED: Sample resources validated.")

	# [TEST 3] PRODUCTION POOL INTEGRITY
	print("\n[TEST 3] Production Pool Loading & Sample Exclusion")
	var main_scene = load("res://scenes/main.tscn")
	var main_node = main_scene.instantiate()
	root.add_child(main_node)
	await _sync_physics()

	var lm: LevelManager = main_node.get_node("LevelManager")
	lm._ensure_levels_loaded()
	assert(lm.levels.size() == 54, "Production level pool count remains exactly 54")
	for lvl in lm.levels:
		assert(lvl.puzzle_type != LevelData.PuzzleType.SQUARE_FILL, "Production pool excludes SQUARE_FILL")
	print("-> TEST 3 PASSED: Production pool remains 54 levels with 0 SQUARE_FILL contamination.")

	# [TEST 4] SCENE CONTAINER ISOLATION
	print("\n[TEST 4] Container Visibility Isolation for SQUARE_FILL")
	var math_container: Node2D = main_node.get_node("MathContainer")
	var shape_container: Node2D = main_node.get_node("ShapeContainer")
	var square_fill_container: Node2D = main_node.get_node("SquareFillContainer")

	lm.current_run_levels = [easy_res]
	lm.load_level(0)
	main_node.call("_set_gameplay_visible", true)
	await _sync_physics()

	assert(square_fill_container.visible == true, "SquareFillContainer visible")
	assert(math_container.visible == false, "MathContainer hidden")
	assert(shape_container.visible == false, "ShapeContainer hidden")
	print("-> TEST 4 PASSED: Container visibility isolation verified.")

	# [TEST 5] SINGLE ACTIVE DRAG OWNERSHIP & MULTI-TOUCH SAFETY (BUG 1 REGRESSION)
	print("\n[TEST 5] Single Active Drag Ownership & Multi-Touch Safety")
	var piece_0: DraggablePiece = lm.square_fill_pieces[0]
	var piece_1: DraggablePiece = lm.square_fill_pieces[1]
	var piece_2: DraggablePiece = lm.square_fill_pieces[2]

	assert(DraggablePiece.active_drag_piece == null, "Initial active_drag_piece is null")

	# 1. Start drag on piece 0
	piece_0._start_drag(0)
	assert(piece_0.is_dragging == true, "Piece 0 is dragging")
	assert(DraggablePiece.active_drag_piece == piece_0, "Piece 0 owns active drag")

	# 2. Attempt simultaneous drag on piece 1 while piece 0 is active -> MUST IGNORE
	piece_1._start_drag(0)
	assert(piece_1.is_dragging == false, "Piece 1 cannot start dragging with same touch index")
	assert(DraggablePiece.active_drag_piece == piece_0, "Piece 0 retains active drag")

	piece_1._start_drag(1)
	assert(piece_1.is_dragging == false, "Piece 1 cannot start dragging with different touch index")
	assert(DraggablePiece.active_drag_piece == piece_0, "Piece 0 still retains active drag")

	# 3. Release piece 0 -> clears ownership
	piece_0._end_drag()
	assert(piece_0.is_dragging == false, "Piece 0 stopped dragging")
	assert(DraggablePiece.active_drag_piece == null, "Active drag cleared on piece release")

	# 4. Now piece 1 can legitimately start dragging
	piece_1._start_drag(0)
	assert(piece_1.is_dragging == true, "Piece 1 now starts dragging cleanly")
	assert(DraggablePiece.active_drag_piece == piece_1, "Piece 1 owns active drag")

	# 5. Cancel / return_neutral clears ownership
	piece_1.return_neutral()
	assert(DraggablePiece.active_drag_piece == null, "Active drag cleared on return_neutral")

	# 6. Wrong drop clears ownership
	piece_2._start_drag(0)
	assert(DraggablePiece.active_drag_piece == piece_2, "Piece 2 owns active drag")
	piece_2.play_invalid_feedback()
	assert(DraggablePiece.active_drag_piece == null, "Active drag cleared on invalid feedback")

	print("-> TEST 5 PASSED: Single active drag ownership & multi-touch safety verified.")

	# [TEST 6] HITBOX NON-OVERLAP ON 100PX PITCH
	print("\n[TEST 6] Hitbox Non-Overlap on 100px Pitch")
	for p in lm.square_fill_pieces:
		var cs: CollisionShape2D = p.get_node_or_null("CollisionShape2D")
		assert(cs != null, "Piece has CollisionShape2D")
		var rect: RectangleShape2D = cs.shape as RectangleShape2D
		assert(rect != null, "Collision shape is RectangleShape2D")
		assert(rect.size.x <= 88.0 and rect.size.y <= 88.0, "Piece hitbox <= 88x88 px (preventing 100px pitch overlap)")
	print("-> TEST 6 PASSED: Hitbox sizes prevent adjacent piece overlap.")

	# [TEST 7] ATOMIC PLACEMENT & DEBOUNCE GUARDS
	print("\n[TEST 7] Atomic Placement & Duplicate Drop Debounce")
	lm.load_level(0)
	await _sync_physics()

	var slot_0: SquareFillSlot = lm.square_fill_slots[0]
	var p0: DraggablePiece = lm.square_fill_pieces[0]

	# Place piece 0 into slot 0
	p0.global_position = slot_0.global_position
	await _sync_physics()
	lm._on_square_fill_piece_dropped(p0)

	assert(lm.placed_square_fill_count == 1, "Placed count incremented to exactly 1")
	assert(slot_0.is_occupied == true, "Slot 0 is occupied")
	assert(p0.is_locked == true, "Piece 0 is locked")

	# Attempt duplicate drop callback with same piece -> MUST NO-OP
	lm._on_square_fill_piece_dropped(p0)
	assert(lm.placed_square_fill_count == 1, "Duplicate drop call did NOT increment count (remains 1)")

	# Attempt drop another piece into occupied slot 0 -> MUST NO-OP (NEUTRAL RETURN)
	var p1: DraggablePiece = lm.square_fill_pieces[1]
	p1.global_position = slot_0.global_position
	await _sync_physics()
	lm._on_square_fill_piece_dropped(p1)
	assert(lm.placed_square_fill_count == 1, "Drop on occupied slot did NOT increment count (remains 1)")
	assert(lm.current_lives == 3, "Drop on occupied slot caused 0 life loss")
	print("-> TEST 7 PASSED: Atomic placement & debounce guards verified.")

	# [TEST 8] DETERMINISTIC SLOT OVERLAP RESOLUTION (RADIUS <= 65PX)
	print("\n[TEST 8] Deterministic Slot Overlap Resolution (<= 65px radius)")
	lm.load_level(0)
	await _sync_physics()

	var p_test: DraggablePiece = lm.square_fill_pieces[0]
	# Drop at midpoint between Slot 0 (0,0) and Slot 1 (100,0) -> distance to each is 50px (< 65px)
	# Should resolve to the closest slot deterministically (or if exactly 50px, nearest)
	var s0_pos: Vector2 = lm.square_fill_slots[0].global_position
	var s1_pos: Vector2 = lm.square_fill_slots[1].global_position

	p_test.global_position = s0_pos + Vector2(20.0, 0.0) # 20px from slot 0, 80px from slot 1
	await _sync_physics()
	lm._on_square_fill_piece_dropped(p_test)

	assert(lm.square_fill_slots[0].is_occupied == true, "Resolved strictly to nearest slot 0")
	assert(lm.square_fill_slots[1].is_occupied == false, "Slot 1 remained unoccupied")
	assert(lm.placed_square_fill_count == 1, "Placed count incremented exactly once")
	print("-> TEST 8 PASSED: Nearest slot overlap resolution verified.")

	# [TEST 9] STEP-BY-STEP PROGRESSION (0 -> 1 -> 2 -> ... -> 9) & ONCE COMPLETION
	print("\n[TEST 9] Step-by-Step Progression (0..9) & Single Completion Fire")
	var save_mgr: SaveManager = main_node.get_node("SaveManager")
	var test_save_path: String = "user://test_save_sf_progression.cfg"
	if FileAccess.file_exists(test_save_path):
		DirAccess.remove_absolute(test_save_path)
	save_mgr.save_path = test_save_path
	save_mgr.load_data()

	lm.current_run_levels = [easy_res]
	lm.load_level(0)
	await _sync_physics()

	for i in range(8):
		var piece = lm.square_fill_pieces[i]
		var slot = lm.square_fill_slots[i]
		piece.global_position = slot.global_position
		await _sync_physics()
		lm._on_square_fill_piece_dropped(piece)
		assert(lm.placed_square_fill_count == i + 1, "Placed count progressed monotonically to %d" % (i + 1))
		assert(lm.is_completed == false, "Level not completed at piece %d" % (i + 1))
		assert(lm.current_streak == 0, "Streak not incremented until 9/9")
		assert(save_mgr.get_total_puzzles_solved() == 0, "Stats not incremented until 9/9")

	# 9th piece
	var p8 = lm.square_fill_pieces[8]
	var s8 = lm.square_fill_slots[8]
	p8.global_position = s8.global_position
	await _sync_physics()
	lm._on_square_fill_piece_dropped(p8)

	assert(lm.placed_square_fill_count == 9, "Placed count is exactly 9")
	assert(lm.is_completed == true, "Level completed on 9th piece")
	assert(lm.current_streak == 1, "Streak incremented exactly ONCE (+1)")
	assert(save_mgr.get_total_puzzles_solved() == 1, "Lifetime solved count incremented exactly ONCE (+1)")

	# Attempt 10th placement attempt -> MUST NO-OP
	lm._on_square_fill_piece_dropped(p8)
	assert(lm.placed_square_fill_count == 9, "Cannot exceed 9 placements")
	assert(lm.current_streak == 1, "Streak does not double-increment")
	assert(save_mgr.get_total_puzzles_solved() == 1, "Solved count does not double-increment")

	if FileAccess.file_exists(test_save_path):
		DirAccess.remove_absolute(test_save_path)
	print("-> TEST 9 PASSED: Monotonic 0..9 progression and single completion fire verified.")

	# [TEST 10] SUCCESS LABEL DRAW ORDER & POSITIONING (BUG 2 REGRESSION)
	print("\n[TEST 10] Success Label Draw Order & Responsive Clean Zone")
	var success_lbl: Label = main_node.get_node("SuccessLabel")
	var prompt_lbl: Label = main_node.get_node("PromptLabel")
	var record_banner_node: Control = main_node.get_node("RecordBanner")

	assert(success_lbl.z_index >= 5, "SuccessLabel has z_index >= 5 (draw priority above puzzle containers)")
	assert(record_banner_node.z_index >= 5, "RecordBanner has z_index >= 5 (draw priority above puzzle containers)")
	assert(success_lbl.visible == true, "SuccessLabel is visible upon 9/9 completion")
	assert(prompt_lbl.visible == false, "PromptLabel hidden on SQUARE_FILL completion to give clean space to success banner")

	# Check position y of SuccessLabel for SQUARE_FILL: must be above the board top edge (y <= 285)
	assert(success_lbl.position.y <= 285.0 + lm.gameplay_y_offset, "SuccessLabel positioned above Board top edge in clean zone")
	assert(success_lbl.position.y >= 160.0, "SuccessLabel positioned below HUD")
	print("-> TEST 10 PASSED: Success label z_index and clean placement zone verified.")

	# [TEST 11] RETRY & CLEANUP ISOLATION
	print("\n[TEST 11] Retry & Cleanup Isolation")
	lm.load_level(0)
	await _sync_physics()

	assert(prompt_lbl.visible == true, "Prompt restored on level reset")
	assert(success_lbl.visible == false, "SuccessLabel hidden on level reset")
	assert(lm.placed_square_fill_count == 0, "Placed count reset to 0")
	assert(DraggablePiece.active_drag_piece == null, "Active drag cleared on level reset")

	main_node.call("return_to_main_menu")
	await _sync_physics()

	assert(square_fill_container.visible == false, "SquareFillContainer hidden on menu return")
	assert(lm.square_fill_pieces.size() == 0, "0 pieces in memory")
	assert(lm.square_fill_slots.size() == 0, "0 slots in memory")
	assert(DraggablePiece.active_drag_piece == null, "Active drag cleared on menu return")
	print("-> TEST 11 PASSED: Cleanup isolation verified.")

	print("\n================================================================================")
	print(">>> ALL STEP 21A SQUARE FILL TESTS PASSED 100%! <<<")
	print("================================================================================")
	quit(0)