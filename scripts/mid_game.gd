extends Node2D
## Datos compactos: fichas y proyectiles se dibujan desde un solo nodo.
signal started
signal collected(side: int, kind: int, pos: Vector2)
signal scored(side: int, pos: Vector2)
const Rules = preload("res://scripts/rules.gd")
const START_TIME := 170.0
const END_TIME := 200.0
const CAP := 84
const COLORS := [Color("ffe466"), Color("93ff62"), Color("569aff"), Color("df7dff"), Color("ff5273"), Color("ffa849"), Color("47eeed")]
var tokens: Array[Dictionary] = []
var shots: Array[Dictionary] = []
var active := false
var triggered := false
var banner := 0.0
var elapsed := 0.0
var spawn_clock := 0.0
var collect_guard := [0.0, 0.0]
var rng := RandomNumberGenerator.new()
func _ready() -> void:
 rng.randomize()
func reset() -> void:
 active = false
 triggered = false
 banner = 0.0
 elapsed = 0.0
 spawn_clock = 0.0
 collect_guard = [0.0, 0.0]
 tokens.clear()
 shots.clear()
 queue_redraw()
func stop() -> void:
 active = false
 banner = 0
 tokens.clear()
 shots.clear()
 queue_redraw()
func tick(delta: float, match_time: float, actors: Array, powers: Node) -> void:
 if not triggered and match_time >= START_TIME:
  triggered = true
  if match_time < END_TIME:
   active = true
   banner = 1.0
   # Distribucion estratificada: llena ambas mitades sin amontonar fichas.
   for row in range(6):
    for col in range(12):
     var pos := Rules.ARENA.position + Vector2(40 + col * (Rules.ARENA.size.x - 80) / 11.0, 35 + row * (Rules.ARENA.size.y - 70) / 5.0)
     tokens.append({"pos": pos + Vector2(rng.randf_range(-12, 12), rng.randf_range(-10, 10)), "kind": (row * 12 + col) % 7, "age": -rng.randf_range(0, 0.55), "variant": rng.randi_range(0, 2), "phase": rng.randf() * TAU})
   started.emit()
 if active and match_time >= END_TIME:
  stop()
 if not active: return
 elapsed += delta
 banner = maxf(0, banner - delta)
 spawn_clock -= delta
 for side in 2: collect_guard[side] = maxf(0, collect_guard[side] - delta)
 if spawn_clock <= 0:
  spawn_clock = 0.35
  if tokens.size() + shots.size() < CAP:
   tokens.append({"pos": Vector2(rng.randf_range(Rules.ARENA.position.x + 30, Rules.ARENA.end.x - 30), rng.randf_range(Rules.ARENA.position.y + 30, Rules.ARENA.end.y - 30)), "kind": rng.randi_range(0, 6), "age": 0.0, "variant": rng.randi_range(0, 2), "phase": rng.randf() * TAU})
 for index in range(tokens.size() - 1, -1, -1):
  var token: Dictionary = tokens[index]
  token.age += delta
  if token.age < 0.2: continue
  for side in 2:
   if collect_guard[side] > 0: continue
   if actors[side].position.distance_to(token.pos) < 33:
    collect_guard[side] = 0.16
    var target := Vector2(Rules.ARENA.end.x + 20 if side == 0 else Rules.ARENA.position.x - 20, Rules.CENTER.y + rng.randf_range(-66, 66))
    var vel: Vector2 = (target - token.pos).normalized() * (420 if token.kind in [0, 6] else 350)
    shots.append({"pos": token.pos, "vel": vel, "life": 7.0, "kind": token.kind, "owner": side, "variant": token.variant})
    tokens.remove_at(index)
    collected.emit(side, token.kind, token.pos)
    break
 for index in range(shots.size() - 1, -1, -1):
  var shot: Dictionary = shots[index]
  shot.life -= delta
  if shot.life <= 0:
   shots.remove_at(index)
   continue
  shot.pos += shot.vel * delta
  # Una paleta puede devolver una ficha lanzada; no se vuelve a premiar su recogida.
  var opponent: int = 1 - shot.owner
  var offset: Vector2 = shot.pos - actors[opponent].position
  if offset.length() < 33:
   var n := offset.normalized() if offset.length() > 0.1 else Vector2.RIGHT
   shot.pos = actors[opponent].position + n * 34
   if shot.vel.dot(n) < 0:
    shot.vel = shot.vel.bounce(n)
    shot.owner = opponent
  if shot.pos.y < Rules.ARENA.position.y + 6 or shot.pos.y > Rules.ARENA.end.y - 6:
   shot.pos.y = clampf(shot.pos.y, Rules.ARENA.position.y + 6, Rules.ARENA.end.y - 6)
   shot.vel.y *= -1
  var goal_side := -1
  if shot.pos.x < Rules.ARENA.position.x + 6: goal_side = 0
  if shot.pos.x > Rules.ARENA.end.x - 6: goal_side = 1
  if goal_side < 0: continue
  var in_goal: bool = shot.pos.y > Rules.GOAL_TOP + 6 and shot.pos.y < Rules.GOAL_BOTTOM - 6
  if in_goal and powers.shield[goal_side] <= 0:
   if shot.pos.x < Rules.ARENA.position.x - 6 or shot.pos.x > Rules.ARENA.end.x + 6:
    shots.remove_at(index)
    scored.emit(1 - goal_side, shot.pos)
  else:
   shot.pos.x = clampf(shot.pos.x, Rules.ARENA.position.x + 6, Rules.ARENA.end.x - 6)
   shot.vel.x *= -1
 queue_redraw()
func _draw() -> void:
 for token in tokens:
  if token.age < 0: continue
  var pos: Vector2 = token.pos + Vector2(0, sin(elapsed * 2 + token.phase) * 2)
  _token(pos, token.kind, token.variant, minf(1, token.age * 5))
 for shot in shots:
  draw_line(shot.pos - shot.vel.normalized() * 14, shot.pos, Color(COLORS[shot.kind], 0.4), 2)
  _token(shot.pos, shot.kind, shot.variant, 1)
func _token(pos: Vector2, kind: int, variant: int, scale_value: float) -> void:
 var tint: Color = COLORS[kind]
 var r := 6.0 * scale_value
 draw_circle(pos, r + 7, Color(tint, 0.08))
 draw_circle(pos, r + 3, Color(tint, 0.18))
 draw_arc(pos, r + 1, 0, TAU, 8, tint.darkened(0.65), 2)
 # Hexagono escalonado de pixels: sin triangulacion de vertices diminutos
 # durante el primer fotograma de la animacion de aparicion.
 if variant == 0:
  draw_circle(pos, r, tint.darkened(0.2))
 else:
  draw_rect(Rect2(pos - Vector2(r, r * 0.5), Vector2(r * 2, r)), tint.darkened(0.2))
  draw_rect(Rect2(pos - Vector2(r * 0.6, r), Vector2(r * 1.2, r * 2)), tint.darkened(0.2))
 draw_arc(pos, r, -PI, 0, 8, tint.lightened(0.65), 1)
 draw_rect(Rect2(pos - Vector2(2, 2), Vector2(4, 4) * scale_value), tint.lightened(0.4) if variant == 0 else Color("10203d"))
 if variant == 2: draw_line(pos - Vector2(3, 0), pos + Vector2(3, 0), tint.lightened(0.6))
