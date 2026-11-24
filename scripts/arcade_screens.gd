extends RefCounted
## Minijuegos dibujados dentro de cuadriláteros: respetan la perspectiva del CRT.
const SCREENS := [
 [Vector2(41, 388), Vector2(107, 389), Vector2(125, 458), Vector2(58, 460)],
 [Vector2(207, 389), Vector2(262, 389), Vector2(279, 457), Vector2(220, 458)],
 [Vector2(330, 416), Vector2(365, 417), Vector2(377, 467), Vector2(341, 468)],
 [Vector2(420, 419), Vector2(442, 419), Vector2(454, 463), Vector2(430, 464)],
 [Vector2(1238, 419), Vector2(1260, 418), Vector2(1246, 465), Vector2(1223, 466)],
 [Vector2(1294, 420), Vector2(1325, 418), Vector2(1308, 465), Vector2(1278, 466)],
 [Vector2(1421, 398), Vector2(1461, 395), Vector2(1440, 459), Vector2(1395, 459)],
 [Vector2(1567, 393), Vector2(1621, 389), Vector2(1602, 462), Vector2(1548, 462)]
]
const ALIEN := ["0011100", "0111110", "1101011", "1111111", "0101010"]
const SHIP := ["0001000", "0011100", "0011100", "1111111", "1101011"]

static func point(corners: Array, x: float, y: float) -> Vector2:
 var top: Vector2 = corners[0].lerp(corners[1], x / 64.0)
 var bottom: Vector2 = corners[3].lerp(corners[2], x / 64.0)
 return top.lerp(bottom, y / 80.0) * Vector2(1280.0 / 1672.0, 800.0 / 941.0)

static func rect(canvas: CanvasItem, corners: Array, box: Rect2, color: Color) -> void:
 var clipped := box.intersection(Rect2(0, 0, 64, 80))
 if not clipped.has_area():
  return
 # Al cruzar el borde puede quedar una franja casi nula. Su proyección
 # pierde precisión y los vértices coinciden; no hay nada visible que dibujar.
 if clipped.size.x < 0.001 or clipped.size.y < 0.001:
  return
 var p := clipped.position
 var e := clipped.end
 var vertices := PackedVector2Array([point(corners, p.x, p.y), point(corners, e.x, p.y), point(corners, e.x, e.y), point(corners, p.x, e.y)])
 # Son cuadriláteros convexos conocidos: la primitiva de cuatro puntos
 # evita la triangulación general, sensible a franjas subpíxel.
 canvas.draw_primitive(vertices, PackedColorArray([color]), PackedVector2Array())

static func icon(canvas: CanvasItem, corners: Array, bitmap: Array, pos: Vector2, color: Color) -> void:
 for y in bitmap.size():
  for x in bitmap[y].length():
   if bitmap[y][x] == "1":
    rect(canvas, corners, Rect2(pos + Vector2(x, y) * 1.4, Vector2(1.4, 1.4)), color)

static func render(canvas: CanvasItem, seconds: float) -> void:
 for index in SCREENS.size():
  var corners: Array = SCREENS[index]
  var t := seconds + index * 1.7
  rect(canvas, corners, Rect2(0, 0, 64, 80), Color("061c38"))
  var mode := index % 3
  if mode == 0:
   _space(canvas, corners, t)
  elif mode == 1:
   _pong(canvas, corners, t)
  else:
   _race(canvas, corners, t)
  # Líneas de barrido discretas sobre el juego, dentro de la pantalla.
  for y in range(0, 80, 4):
   rect(canvas, corners, Rect2(0, y, 64, 0.45), Color(0.1, 0.8, 1.0, 0.12))

static func _space(canvas: CanvasItem, corners: Array, t: float) -> void:
 for i in range(16):
  rect(canvas, corners, Rect2(fmod(i * 19 + 7, 62), fmod(i * 23 + t * (9 + i % 3), 80), 1, 2), Color("4797d7"))
 var player_x := 28 + sin(t * 1.7) * 20
 icon(canvas, corners, SHIP, Vector2(player_x, 68), Color("82f6ff"))
 for row in range(2):
  for column in range(3):
   var pos := Vector2(6 + column * 18 + sin(t * 1.3) * 4, 12 + row * 16)
   icon(canvas, corners, ALIEN, pos, Color("ffe170") if row == 0 else Color("fa7bc4"))
 for i in range(3):
  var y := 65 - fmod(t * 40 + i * 24, 65)
  rect(canvas, corners, Rect2(31 + sin((t - (65 - y) / 40) * 1.7) * 20, y, 2, 6), Color("e4ffff"))

static func _pong(canvas: CanvasItem, corners: Array, t: float) -> void:
 for y in range(4, 80, 8):
  rect(canvas, corners, Rect2(31, y, 1, 4), Color("347695"))
 var bx := 8 + pingpong(t * 30, 47)
 var by := 8 + pingpong(t * 23 + 15, 57)
 rect(canvas, corners, Rect2(3, clampf(by - 7 + sin(t) * 8, 1, 64), 3, 15), Color("ff88b7"))
 rect(canvas, corners, Rect2(58, clampf(by - 7 - sin(t) * 9, 1, 64), 3, 15), Color("66efff"))
 rect(canvas, corners, Rect2(bx, by, 4, 4), Color("fff7bc"))

static func _race(canvas: CanvasItem, corners: Array, t: float) -> void:
 rect(canvas, corners, Rect2(6, 0, 2, 80), Color("5cd2dc"))
 rect(canvas, corners, Rect2(56, 0, 2, 80), Color("5cd2dc"))
 for y in range(5):
  rect(canvas, corners, Rect2(31, fmod(y * 20 + t * 38, 90) - 10, 2, 9), Color("779bbe"))
 var car_x := 25 + sin(t * 1.1) * 14
 _car(canvas, corners, Vector2(car_x, 60), Color("6affb4"))
 for i in range(2):
  _car(canvas, corners, Vector2(12 + i * 25, fmod(t * 24 + i * 40, 105) - 16), Color("ff718b"))

static func _car(canvas: CanvasItem, corners: Array, pos: Vector2, tint: Color) -> void:
 rect(canvas, corners, Rect2(pos + Vector2(-2, 3), Vector2(14, 8)), Color("081b2c"))
 rect(canvas, corners, Rect2(pos, Vector2(10, 15)), tint)
 rect(canvas, corners, Rect2(pos + Vector2(2, 3), Vector2(6, 4)), Color("142f59"))
