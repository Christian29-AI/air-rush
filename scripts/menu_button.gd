@tool
extends Button
## Botón real de Godot con dibujo pixel art y foco de mouse/teclado.
const Ink = preload("res://scripts/pixel_ink.gd")
@export var caption := "JUGAR"
@export var symbol := "play"
@export var detail := ""
@export var primary := false
var glow_time := 0.0
var highlighted := false
var click_direction := 1
const ICONS := {
 "play": ["100000000", "111000000", "111110000", "111111100", "111111111", "111111100", "111110000", "111000000", "100000000"],
 "gear": ["000111000", "010111010", "111111111", "011000110", "111000111", "011000110", "111111111", "010111010", "000111000"],
 "pad": ["001111100", "011111110", "111111111", "110111011", "100010111", "110111101", "111111111", "111000111", "110000011"],
 "cup": ["111111111", "101111101", "101111101", "111111111", "001111100", "000111000", "000010000", "000111000", "001111100"],
 "bars": ["000000011", "000000011", "000110011", "000110011", "000110011", "110110011", "110110011", "110110011", "110110011"],
 "exit": ["000111110", "000100110", "000100110", "010100110", "111110110", "010100110", "000100110", "000100110", "000111110"],
 "back": ["000100000", "001100000", "011100000", "111111110", "011100011", "001100011", "000100011", "000000011", "000111110"]
}

func _ready() -> void:
 focus_mode = Control.FOCUS_ALL
 mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
 for style in ["normal", "hover", "pressed", "focus", "disabled"]:
  add_theme_stylebox_override(style, StyleBoxEmpty.new())
 mouse_entered.connect(_hover)
 mouse_exited.connect(queue_redraw)
 focus_entered.connect(queue_redraw)
 focus_exited.connect(queue_redraw)
 button_down.connect(queue_redraw)
 button_up.connect(queue_redraw)

func _hover() -> void:
 if not Engine.is_editor_hint():
  grab_focus()
 queue_redraw()

func _gui_input(event: InputEvent) -> void:
 if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
  click_direction = -1 if event.position.x < size.x / 2 else 1

func _shape(rect: Rect2, cut: float = 10.0) -> PackedVector2Array:
 var p := rect.position
 var e := rect.end
 return PackedVector2Array([p + Vector2(cut, 0), Vector2(e.x - cut, p.y), Vector2(e.x, p.y + cut), e - Vector2(0, cut), e - Vector2(cut, 0), Vector2(p.x + cut, e.y), Vector2(p.x, e.y - cut), p + Vector2(0, cut)])

func _process(delta: float) -> void:
 if visible and (has_focus() or is_hovered() or highlighted):
  glow_time += delta
  queue_redraw()

func _draw() -> void:
 var active := highlighted or has_focus() or is_hovered()
 var edge := Color("ff6267") if primary else Color("18c8ff")
 var fill := Color("501127") if primary else Color("071c53")
 if active:
  fill = fill.lightened(0.08)
 for i in range(3, 0, -1):
  var glow := edge
  glow.a = 0.04 + ((0.035 + 0.035 * sin(glow_time * 4.0)) if active else 0.0)
  draw_colored_polygon(_shape(Rect2(Vector2.ONE * -i * 3, size + Vector2.ONE * i * 6)), glow)
 draw_colored_polygon(_shape(Rect2(Vector2(0, 6), size)), Color("03081d"))
 draw_colored_polygon(_shape(Rect2(Vector2.ZERO, size)), Color("020a2a"))
 var outline := _shape(Rect2(Vector2(3, 3), size - Vector2(6, 6)))
 draw_colored_polygon(outline, edge)
 draw_colored_polygon(_shape(Rect2(Vector2(6, 6), size - Vector2(12, 12))), fill)
 for yy in range(12, int(size.y) - 10, 6):
  for xx in range(16 + (yy % 12), int(size.x) - 14, 12):
   draw_rect(Rect2(xx, yy, 3, 3), Color(0.4, 0.6, 1, 0.055))
 draw_line(Vector2(15, 7), Vector2(size.x - 15, 7), Color("fff1ba") if primary else Color("a1eaff"), 2)
 draw_line(Vector2(16, size.y - 8), Vector2(size.x - 16, size.y - 8), edge.darkened(0.4), 2)
 var text_color := Color("fff4dd") if primary else Color("d9f7ff")
 var icon_rows: Array = ICONS.get(symbol, ICONS.play)
 var icon_origin := Vector2(30, (size.y - 27) / 2.0)
 for y in icon_rows.size():
  for x in icon_rows[y].length():
   if icon_rows[y][x] == "1":
    draw_rect(Rect2(icon_origin + Vector2(x, y) * 3, Vector2(3, 3)), text_color)
 if detail.is_empty():
  var scale_px := 4 if Ink.width(caption, 4) < size.x - 120 else 2
  Ink.text(self, caption, Vector2(size.x / 2 + 16, (size.y - 7 * scale_px) / 2), scale_px, text_color, true)
 else:
  Ink.text(self, caption, Vector2(size.x / 2 + 16, 15), 2, text_color, true)
  Ink.text(self, detail, Vector2(size.x / 2 + 16, 37), 2, Color("56efff"), true)
 if active:
  for corner in [Vector2(-7, 0), Vector2(size.x + 7, 0), Vector2(-7, size.y), Vector2(size.x + 7, size.y)]:
   var dx := 1 if corner.x < 0 else -1
   var dy := 1 if corner.y == 0 else -1
   draw_line(corner, corner + Vector2(12 * dx, 0), edge, 3)
   draw_line(corner, corner + Vector2(0, 12 * dy), edge, 3)
