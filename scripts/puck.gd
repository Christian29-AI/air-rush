@tool
extends Node2D
const RADIUS := 12.0
var velocity := Vector2.ZERO
var tint := Color("ffcd4c")

func _draw() -> void:
 for ring in range(4, 0, -1):
  draw_circle(Vector2.ZERO, 19 + ring * 3, Color(tint, 0.025))
 draw_circle(Vector2(2, 5), 14, Color(0, 0, 0, 0.45))
 draw_circle(Vector2.ZERO, 23, Color(tint, 0.10))
 draw_circle(Vector2.ZERO, 18, Color(tint, 0.24))
 draw_circle(Vector2.ZERO, 15, tint.darkened(0.45))
 draw_arc(Vector2.ZERO, 15, 0, TAU, 32, tint.lightened(0.45), 2)
 draw_circle(Vector2.ZERO, 12, tint)
 draw_circle(Vector2(-1, -2), 9, tint.lightened(0.45))
 draw_rect(Rect2(-6, -8, 7, 3), Color("fff4c4"))
