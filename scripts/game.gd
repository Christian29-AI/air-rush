extends Node2D
## Coordinador del partido; HUD, poderes, combos, bot y audio separados.
## Posiciones en píxeles; velocidades en píxeles por segundo.
const Rules = preload("res://scripts/rules.gd")
const Bot = preload("res://scripts/air_bot.gd")
const ARENA := Rules.ARENA
const CENTER := Rules.CENTER
const GOAL_TOP := Rules.GOAL_TOP
const GOAL_BOTTOM := Rules.GOAL_BOTTOM
const PUCK_RADIUS := 12.0
const PADDLE_RADIUS := 27.0
const SERVE_SPEED := 310.0
const PLAYER_SPEED := 440.0
const PROFILE_PATH := "user://air_rush_profile.cfg"
const WIN_SCORE := 7
const SUBSTEPS := 4
const RED := Color("ff596c")
const BLUE := Color("50caff")
const GOLD := Color("ffda73")
enum Phase { MENU, SERVE, PLAYING, GOAL, FINISHED }

@onready var player: Node2D = $Player
@onready var computer: Node2D = $Computer
@onready var puck: Node2D = $Puck
@onready var interface: Node2D = $Interface
@onready var powers = $Powers
@onready var combos = $Combos
@onready var audio = $ArcadeAudio
@onready var mid = $MidGame
@onready var extras = $MiniPucks
var main_goals := [0, 0]
var token_points := [0, 0]
var music_volume := 0.45
var effects_volume := 0.75
var floating_scores: Array[Dictionary] = []
var mid_flash := 0.0
var token_flash := [0.0, 0.0]
var bot := Bot.new()
var player_names := ["", ""]
var match_names := ["ROJO", "BOT"]
var game_mode := 0
var match_mode := 0
var goal_flash := 0.0
var phase := Phase.MENU
var paused := false
var score := [0, 0]
var timer := 0.0
var clock_time := 0.0
var serve_direction := 1.0
var last_scorer := 0
var mouse_control := false
var muted := false
var difficulty := 1
var match_difficulty := 1
var fullscreen := false
var trail_enabled := true
var stats := {"goals": 0, "wins": 0, "perfect_wins": 0, "hard_wins": 0}
var trail: Array[Vector2] = []
var sparks: Array[Dictionary] = []
var impact_cooldown := 0.0
var stationary_timer := 0.0
var stationary_anchor := CENTER
var rng := RandomNumberGenerator.new()

func _ready() -> void:
 rng.randomize()
 powers.collected.connect(_power_collected)
 combos.high_combo.connect(_high_combo)
 mid.started.connect(_mid_started)
 mid.collected.connect(_token_collected)
 mid.scored.connect(_token_goal)
 load_profile()
 $MainMenu.refresh()
 apply_display_mode()

func _notification(what: int) -> void:
 if what == NOTIFICATION_APPLICATION_FOCUS_OUT and phase in [Phase.SERVE, Phase.PLAYING, Phase.GOAL]:
  paused = true

func _unhandled_input(event: InputEvent) -> void:
 if phase == Phase.MENU:
  return
 if event is InputEventKey and event.pressed and not event.echo:
  match event.physical_keycode:
   KEY_ENTER, KEY_SPACE:
    _activate()
   KEY_P, KEY_ESCAPE:
    if phase != Phase.MENU and phase != Phase.FINISHED:
     paused = not paused
     _sound("pause")
   KEY_R:
    start_match()
   KEY_M:
    muted = not muted
    save_profile()
   KEY_X:
    if paused or phase == Phase.FINISHED:
     return_to_menu()
   KEY_W, KEY_A, KEY_S, KEY_D, KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT:
    mouse_control = false

func _activate() -> void:
 if paused:
  paused = false
 elif phase == Phase.MENU or phase == Phase.FINISHED:
  start_match()

func start_match() -> void:
 $MainMenu.hide()
 match_difficulty = difficulty
 match_mode = game_mode
 match_names = [clean_name(player_names[0], "ROJO"), "BOT" if match_mode == 0 else clean_name(player_names[1], "AZUL")]
 bot.configure(match_difficulty)
 score = [0, 0]
 main_goals = [0, 0]
 token_points = [0, 0]
 mid.reset()
 extras.reset()
 floating_scores.clear()
 token_flash = [0.0, 0.0]
 mid_flash = 0.0
 paused = false
 clock_time = 0.0
 serve_direction = -1.0 if rng.randf() < 0.5 else 1.0
 _reset_round()
 phase = Phase.SERVE
 timer = 2.0

