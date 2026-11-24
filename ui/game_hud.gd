extends Node2D
const Ink = preload("res://scripts/pixel_ink.gd")
const Rules = preload("res://scripts/rules.gd")
const Icon = preload("res://effects/power_icon.gd")
const ArcadeButton = preload("res://scripts/menu_button.gd")
const ArcadePanel = preload("res://effects/arcade_panel.gd")
var game: Node2D
var resume_button: Button
var menu_button: Button
var was_overlay := false
func _ready() -> void:
 game = get_parent()
 resume_button = _button(Vector2(461, 463), "REVANCHA")
 resume_button.pressed.connect(func(): game._activate())
 menu_button = _button(Vector2(461, 525), "MENU")
 menu_button.pressed.connect(func(): game.return_to_menu())
func _button(pos: Vector2, caption: String) -> Button:
 var b := Button.new()
 b.set_script(ArcadeButton)
 b.caption = caption
 b.position = pos
 b.size = Vector2(358, 52)
 b.hide()
 add_child(b)
 return b
func _process(_delta: float) -> void:
 var overlay: bool = game.phase != game.Phase.MENU and (game.paused or game.phase == game.Phase.FINISHED)
 resume_button.visible = overlay
 menu_button.visible = overlay
 resume_button.caption = "CONTINUAR" if game.paused else "REVANCHA"
 if overlay and not was_overlay: resume_button.grab_focus()
 was_overlay = overlay
 queue_redraw()
