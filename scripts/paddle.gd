@tool
extends Node2D
## Su movimiento y las colisiones se resuelven en game.gd con subpasos.
@export var tint := Color("ff596c")
const RADIUS := 27.0
var velocity := Vector2.ZERO
var glow_time := 0.0

func _process(delta: float) -> void:
 glow_time += delta
 queue_redraw()

func _draw() -> void:
 for ring in range(5, 0, -1):
  draw_circle(Vector2.ZERO, 30 + ring * 3, Color(tint, 0.018))
 if velocity.length() > 50:
  var heading := -velocity.normalized()
  for lane in [-1, 0, 1]:
   var offset: Vector2 = heading.orthogonal() * lane * 12
   var tail := heading * minf(77, velocity.length() * 0.14)
   draw_line(offset + heading * 20, offset + tail, Color(tint, 0.15), 7)
   draw_line(offset + heading * 22, offset + tail, Color(tint.lightened(0.4), 0.55), 2)
 draw_circle(Vector2.ZERO, 37, Color(tint, 0.06))
 draw_circle(Vector2.ZERO, 32, Color(tint, 0.14))
 draw_arc(Vector2.ZERO, 31, 0, TAU, 48, tint, 1)
 draw_arc(Vector2.ZERO, 33, -PI * 0.9, PI * 0.3, 48, Color(tint.lightened(0.6), 0.8), 2)
 draw_circle(Vector2(3, 9), 29, Color(0.01, 0.04, 0.09, 0.65))
 draw_circle(Vector2.ZERO, 29, Color("081522"))
 draw_circle(Vector2.ZERO, 26, tint.darkened(0.5))
 draw_circle(Vector2(0, -3), 24, tint)
 draw_circle(Vector2(0, -3), 20, tint.darkened(0.25))
 draw_arc(Vector2(0, -3), 23, 0.2, PI * 0.8, 20, tint.darkened(0.65), 2)
 draw_arc(Vector2(0, -3), 20, PI, TAU, 18, tint.lightened(0.3), 3, false)
 draw_circle(Vector2(0, -9), 13, tint.darkened(0.5))
 draw_circle(Vector2(0, -13), 12, tint)
 draw_arc(Vector2(0, -13), 10, -PI, -0.3, 20, tint.lightened(0.75), 2)
 draw_rect(Rect2(-7, -20, 9, 5), tint.lightened(0.5))
 for i in range(4):
  var pos := Vector2.from_angle(glow_time * 1.7 + i * PI / 2) * 36
  draw_rect(Rect2(pos.round(), Vector2(2, 2)), tint.lightened(0.6))