func _reset_round() -> void:
 goal_flash = 0.0
 puck.position = CENTER
 puck.velocity = Vector2.ZERO
 player.position = Vector2(345, CENTER.y)
 computer.position = Vector2(935, CENTER.y)
 player.velocity = Vector2.ZERO
 computer.velocity = Vector2.ZERO
 powers.reset()
 extras.reset()
 combos.reset()
 bot.configure(match_difficulty)
 trail.clear()
 sparks.clear()
 stationary_timer = 0.0
 stationary_anchor = CENTER

func _process(delta: float) -> void:
 audio.set_levels(music_volume, effects_volume, muted)
 audio.set_music_state(phase in [Phase.SERVE, Phase.PLAYING, Phase.GOAL], paused)
 puck.tint = Color("ff642f") if powers.fire_time > 0 else (Rules.POWER_COLORS[1] if powers.super_time > 0 else GOLD)
 puck.queue_redraw()
 var shake := Vector2.ZERO
 if (goal_flash > 0 or mid_flash > 0) and not paused:
  shake = Vector2(rng.randf_range(-2, 2), rng.randf_range(-2, 2)).round()
 get_viewport().canvas_transform = Transform2D(0, shake)
 if not paused:
  mid_flash = maxf(0, mid_flash - delta)
  for side in 2: token_flash[side] = maxf(0, token_flash[side] - delta)
  for index in range(floating_scores.size() - 1, -1, -1):
   floating_scores[index].life -= delta
   floating_scores[index].pos.y -= delta * 26
   if floating_scores[index].life <= 0: floating_scores.remove_at(index)
  goal_flash = maxf(0.0, goal_flash - delta)
  for i in range(sparks.size() - 1, -1, -1):
   sparks[i].life -= delta
   sparks[i].pos += sparks[i].vel * delta
   if sparks[i].life <= 0:
    sparks.remove_at(i)
 queue_redraw()
 interface.queue_redraw()

func _physics_process(delta: float) -> void:
 if paused:
  return
 impact_cooldown = maxf(0.0, impact_cooldown - delta)
 if phase == Phase.SERVE or phase == Phase.GOAL:
  timer -= delta
  if timer <= 0:
   if phase == Phase.GOAL:
    _reset_round()
    phase = Phase.SERVE
    timer = 1.5
   else:
    phase = Phase.PLAYING
    puck.velocity = Vector2(serve_direction * SERVE_SPEED, rng.randf_range(-100, 100))
    _sound("start")
  return
 if phase != Phase.PLAYING:
  return
 clock_time += delta
 mid.tick(delta, clock_time, [player, computer], powers)
 powers.tick(delta, [player, computer])
 combos.tick(delta)
 var speed: float = PLAYER_SPEED * powers.paddle_multiplier(0)
 var target: Vector2 = get_global_mouse_position() if mouse_control else player.position + _keyboard_direction(0) * speed * delta
 var cpu_speed: float = (Bot.SPEEDS[match_difficulty] if match_mode == 0 else PLAYER_SPEED) * powers.paddle_multiplier(1)
 var cpu_target: Vector2 = bot.tick(delta, puck, computer, powers, mid) if match_mode == 0 else computer.position + _keyboard_direction(1) * cpu_speed * delta
 var current_speed: float = puck.velocity.length()
 if current_speed < 230.0:
  var direction: Vector2 = puck.velocity.normalized() if current_speed > 0.1 else Vector2(serve_direction, 0.3).normalized()
  puck.velocity = direction * 230.0
 else:
  puck.velocity = puck.velocity.normalized() * minf(current_speed + 5.0 * delta, powers.speed_limit())
 var step := delta / SUBSTEPS
 for i in SUBSTEPS:
  _move_paddle(player, target, speed, step, false)
  _move_paddle(computer, cpu_target, cpu_speed, step, true)
  puck.velocity = powers.attract(puck.position, puck.velocity, [player, computer], step)
  extras.tick(step, [player, computer], powers)
  _advance_puck(step)
  if phase != Phase.PLAYING:
   break
 if phase == Phase.PLAYING:
  _watch_corner(delta)
 trail.append(puck.position)
 if trail.size() > 14:
  trail.pop_front()

