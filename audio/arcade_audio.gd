extends Node
var voices: Array[AudioStreamPlayer] = []
var music: AudioStreamPlayer
var sounds: Dictionary = {}
var muted := false
var cooldown := 0.0
var token_cooldown := 0.0
func _ready() -> void:
 for bus_name in ["Music", "SFX"]:
  if AudioServer.get_bus_index(bus_name) < 0:
   AudioServer.add_bus()
   AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)
 for index in 10:
  var voice := AudioStreamPlayer.new()
  voice.bus = "SFX"
  add_child(voice)
  voices.append(voice)
 music = AudioStreamPlayer.new()
 music.bus = "Music"
 music.volume_db = -5
 if ResourceLoader.exists("res://audio/arcade_loop.wav"):
  music.stream = load("res://audio/arcade_loop.wav")
  if music.stream is AudioStreamWAV:
   music.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
   music.stream.loop_begin = 0
   music.stream.loop_end = music.stream.data.size() / 2
 add_child(music)
 var specs := {"hit": [165, 0.075, -95], "wall": [940, 0.06, -610], "pickup": [620, 0.14, 750], "goal": [220, 0.65, 1000], "victory": [523, 1.2, 780], "select": [440, 0.04, 80], "button": [660, 0.10, 220], "pause": [400, 0.16, -170], "start": [660, 0.16, 220], "token_goal": [1060, 0.09, 220], "token_pickup": [700, 0.045, 430], "mid_start": [220, 0.8, 980]}
 for kind in 6: specs["activate_%d" % kind] = [280 + kind * 145, 0.17 + kind * 0.02, 800 - kind * 180]
 for event in specs:
  var values: Array = specs[event]
  sounds[event] = tone(values[0], values[1], values[2])
  for extension in ["wav", "ogg"]:
   var path := "res://audio/%s.%s" % [event, extension]
   if ResourceLoader.exists(path): sounds[event] = load(path)
func set_levels(music_level: float, effects_level: float, silent: bool) -> void:
 muted = silent
 AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(maxf(0.0001, music_level)))
 AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(maxf(0.0001, effects_level)))
 AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), silent or music_level <= 0)
 AudioServer.set_bus_mute(AudioServer.get_bus_index("SFX"), silent or effects_level <= 0)
func set_music_state(playing_match: bool, paused: bool) -> void:
 if not playing_match:
  music.stop()
 elif music.stream != null:
  if not music.playing: music.play()
  music.stream_paused = paused
func _process(delta: float) -> void:
 cooldown = maxf(0, cooldown - delta)
 token_cooldown = maxf(0, token_cooldown - delta)
func play_event(event: String) -> void:
 if muted or not sounds.has(event): return
 if cooldown > 0 and event in ["hit", "wall", "select"]: return
 if token_cooldown > 0 and event in ["token_goal", "token_pickup"]: return
 var selected: AudioStreamPlayer = null
 for voice in voices:
  if not voice.playing:
   selected = voice
   break
 if selected == null and event in ["goal", "victory", "mid_start"]: selected = voices[0]
 if selected == null: return
 selected.stream = sounds[event]
 selected.volume_db = -3 if event in ["goal", "victory"] else (-15 if event.begins_with("token") else -9)
 selected.play()
 if event in ["hit", "wall", "select"]: cooldown = 0.04
 if event.begins_with("token"): token_cooldown = 0.06
func tone(frequency: float, duration: float, slide: float) -> AudioStreamWAV:
 var stream := AudioStreamWAV.new()
 stream.format = AudioStreamWAV.FORMAT_16_BITS
 stream.mix_rate = 22050
 var count := int(duration * 22050)
 var data := PackedByteArray()
 data.resize(count * 2)
 var oscillator := 0.0
 for index in count:
  var progress := float(index) / count
  oscillator += TAU * maxf(50, frequency + slide * progress) / 22050.0
  var wave := sin(oscillator) * 0.65 + sin(oscillator * 2.01) * 0.22 + sin(oscillator * 3.97) * 0.13
  var sample := wave * (1 - progress) * minf(progress * 35, 1) * 0.7
  data.encode_s16(index * 2, int(sample * 32767))
 stream.data = data
 return stream
func _exit_tree() -> void:
 if is_instance_valid(music):
  music.stop()
  music.stream = null
 for voice in voices:
  voice.stop()
  voice.stream = null
 voices.clear()
 sounds.clear()
