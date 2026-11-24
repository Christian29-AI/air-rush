extends Node2D
## Tres señuelos por jugador. Nunca llaman al sistema de puntuacion.
const Rules = preload("res://scripts/rules.gd")
var balls: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()
func reset() -> void:
 balls.clear()
 queue_redraw()
func spawn(side: int, origin: Vector2) -> void:
 for index in range(balls.size() - 1, -1, -1):
  if balls[index].owner == side: balls.remove_at(index)
 for index in range(3):
  balls.append({"pos": origin + Vector2(0, (index - 1) * 20), "vel": Vector2(1 if side == 0 else -1, (index - 1) * 0.6).normalized() * 320, "owner": side, "color": Rules.POWER_COLORS[(index + 1) % 6]})
 queue_redraw()
func tick(delta: float, actors: Array, powers: Node) -> void:
 for index in range(balls.size() - 1, -1, -1):
  var b: Dictionary = balls[index]
  if powers.multiball[b.owner] <= 0:
   balls.remove_at(index)
   continue
  b.pos += b.vel * delta
  for actor in actors:
   var offset: Vector2 = b.pos - actor.position
   if offset.length() < 34:
    var normal := offset.normalized() if offset.length() > 0.1 else Vector2.RIGHT
    b.pos = actor.position + normal * 34
    if b.vel.dot(normal) < 0: b.vel = b.vel.bounce(normal)
  var rect := Rules.ARENA.grow(-7)
  if b.pos.x < rect.position.x or b.pos.x > rect.end.x: b.vel.x *= -1
  if b.pos.y < rect.position.y or b.pos.y > rect.end.y: b.vel.y *= -1
  b.pos = b.pos.clamp(rect.position, rect.end)
 queue_redraw()
func _draw() -> void:
 for b in balls:
  draw_circle(b.pos, 11, Color(b.color, 0.12))
  draw_arc(b.pos, 6, 0, TAU, 12, b.color, 2)
  draw_rect(Rect2(b.pos - Vector2(2, 2), Vector2(4, 4)), Color(b.color, 0.5))