func _keyboard_direction(side: int = 0) -> Vector2:
 var keys := [KEY_D, KEY_A, KEY_S, KEY_W] if side == 0 else [KEY_RIGHT, KEY_LEFT, KEY_DOWN, KEY_UP]
 return Vector2(float(Input.is_physical_key_pressed(keys[0])) - float(Input.is_physical_key_pressed(keys[1])), float(Input.is_physical_key_pressed(keys[2])) - float(Input.is_physical_key_pressed(keys[3]))).normalized()

func _clamp_paddle(point: Vector2, is_ai: bool) -> Vector2:
 var min_x := CENTER.x + PADDLE_RADIUS + 3 if is_ai else ARENA.position.x + PADDLE_RADIUS
 var max_x := ARENA.end.x - PADDLE_RADIUS if is_ai else CENTER.x - PADDLE_RADIUS - 3
 return Vector2(clampf(point.x, min_x, max_x), clampf(point.y, ARENA.position.y + PADDLE_RADIUS, ARENA.end.y - PADDLE_RADIUS))

func _move_paddle(actor: Node2D, target: Vector2, speed: float, delta: float, is_ai: bool) -> void:
 var old := actor.position
 actor.position = _clamp_paddle(actor.position.move_toward(target, speed * delta), is_ai)
 actor.velocity = (actor.position - old) / delta

func _advance_puck(delta: float) -> void:
 puck.position += puck.velocity * delta
 _collide_paddle(player)
 _collide_paddle(computer)
 # Las bandas de arriba y abajo siempre son sólidas.
 if puck.position.y < ARENA.position.y + PUCK_RADIUS:
  puck.position.y = ARENA.position.y + PUCK_RADIUS
  puck.velocity.y = absf(puck.velocity.y)
  _wall_hit()
 elif puck.position.y > ARENA.end.y - PUCK_RADIUS:
  puck.position.y = ARENA.end.y - PUCK_RADIUS
  puck.velocity.y = -absf(puck.velocity.y)
  _wall_hit()
 var inside_goal := puck.position.y > GOAL_TOP + PUCK_RADIUS and puck.position.y < GOAL_BOTTOM - PUCK_RADIUS
 if inside_goal:
  if powers.shield[0] > 0 and puck.position.x < ARENA.position.x + PUCK_RADIUS:
   puck.position.x = ARENA.position.x + PUCK_RADIUS
   puck.velocity.x = absf(puck.velocity.x)
   _impact(Rules.POWER_COLORS[0], 6)
   _sound("activate_1")
   return
  if powers.shield[1] > 0 and puck.position.x > ARENA.end.x - PUCK_RADIUS:
   puck.position.x = ARENA.end.x - PUCK_RADIUS
   puck.velocity.x = -absf(puck.velocity.x)
   _impact(Rules.POWER_COLORS[0], 6)
   _sound("activate_1")
   return
  if puck.position.x < ARENA.position.x - PUCK_RADIUS:
   _goal(1)
  elif puck.position.x > ARENA.end.x + PUCK_RADIUS:
   _goal(0)
 else:
  if puck.position.x < ARENA.position.x + PUCK_RADIUS:
   puck.position.x = ARENA.position.x + PUCK_RADIUS
   puck.velocity.x = absf(puck.velocity.x)
   _wall_hit()
  elif puck.position.x > ARENA.end.x - PUCK_RADIUS:
   puck.position.x = ARENA.end.x - PUCK_RADIUS
   puck.velocity.x = -absf(puck.velocity.x)
   _wall_hit()

func _collide_paddle(actor: Node2D) -> void:
 var difference: Vector2 = puck.position - actor.position
 var separation := PADDLE_RADIUS + PUCK_RADIUS
 if difference.length_squared() >= separation * separation:
  return
 var normal := difference.normalized() if difference.length() > 0.001 else Vector2.LEFT
 var desired: Vector2 = actor.position + normal * (separation + 0.2)
 var legal := _legal_puck_position(desired)
 # Si separar el disco lo metería dentro de una pared, se aparta la paleta.
 # Antes se corregía solo el disco, recreando la misma penetración sin fin.
 if desired.distance_squared_to(legal) > 0.01:
  puck.position = legal
  _release_pressure(actor, normal)
  return
 puck.position = desired
 var relative: Vector2 = puck.velocity - actor.velocity
 if relative.dot(normal) < 0:
  puck.velocity = relative.bounce(normal) * 0.92 + actor.velocity * 0.75
  var side := 0 if actor == player else 1
  combos.register_hit(side, 2 if powers.combo_boost[side] > 0 else 1)
  if powers.charged[side]:
   _sound("activate_1")
  puck.velocity = powers.hit(side, puck.velocity * 1.035)
  if puck.velocity.length() < 200.0:
   puck.velocity = normal * 200.0
  _impact(GOLD, 8)
  _sound("hit")

