extends Node

var clips: Dictionary = {}
var voices: Array[AudioStreamPlayer] = []
var next_voice: int = 0
var muted: bool = false
var pickup_cooldown: float = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# The headless dummy audio driver cannot drain active playback during immediate test exit.
	muted = DisplayServer.get_name() == "headless"
	for key in ["orb", "vacuum", "card", "growth", "restored"]:
		clips[key] = tone(key)
	for index in 4:
		var voice := AudioStreamPlayer.new()
		voice.volume_db = -12
		add_child(voice)
		voices.append(voice)

func _process(delta: float) -> void:
	pickup_cooldown = maxf(0, pickup_cooldown - delta)

func _exit_tree() -> void:
	for voice in voices:
		voice.stop()
		voice.stream = null

func cue(key: String, pitch: float = 1.0) -> void:
	if muted or not clips.has(key) or (key == "orb" and pickup_cooldown > 0):
		return
	if key == "orb": pickup_cooldown = 0.055
	# Keep the restoration chord intact while the vacuum produces pickup cues.
	var voice := voices[0 if key == "restored" else 1 + next_voice % 3]
	next_voice += 1
	voice.stream = clips[key]
	voice.pitch_scale = pitch
	voice.play()

static func tone(key: String) -> AudioStreamWAV:
	var duration: float = {"orb": 0.12, "vacuum": 0.38, "card": 0.32, "growth": 0.6, "restored": 1.6}[key]
	var frequency: float = {"orb": 880.0, "vacuum": 440.0, "card": 523.25, "growth": 329.63, "restored": 261.63}[key]
	var samples := PackedByteArray()
	samples.resize(int(duration * 22050) * 2)
	for index in samples.size() / 2:
		var t: float = float(index) / 22050
		var envelope: float = minf(t / 0.012, 1) * pow(1 - t / duration, 2)
		var phase: float = TAU * frequency * t
		var value: float = sin(phase + (t * t * 180 if key == "vacuum" else 0)) * 0.16
		value += sin(phase * 1.5) * 0.04 + sin(phase * 2) * 0.025
		if key == "restored": value += sin(phase * 1.25) * 0.07
		samples.encode_s16(index * 2, int(value * envelope * 32767))
	var clip := AudioStreamWAV.new()
	clip.format = AudioStreamWAV.FORMAT_16_BITS
	clip.mix_rate = 22050
	clip.data = samples
	return clip
