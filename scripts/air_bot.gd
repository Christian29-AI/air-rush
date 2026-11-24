extends RefCounted
const Rules = preload("res://scripts/rules.gd")
const SPEEDS := [240.0, 330.0, 390.0]
const REACTIONS := [0.36, 0.19, 0.14]
const ERRORS := [75.0, 27.0, 18.0]
const MISTAKES := [0.28, 0.10, 0.015]
var level := 1
var think_timer := 0.0
var attack_timer := 0.0
var retreat_timer := 0.0
var target := Vector2(1050, Rules.CENTER.y)
var rng := RandomNumberGenerator.new()
var last_error := 0.0

func configure(difficulty: int) -> void:
 level = clampi(difficulty, 0, 2)
 rng.randomize()
 think_timer = 0
 attack_timer = 0
 retreat_timer = 0
 target = Vector2(1050, Rules.CENTER.y)

func predict_y(pos: Vector2, velocity: Vector2, at_x: float) -> float:
 var low := Rules.ARENA.position.y + 12
 var span := Rules.ARENA.size.y - 24
 var seconds := maxf(0, (at_x - pos.x) / maxf(velocity.x, 1.0))
 return low + pingpong(pos.y - low + velocity.y * seconds, span)

func tick(delta: float, puck: Node2D, paddle: Node2D, power_system: Node, mid: Node = null) -> Vector2:
 retreat_timer = maxf(0, retreat_timer - delta)
 if retreat_timer > 0:
  return Vector2(910, Rules.CENTER.y)
 if attack_timer > 0:
  attack_timer -= delta
  if attack_timer <= 0: retreat_timer = 0.27
  return target
 think_timer -= delta
 if think_timer > 0: return target
 think_timer = REACTIONS[level]
 last_error = rng.randf_range(-ERRORS[level], ERRORS[level])
 if rng.randf() < MISTAKES[level]:
  last_error *= 2.6
 # Ante un tiro fuerte, cubre el centro y deja espacio junto a los postes.
 if level == 2 and puck.velocity.x > 0 and puck.velocity.length_squared() >= 400.0 * 400.0:
  var defense_x := 1040.0
  var predicted_y := predict_y(puck.position, puck.velocity, defense_x) + last_error
  var goal_center := (Rules.GOAL_TOP + Rules.GOAL_BOTTOM) * 0.5
  target = Vector2(defense_x, clampf(predicted_y, goal_center - 31.0, goal_center + 31.0))
  return target
 var danger: bool = puck.velocity.x > 0 and puck.position.x > 780
 if not danger and not power_system.pickups.is_empty():
  var desire: float = [0.25, 0.6, 1.0][level]
  for pickup in power_system.pickups:
   if pickup.pos.x > Rules.CENTER.x and rng.randf() < desire:
    target = pickup.pos
    return target
 if not danger and mid != null and mid.active:
  var nearest := 155.0
  var found := false
  for token in mid.tokens:
   var distance: float = paddle.position.distance_to(token.pos)
   if token.pos.x > Rules.CENTER.x + 40 and distance < nearest:
    nearest = distance
    target = token.pos
    found = true
  if found: return target
 target = Vector2(1005, lerpf(Rules.CENTER.y, puck.position.y, 0.6))
 if puck.velocity.x > 0:
  target.y = predict_y(puck.position, puck.velocity, 1005) if level == 2 else puck.position.y + puck.velocity.y * 0.12
 if puck.position.x > Rules.CENTER.x + 38:
  var aim: Vector2 = (Vector2(Rules.ARENA.position.x - 15, Rules.CENTER.y) - puck.position).normalized()
  target = puck.position - aim * 46
  target.x = clampf(target.x, 670, Rules.ARENA.end.x - 27)
  target.y = clampf(target.y, Rules.ARENA.position.y + 27, Rules.ARENA.end.y - 27)
  if paddle.position.distance_to(target) < 28:
   attack_timer = 0.16
   target = puck.position + aim * 80
 target.y += last_error
 return target

