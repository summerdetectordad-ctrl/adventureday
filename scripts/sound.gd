extends Node
## Autoload: all audio, generated procedurally — no sound files.
## The detector tone is the heart of it: a soft warm sine that rises in pitch
## and swells gently as Summer nears something buried. Everything is tunable
## from the constants below. No sound is ever sudden or loud.

const MIX_RATE := 22050.0

# Detector tone tuning.
const TONE_FREQ_FAR := 180.0      # Hz when nothing is near
const TONE_FREQ_NEAR := 720.0     # Hz right on top of a find
const TONE_AMP_FAR := 0.015       # barely-there idle hum
const TONE_AMP_NEAR := 0.14
const TONE_GLIDE := 0.002         # per-sample smoothing (smaller = slower glide)
const TREMOLO_HZ := 5.0

var detector_active := false
var detector_strength := 0.0      # 0..1 proximity, set by the world each frame

var _player: AudioStreamPlayer
var _playback: AudioStreamGeneratorPlayback
var _freq := TONE_FREQ_FAR
var _amp := 0.0
var _phase := 0.0
var _trem_phase := 0.0


class Voice:
	var f0 := 440.0
	var f1 := 440.0
	var dur := 0.3
	var t := 0.0        # starts negative for delayed notes
	var amp := 0.2
	var phase := 0.0


var _voices: Array = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player = AudioStreamPlayer.new()
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = MIX_RATE
	gen.buffer_length = 0.08
	_player.stream = gen
	_player.volume_db = -6.0
	add_child(_player)
	_player.play()
	_playback = _player.get_stream_playback()
	set_muted(GameState.muted)


func set_muted(m: bool) -> void:
	AudioServer.set_bus_mute(0, m)


## Queue one soft sine note. Frequency glides f0 -> f1 over dur seconds,
## with a smooth sin^2 envelope so there are never any clicks or harsh edges.
func play_note(f0: float, f1: float, dur: float, amp: float, delay := 0.0) -> void:
	var v := Voice.new()
	v.f0 = f0
	v.f1 = f1
	v.dur = dur
	v.amp = amp
	v.t = -delay
	_voices.append(v)


func chime_find() -> void:
	play_note(523.25, 523.25, 0.35, 0.22)          # C5
	play_note(659.25, 659.25, 0.35, 0.22, 0.12)    # E5
	play_note(783.99, 783.99, 0.55, 0.22, 0.24)    # G5


func chime_shelf() -> void:
	play_note(392.0, 392.0, 0.4, 0.2)              # G4
	play_note(523.25, 523.25, 0.5, 0.2, 0.15)      # C5
	play_note(659.25, 659.25, 0.75, 0.18, 0.3)     # E5


func card_sound() -> void:
	play_note(660.0, 660.0, 0.3, 0.12)
	play_note(880.0, 880.0, 0.4, 0.1, 0.12)


func pop() -> void:
	play_note(700.0, 950.0, 0.08, 0.2)


func dig_sound() -> void:
	play_note(160.0, 90.0, 0.16, 0.25)
	play_note(140.0, 85.0, 0.16, 0.2, 0.18)


func ribbit() -> void:
	play_note(220.0, 140.0, 0.18, 0.25)
	play_note(200.0, 130.0, 0.22, 0.25, 0.2)


func chirp() -> void:
	play_note(1400.0, 1900.0, 0.09, 0.12)
	play_note(1600.0, 2100.0, 0.09, 0.12, 0.13)


func woof() -> void:
	play_note(170.0, 110.0, 0.12, 0.22)
	play_note(150.0, 100.0, 0.14, 0.2, 0.16)


func bell() -> void:
	play_note(1318.5, 1318.5, 0.5, 0.15)           # E6, bicycle bell-ish
	play_note(1318.5, 1318.5, 0.5, 0.12, 0.15)


func _process(_delta: float) -> void:
	if _playback == null:
		return
	var frames := _playback.get_frames_available()
	if frames <= 0:
		return
	var dt := 1.0 / MIX_RATE
	var target_amp := 0.0
	var target_freq := TONE_FREQ_FAR
	if detector_active:
		target_amp = lerpf(TONE_AMP_FAR, TONE_AMP_NEAR, detector_strength)
		target_freq = lerpf(TONE_FREQ_FAR, TONE_FREQ_NEAR, pow(detector_strength, 1.4))
	for i in frames:
		_amp = lerpf(_amp, target_amp, TONE_GLIDE)
		_freq = lerpf(_freq, target_freq, TONE_GLIDE)
		_trem_phase += dt * TREMOLO_HZ
		var trem := 0.85 + 0.15 * sin(TAU * _trem_phase)
		_phase += dt * _freq
		var s := sin(TAU * _phase) * _amp * trem
		var j := _voices.size() - 1
		while j >= 0:
			var v: Voice = _voices[j]
			v.t += dt
			if v.t >= v.dur:
				_voices.remove_at(j)
			elif v.t >= 0.0:
				var k: float = v.t / v.dur
				v.phase += dt * lerpf(v.f0, v.f1, k)
				var env := sin(PI * k)
				s += sin(TAU * v.phase) * v.amp * env * env
			j -= 1
		s = clampf(s, -0.9, 0.9)
		_playback.push_frame(Vector2(s, s))