func _legal_puck_position(point: Vector2) -> Vector2:
 var result := point
 result.y = clampf(result.y, ARENA.position.y + PUCK_RADIUS, ARENA.end.y - PUCK_RADIUS)
 if result.y <= GOAL_TOP + PUCK_RADIUS or result.y >= GOAL_BOTTOM - PUCK_RADIUS:
  result.x = clampf(result.x, ARENA.position.x + PUCK_RADIUS, ARENA.end.x - PUCK_RADIUS)
 return result

func _release_pressure(actor: Node2D, normal: Vector2) -> void:
 actor.position = _clamp_paddle(puck.position - normal * (PADDLE_RADIUS + PUCK_RADIUS + 12.0), actor == computer)
 actor.velocity = Vector2.ZERO
 # Despeje suave hacia el interior; el disco permanece donde ocurrió el choque.
 puck.velocity = (CENTER - puck.position).normalized() * 260.0
 if actor == computer:
  bot.attack_timer = 0.0
  bot.retreat_timer = 0.8
 stationary_timer = 0.0
 stationary_anchor = puck.position
 _impact(GOLD, 5)

func _watch_corner(delta: float) -> void:
 # Detecta desplazamiento real, no velocidad: un bucle de rebotes puede tener
 # velocidad elevada pero permanecer en unos pocos píxeles.
 if puck.position.distance_to(stationary_anchor) > 28.0:
  stationary_anchor = puck.position
  stationary_timer = 0.0
  return
 stationary_timer += delta
 var near_wall: bool = puck.position.x > ARENA.end.x - 58 or puck.position.y < ARENA.position.y + 58 or puck.position.y > ARENA.end.y - 58
 if stationary_timer > 0.7 and near_wall and puck.position.x > CENTER.x and computer.position.distance_to(puck.position) < 90:
  var normal: Vector2 = (puck.position - computer.position).normalized()
  if normal.is_zero_approx():
   normal = Vector2.RIGHT
  _release_pressure(computer, normal)

func _impact(tint: Color, count: int) -> void:
 if impact_cooldown <= 0:
  _burst(puck.position, tint, count)
  impact_cooldown = 0.06

func _wall_hit() -> void:
 _impact(BLUE, 3)
 _sound("wall")

func _goal(scorer: int) -> void:
 if phase != Phase.PLAYING: return
 main_goals[scorer] += 1
 score[scorer] += 50
 floating_scores.append({"pos": Vector2(390 if scorer == 0 else 890, CENTER.y - 80), "value": 50, "side": scorer, "life": 1.15})
 combos.reset()
 goal_flash = 0.35
 last_scorer = scorer
 puck.velocity = Vector2.ZERO
 _burst(puck.position, RED if scorer == 0 else BLUE, 36)
 _sound("goal")
 serve_direction = 1.0 if scorer == 0 else -1.0
 if main_goals[scorer] >= WIN_SCORE:
  phase = Phase.FINISHED
  mid.stop()
  extras.reset()
  _sound("victory")
  if scorer == 0:
   stats.wins += 1
   if main_goals[1] == 0:
    stats.perfect_wins += 1
   if match_difficulty == 2 and match_mode == 0:
    stats.hard_wins += 1
 else:
  phase = Phase.GOAL
  timer = 1.4
 if scorer == 0:
  stats.goals += 1
 save_profile()

func _burst(pos: Vector2, tint: Color, amount: int) -> void:
 for i in mini(amount, maxi(0, 180 - sparks.size())):
  sparks.append({"pos": pos, "vel": Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(35, 220), "life": rng.randf_range(0.15, 0.55), "tint": tint})

func _power_collected(side: int, kind: int) -> void:
 var actor: Node2D = player if side == 0 else computer
 _burst(actor.position, Rules.POWER_COLORS[kind], 14)
 _sound("pickup")
 _sound("activate_%d" % kind)
 if kind == 3:
  puck.velocity = puck.velocity.normalized() * minf(puck.velocity.length() + 110.0, powers.speed_limit())
 if kind == 4:
  extras.spawn(side, actor.position + Vector2(45 if side == 0 else -45, 0))

