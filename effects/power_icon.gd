extends RefCounted
const Rules = preload("res://scripts/rules.gd")
const MAPS := [
 ["011111110", "111111111", "111111111", "011111110", "011111110", "001111100", "000111000", "000010000"],
 ["000111000", "001110000", "011100000", "111111110", "000011100", "000111000", "001110000", "001000000"],
 ["110011000", "011001100", "001100110", "000110011", "000110011", "001100110", "011001100", "110011000"],
 ["000010000", "000110000", "001111000", "011111010", "011111110", "111011111", "011001110", "001111100"],
 ["000010000", "000111000", "111111111", "011111110", "001111100", "011111110", "011000110", "010000010"],
 ["110000011", "110000011", "110000011", "110000011", "110000011", "111000111", "011111110", "001111100"]
]
static func draw_icon(canvas: CanvasItem, kind: int, center: Vector2, radius: float = 20.0, alpha: float = 1.0) -> void:
 var tint: Color = Rules.POWER_COLORS[kind]
 tint.a = alpha
 for i in range(3, 0, -1):
  var glow := tint
  glow.a = 0.07 * alpha
  canvas.draw_circle(center, radius + i * 3, glow)
 canvas.draw_circle(center, radius, Color(0.015, 0.04, 0.13, 0.95 * alpha))
 canvas.draw_arc(center, radius, 0, TAU, 32, tint, 2, false)
 canvas.draw_arc(center, radius - 2, -PI, -0.35, 24, Color(tint.lightened(0.65), alpha * 0.8), 1)
 canvas.draw_arc(center, radius + 3, 0.15, PI * 0.8, 20, Color(tint, alpha * 0.4), 1)
 var unit := maxf(1.0, floorf(radius / 7.0))
 var origin := center - Vector2(4.5, 4) * unit
 var bitmap: Array = MAPS[kind]
 for y in bitmap.size():
  for x in bitmap[y].length():
   if bitmap[y][x] == "1":
    canvas.draw_rect(Rect2(origin + Vector2(x, y) * unit, Vector2.ONE * unit), tint)
