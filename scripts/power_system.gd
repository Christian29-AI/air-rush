extends Node
signal collected(player_index: int, kind: int)
const Rules = preload("res://scripts/rules.gd")
enum Kind { SHIELD, SUPER, HASTE, FIRE, MULTIBALL, MAGNET }
var charge_time := [0.0, 0.0]
var multiball := [0.0, 0.0]
var magnet := [0.0, 0.0]
var combo_boost := [0.0, 0.0]
var shield := [0.0, 0.0]
var haste := [0.0, 0.0]
var charged := [false, false]
var fire_time := 0.0
var super_time := 0.0
var super_owner := -1
var fire_owner := -1
var pickups: Array[Dictionary] = []
var next_spawn := 2.5
var rng := RandomNumberGenerator.new()
var next_side := 0

func _ready() -> void:
 rng.randomize()

func reset() -> void:
 charge_time = [0.0, 0.0]
 multiball = [0.0, 0.0]
 magnet = [0.0, 0.0]
 combo_boost = [0.0, 0.0]
 shield = [0.0, 0.0]
 haste = [0.0, 0.0]
 charged = [false, false]
 fire_time = 0.0
 super_time = 0.0
 super_owner = -1
 fire_owner = -1
 pickups.clear()
 next_spawn = 2.5

func tick(delta: float, actors: Array) -> void:
 for index in 2:
  charge_time[index] = maxf(0, charge_time[index] - delta)
  multiball[index] = maxf(0, multiball[index] - delta)
  magnet[index] = maxf(0, magnet[index] - delta)
  combo_boost[index] = maxf(0, combo_boost[index] - delta)
  if charge_time[index] <= 0: charged[index] = false
  shield[index] = maxf(0, shield[index] - delta)
  haste[index] = maxf(0, haste[index] - delta)
 fire_time = maxf(0, fire_time - delta)
 super_time = maxf(0, super_time - delta)
 next_spawn -= delta
 if next_spawn <= 0:
  if pickups.size() < 2:
   spawn_random(actors)
  next_spawn = rng.randf_range(4.0, 6.5)
 for index in range(pickups.size() - 1, -1, -1):
  pickups[index].life -= delta
  if pickups[index].life <= 0:
   pickups.remove_at(index)
   continue
  for side in 2:
   if actors[side].position.distance_to(pickups[index].pos) <= 45.0:
    var kind: int = pickups[index].kind
    pickups.remove_at(index)
    collect(side, kind)
    break

func spawn_random(actors: Array) -> void:
 var side := next_side
 next_side = 1 - next_side
 # Cerca de la columna actual: también son alcanzables usando solo arriba/abajo.
 var x: float = clampf(actors[side].position.x, 240 if side == 0 else 695, 585 if side == 0 else 1040)
 var pos := Vector2(x, rng.randf_range(Rules.ARENA.position.y + 50, Rules.ARENA.end.y - 50))
 if pos.distance_to(actors[side].position) < 90:
  pos.y = Rules.ARENA.end.y - 50 if actors[side].position.y < Rules.CENTER.y else Rules.ARENA.position.y + 50
 pickups.append({"pos": pos, "kind": rng.randi_range(0, 5), "life": 12.0})

func collect(side: int, kind: int) -> void:
 match kind:
  Kind.SHIELD: shield[side] = 6.0
  Kind.SUPER:
   charged[side] = true
   charge_time[side] = 12.0
  Kind.HASTE: haste[side] = 5.0
  Kind.FIRE:
   fire_time = 4.0
   fire_owner = side
  Kind.MULTIBALL: multiball[side] = 6.0
  Kind.MAGNET: magnet[side] = 6.0
 collected.emit(side, kind)

func hit(side: int, velocity: Vector2) -> Vector2:
 if charged[side]:
  charged[side] = false
  charge_time[side] = 0.0
  super_time = 2.8
  super_owner = side
  return velocity.normalized() * 730.0
 return velocity.limit_length(speed_limit())

func attract(pos: Vector2, velocity: Vector2, actors: Array, delta: float) -> Vector2:
 var result := velocity
 var speed := velocity.length()
 for side in 2:
  if magnet[side] <= 0: continue
  var offset: Vector2 = actors[side].position - pos
  var distance := offset.length()
  if distance > 42 and distance < 145:
   result += offset.normalized() * (1.0 - distance / 145.0) * 240.0 * delta
 return result.normalized() * speed if not result.is_zero_approx() else velocity

func active_time(side: int, kind: int) -> float:
 match kind:
  Kind.SHIELD: return shield[side]
  Kind.SUPER: return maxf(charge_time[side], super_time if super_owner == side else 0.0)
  Kind.HASTE: return haste[side]
  Kind.FIRE: return fire_time if fire_owner == side else 0.0
  Kind.MULTIBALL: return multiball[side]
  Kind.MAGNET: return magnet[side]
 return 0.0

func speed_limit() -> float:
 return 760.0 if fire_time > 0 or super_time > 0 else 620.0

func paddle_multiplier(side: int) -> float:
 return 1.45 if haste[side] > 0 else 1.0

func status(side: int) -> String:
 var labels: Array[String] = []
 if shield[side] > 0: labels.append("ESCUDO %ds" % ceili(shield[side]))
 if charged[side]: labels.append("SUPER LISTO")
 if haste[side] > 0: labels.append("TURBO %ds" % ceili(haste[side]))
 if fire_time > 0 and fire_owner == side: labels.append("FUEGO %ds" % ceili(fire_time))
 if multiball[side] > 0: labels.append("MULTIBOLA %ds" % ceili(multiball[side]))
 if magnet[side] > 0: labels.append("IMAN %ds" % ceili(magnet[side]))
 return " / ".join(labels) if not labels.is_empty() else "SIN PODER"