func _mid_started() -> void:
 mid_flash = 0.22
 _burst(CENTER, Color("b38aff"), 45)
 _sound("mid_start")

func _token_collected(side: int, kind: int, pos: Vector2) -> void:
 _burst(pos, mid.COLORS[kind], 4)
 _sound("token_pickup")
 match kind:
  1: powers.haste[side] = maxf(powers.haste[side], 1.5)
  2: powers.shield[side] = maxf(powers.shield[side], 1.2)
  3:
   powers.charged[side] = true
   powers.charge_time[side] = maxf(powers.charge_time[side], 4.0)
  4:
   powers.fire_time = maxf(powers.fire_time, 0.8)
   powers.fire_owner = side
   puck.velocity = puck.velocity.normalized() * minf(puck.velocity.length() + 25, powers.speed_limit())
  5: powers.combo_boost[side] = maxf(powers.combo_boost[side], 3.0)
  6: powers.magnet[side] = maxf(powers.magnet[side], 1.5)

func _token_goal(side: int, pos: Vector2) -> void:
 if phase != Phase.PLAYING or not mid.active: return
 token_points[side] += 2
 score[side] += 2
 token_flash[1 - side] = 0.12
 if floating_scores.size() < 24:
  floating_scores.append({"pos": Vector2(clampf(pos.x, ARENA.position.x + 35, ARENA.end.x - 35), pos.y), "value": 2, "side": side, "life": 0.65})
 _burst(pos, RED if side == 0 else BLUE, 5)
 _sound("token_goal")

func _high_combo(side: int, _value: int) -> void:
 _burst(player.position if side == 0 else computer.position, GOLD, 12)

func return_to_menu() -> void:
 paused = false
 phase = Phase.MENU
 mid.reset()
 floating_scores.clear()
 mid_flash = 0.0
 _reset_round()
 $MainMenu.open_home()

func clean_name(value: String, fallback: String = "") -> String:
 var result := ""
 for letter in value.strip_edges().to_upper():
  if letter in "ABCDEFGHIJKLMNOPQRSTUVWXYZÁÉÍÓÚÜÑ0123456789 -":
   result += letter
 result = result.strip_edges().left(12)
 return fallback if result.is_empty() else result

func load_profile() -> void:
 var config := ConfigFile.new()
 if config.load(PROFILE_PATH) != OK:
  return
 player_names = [clean_name(str(config.get_value("names", "red", ""))), clean_name(str(config.get_value("names", "blue", "")))]
 game_mode = clampi(int(config.get_value("settings", "game_mode", 0)), 0, 1)
 mouse_control = bool(config.get_value("settings", "mouse_control", false))
 difficulty = clampi(int(config.get_value("settings", "difficulty", 1)), 0, 2)
 music_volume = clampf(float(config.get_value("settings", "music_volume", 0.45)), 0, 1)
 effects_volume = clampf(float(config.get_value("settings", "effects_volume", 0.75)), 0, 1)
 muted = bool(config.get_value("settings", "muted", false))
 fullscreen = bool(config.get_value("settings", "fullscreen", false))
 trail_enabled = bool(config.get_value("settings", "trail", true))
 for key in stats:
  stats[key] = maxi(0, int(config.get_value("stats", key, 0)))

func save_profile() -> Error:
 var config := ConfigFile.new()
 config.set_value("names", "red", player_names[0])
 config.set_value("names", "blue", player_names[1])
 config.set_value("settings", "game_mode", game_mode)
 config.set_value("settings", "mouse_control", mouse_control)
 config.set_value("settings", "difficulty", difficulty)
 config.set_value("settings", "music_volume", music_volume)
 config.set_value("settings", "effects_volume", effects_volume)
 config.set_value("settings", "muted", muted)
 config.set_value("settings", "fullscreen", fullscreen)
 config.set_value("settings", "trail", trail_enabled)
 for key in stats:
  config.set_value("stats", key, stats[key])
 var result := config.save(PROFILE_PATH)
 if result != OK:
  push_warning("No se pudo guardar el perfil: " + error_string(result))
 return result

func apply_display_mode() -> void:
 if DisplayServer.get_name() != "headless":
  DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)

func _sound(kind: String) -> void:
 audio.muted = muted
 audio.play_event(kind)

