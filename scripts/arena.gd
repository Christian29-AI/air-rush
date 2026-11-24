@tool
extends Node2D
## Fondo artistico sin objetos de juego incrustados. Luces animadas por codigo.
const Rules = preload("res://scripts/rules.gd")
const BACKDROP = preload("res://assets/arena_cyber_v61.png")
var pulse := 0.0
var mid_active := false
func _process(delta: float) -> void:
 pulse += delta
 if not Engine.is_editor_hint() and get_parent().has_node("MidGame"):
  mid_active = get_parent().get_node("MidGame").active
 queue_redraw()
func _draw() -> void:
 draw_texture_rect(BACKDROP, Rect2(0, 0, 1280, 800), false)
 for side in range(2):
  var tint := Rules.RED if side == 0 else Rules.BLUE
  for y in [177, 607]:
   var x := 175 + side * 490 + fmod(pulse * 90, 420)
   draw_line(Vector2(x, y), Vector2(x + 18, y), Color(tint.lightened(0.5), 0.6), 2)
  for y in [245, 535]:
   var x := 87 if side == 0 else 1180
   draw_rect(Rect2(x, y, 4, 14), Color(tint.lightened(0.5), 0.25 + sin(pulse * 3 + y) * 0.2))
 if mid_active:
  draw_line(Vector2(172, 194), Vector2(1115, 194), Color(0.9, 0.3, 1, 0.55 + sin(pulse * 6) * 0.2), 3)
  draw_line(Vector2(172, 596), Vector2(1115, 596), Color(0.7, 0.3, 1, 0.4), 2)