func _draw() -> void:
 if not is_instance_valid(game) or game.phase == game.Phase.MENU: return
 var colors := [Rules.RED, Rules.BLUE]
 # Los paneles forman parte del fondo; nombres, puntos y reloj son reales.
 for side in 2:
  var center_x := 467 if side == 0 else 775
  var name: String = game.match_names[side]
  var name_scale := 2 if Ink.width(name, 2) < 113 else 1
  _neon_text(name, Vector2(center_x, 43), name_scale, colors[side])
  var value: String = str(game.score[side])
  _neon_text(value, Vector2(center_x, 69), 4 if value.length() < 5 else 3, Rules.WHITE)
 _neon_text("%02d:%02d" % [int(game.clock_time / 60.0), int(game.clock_time) % 60], Vector2(622, 45), 4, Rules.WHITE)
 # Azul: bandeja superior derecha. Rojo: bandeja junto al retrato inferior.
 # No se duplican poderes ni se muestran temporizadores inactivos.
 for side in 2:
  var column := 0
  var any_active := false
  for kind in range(6):
   var remaining: float = game.powers.active_time(side, kind)
   if remaining <= 0: continue
   any_active = true
   var pos := Vector2(394 + column * 104, 697) if side == 0 else Vector2(904 + column * 65, 56)
   var radius := 27 if side == 0 else 21
   Icon.draw_icon(self, kind, pos, radius)
   _neon_text("00:%02d" % ceili(remaining), pos + Vector2(0, radius + 11), 2, Rules.POWER_COLORS[kind])
   column += 1
  if any_active:
   var y := 762 if side == 0 else 111
   draw_line(Vector2(341 if side == 0 else 877, y), Vector2(976 if side == 0 else 1255, y), Color(colors[side], 0.8), 2)
 for side in 2:
  var actor: Node2D = game.player if side == 0 else game.computer
  if game.powers.magnet[side] > 0:
   draw_arc(actor.position, 145, 0, TAU, 64, Color(Rules.POWER_COLORS[5], 0.13), 1)
   for i in range(3):
    var radius := 46 + fmod(game.clock_time * 35 + i * 32, 96)
    draw_arc(actor.position, radius, game.clock_time + i, game.clock_time + i + PI * 0.8, 24, Color(Rules.POWER_COLORS[5], 0.35), 2)
  if game.powers.haste[side] > 0:
   for i in range(6):
    draw_rect(Rect2(actor.position + Vector2(-35 + i * 13, 35 + sin(game.clock_time * 10 + i) * 5), Vector2(3, 3)), Rules.POWER_COLORS[2])
  if game.powers.charged[side]:
   draw_arc(actor.position, 34, game.clock_time, game.clock_time + TAU, 36, Rules.POWER_COLORS[1], 2)
  var goal_x := Rules.ARENA.position.x + 4 if side == 0 else Rules.ARENA.end.x - 4
  if game.powers.shield[side] > 0:
   draw_line(Vector2(goal_x, Rules.GOAL_TOP), Vector2(goal_x, Rules.GOAL_BOTTOM), Color(0.4, 1, 0.2, 0.2), 16)
   draw_line(Vector2(goal_x, Rules.GOAL_TOP), Vector2(goal_x, Rules.GOAL_BOTTOM), Rules.POWER_COLORS[0], 3)
  if game.token_flash[side] > 0:
   draw_line(Vector2(goal_x, Rules.GOAL_TOP), Vector2(goal_x, Rules.GOAL_BOTTOM), Color(colors[side], 0.6), 9)
  if game.combos.celebration[side] > 0:
   Ink.text(self, "X%d" % game.combos.counts[side], actor.position + Vector2(0, -49), 2, colors[side], true)
 for pickup in game.powers.pickups:
  Icon.draw_icon(self, pickup.kind, pickup.pos, 24 + sin(game.clock_time * 3) * 1.5)
 var trail_color := Color("ffd454")
 if game.powers.fire_time > 0: trail_color = Color("ff672f")
 elif game.powers.super_time > 0: trail_color = Rules.POWER_COLORS[1]
 if game.trail_enabled:
  for i in game.trail.size():
   var alpha := float(i + 1) / float(game.trail.size()) * 0.3
   draw_circle(game.trail[i], 2 + i * 0.48, Color(trail_color, alpha))
   if game.powers.fire_time > 0 and i % 2 == 0:
    var flame: Vector2 = game.trail[i] + Vector2(sin(i + game.clock_time * 12) * 6, cos(i + game.clock_time * 9) * 9)
    draw_rect(Rect2(flame, Vector2(3, 5)), Color(Color("ffce4b"), alpha * 2))
 if game.powers.fire_time > 0 or game.powers.super_time > 0:
  draw_arc(game.puck.position, 16, 0, TAU, 24, trail_color, 3)
 for spark in game.sparks:
  draw_rect(Rect2(spark.pos, Vector2(3, 3)), Color(spark.tint, clampf(spark.life * 3, 0, 1)))
 if game.goal_flash > 0:
  draw_rect(Rules.ARENA, Color(colors[game.last_scorer], game.goal_flash * 0.35))
 if game.mid_flash > 0:
  draw_rect(Rules.ARENA, Color(0.7, 0.5, 1, game.mid_flash * 0.4))
 for item in game.floating_scores:
  if item.value == 50:
   Ink.text(self, game.match_names[item.side], item.pos - Vector2(0, 23), 2, Color(colors[item.side], minf(1, item.life * 3)), true)
  Ink.text(self, "+%d" % item.value, item.pos, 5 if item.value == 50 else 2, Color(colors[item.side], minf(1, item.life * 3)), true)
 if game.mid.banner > 0:
  var rect := Rect2(440, 137, 400, 78)
  var tint := Color("f14dff")
  for expansion in [12, 8, 4]:
   draw_rect(rect.grow(expansion), Color(tint, 0.035), false, 3)
  ArcadePanel.render(self, rect, tint)
  _neon_text("MID GAME MODE", Vector2(640, 150), 3, tint.lightened(0.3))
  _neon_text("02:50", Vector2(640, 184), 2, Rules.WHITE)
  for side in [-1, 1]:
   for i in range(7):
    var p := Vector2(640 + side * (210 + i * 5), 178 + sin(game.clock_time * 20 + i) * 25)
    draw_line(p, p + Vector2(side * 10, -8), Color(tint.lightened(0.5), game.mid.banner), 2)
 if game.paused or game.phase == game.Phase.FINISHED:
  draw_rect(Rules.ARENA, Color(0, 0.015, 0.045, 0.8))
  ArcadePanel.render(self, Rect2(378, 282, 524, 312), Rules.BLUE if game.paused else colors[game.last_scorer])
  var title: String = "PAUSA" if game.paused else (game.match_names[game.last_scorer] + " GANA!")
  Ink.text(self, title, Vector2(640, 309), 3, Rules.WHITE, true)
  Ink.text(self, "%d  -  %d" % [game.score[0], game.score[1]], Vector2(640, 357), 4, Color("ffda73"), true)
  Ink.text(self, "GOLES PRINCIPALES  %d - %d" % [game.main_goals[0], game.main_goals[1]], Vector2(640, 409), 1, Rules.BLUE, true)
 elif game.phase == game.Phase.SERVE:
  Ink.text(self, str(maxi(1, ceili(game.timer))), Rules.CENTER - Vector2(0, 22), 6, Rules.WHITE, true)

func _neon_text(message: String, pos: Vector2, size_px: int, tint: Color) -> void:
 for offset in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
  Ink.text(self, message, pos + offset, size_px, Color(tint, 0.09), true)
 Ink.text(self, message, pos, size_px, tint, true)
