extends RefCounted
## Marco biselado reutilizable. Poligonos simples, sin vertices repetidos.
static func shape(rect: Rect2, cut: float) -> PackedVector2Array:
 var p := rect.position
 var e := rect.end
 return PackedVector2Array([p + Vector2(cut, 0), Vector2(e.x - cut, p.y), Vector2(e.x, p.y + cut), e - Vector2(0, cut), e - Vector2(cut, 0), Vector2(p.x + cut, e.y), Vector2(p.x, e.y - cut), p + Vector2(0, cut)])

static func render(canvas: CanvasItem, rect: Rect2, tint: Color) -> void:
 for i in range(3, 0, -1):
  canvas.draw_colored_polygon(shape(rect.grow(i * 3), 11), Color(tint, 0.045))
 canvas.draw_colored_polygon(shape(rect.grow(6), 12), Color("020619"))
 canvas.draw_colored_polygon(shape(rect.grow(3), 10), tint.darkened(0.6))
 canvas.draw_colored_polygon(shape(rect, 9), tint)
 canvas.draw_colored_polygon(shape(rect.grow(-3), 7), Color("0f2850"))
 canvas.draw_colored_polygon(shape(rect.grow(-6), 5), Color("04132d"))
 var p := rect.position
 var e := rect.end
 canvas.draw_line(p + Vector2(13, 1), Vector2(e.x - 13, p.y + 1), tint.lightened(0.4), 2)
 canvas.draw_line(Vector2(p.x + 13, e.y - 1), e - Vector2(13, 1), tint.darkened(0.4), 2)
 canvas.draw_line(p + Vector2(1, 14), Vector2(p.x + 1, e.y - 14), tint.lightened(0.2), 2)
 for x in [p.x + 9, e.x - 11]:
  for y in [p.y + 10, e.y - 12]:
   canvas.draw_rect(Rect2(x, y, 2, 2), Color("7493b4"))
