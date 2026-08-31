@tool
extends SceneTree

func _init() -> void:
	print("--- GENERATING PROCEDURAL AUDIO ASSETS VIA GODOT ---")
	_generate_all()
	quit(0)

func _create_wav(path: String, samples: PackedFloat32Array, sample_rate: int = 44100) -> void:
	var num_samples: int = samples.size()
	var data_size: int = num_samples * 2
	var file_size: int = 36 + data_size

	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		push_error("Failed to open file for write: %s" % path)
		return

	# RIFF chunk descriptor
	file.store_buffer("RIFF".to_ascii_buffer())
	file.store_32(file_size)
	file.store_buffer("WAVE".to_ascii_buffer())

	# fmt sub-chunk
	file.store_buffer("fmt ".to_ascii_buffer())
	file.store_32(16) # Subchunk1Size for PCM
	file.store_16(1)  # AudioFormat 1 = PCM
	file.store_16(1)  # NumChannels = 1 (Mono)
	file.store_32(sample_rate)
	file.store_32(sample_rate * 2) # ByteRate = SampleRate * NumChannels * BitsPerSample/8
	file.store_16(2)  # BlockAlign = NumChannels * BitsPerSample/8
	file.store_16(16) # BitsPerSample = 16

	# data sub-chunk
	file.store_buffer("data".to_ascii_buffer())
	file.store_32(data_size)

	for s in samples:
		var clamped: float = clampf(s, -1.0, 1.0)
		var val_16: int = int(clamped * 32767.0)
		file.store_16(val_16)

	file.close()
	print("Saved audio asset: %s (%d samples, %.2fs)" % [path, num_samples, float(num_samples) / float(sample_rate)])

func _generate_all() -> void:
	var sr: int = 44100
	DirAccess.make_dir_recursive_absolute("res://assets/audio")

	# 1. sfx_wrong.wav (soft low downward blip, 0.13s)
	var dur_wrong: float = 0.13
	var count_wrong: int = int(sr * dur_wrong)
	var samples_wrong: PackedFloat32Array = PackedFloat32Array()
	samples_wrong.resize(count_wrong)
	for i in range(count_wrong):
		var t: float = float(i) / float(sr)
		var env: float = exp(-t * 26.0)
		var freq: float = maxf(70.0, 160.0 - t * 400.0)
		samples_wrong[i] = sin(TAU * freq * t) * env * 0.45
	_create_wav("res://assets/audio/sfx_wrong.wav", samples_wrong, sr)

	# 2. sfx_correct.wav (crisp bright chime/pop, 0.15s)
	var dur_correct: float = 0.15
	var count_correct: int = int(sr * dur_correct)
	var samples_correct: PackedFloat32Array = PackedFloat32Array()
	samples_correct.resize(count_correct)
	for i in range(count_correct):
		var t: float = float(i) / float(sr)
		var env: float = exp(-t * 20.0)
		var freq: float = 587.0 + t * 1600.0
		var s: float = (0.7 * sin(TAU * freq * t) + 0.3 * sin(TAU * freq * 2.0 * t)) * env * 0.5
		samples_correct[i] = s
	_create_wav("res://assets/audio/sfx_correct.wav", samples_correct, sr)

	# 3. sfx_level_complete.wav (sparkly 2-tone melodic chime, 0.35s)
	var dur_lc: float = 0.35
	var count_lc: int = int(sr * dur_lc)
	var samples_lc: PackedFloat32Array = PackedFloat32Array()
	samples_lc.resize(count_lc)
	for i in range(count_lc):
		var t: float = float(i) / float(sr)
		var s: float = 0.0
		if t < 0.12:
			var t1: float = t
			var env1: float = exp(-t1 * 14.0)
			s = 0.5 * sin(TAU * 523.25 * t1) * env1 # C5
		else:
			var t2: float = t - 0.12
			var env2: float = exp(-t2 * 8.0)
			s = (0.5 * sin(TAU * 783.99 * t2) + 0.25 * sin(TAU * 783.99 * 2.0 * t2)) * env2 # G5
		samples_lc[i] = s * 0.5
	_create_wav("res://assets/audio/sfx_level_complete.wav", samples_lc, sr)

	# 4. sfx_run_complete.wav (triumphant 4-note ascending fanfare chime, 0.65s)
	var dur_rc: float = 0.65
	var count_rc: int = int(sr * dur_rc)
	var samples_rc: PackedFloat32Array = PackedFloat32Array()
	samples_rc.resize(count_rc)
	for i in range(count_rc):
		samples_rc[i] = 0.0

	var notes: Array = [
		{"start": 0.00, "freq": 523.25}, # C5
		{"start": 0.10, "freq": 659.25}, # E5
		{"start": 0.20, "freq": 783.99}, # G5
		{"start": 0.32, "freq": 1046.50} # C6
	]
	for note in notes:
		var start_idx: int = int(note.start * float(sr))
		var freq: float = note.freq
		var decay: float = 7.0 if freq == 1046.50 else 14.0
		for i in range(start_idx, count_rc):
			var t_note: float = float(i - start_idx) / float(sr)
			var env: float = exp(-t_note * decay)
			var s: float = (0.4 * sin(TAU * freq * t_note) + 0.15 * sin(TAU * freq * 2.0 * t_note)) * env
			samples_rc[i] += s * 0.5
	_create_wav("res://assets/audio/sfx_run_complete.wav", samples_rc, sr)

	print("--- PROCEDURAL AUDIO GENERATION COMPLETE ---")
