@tool
extends Control
## Menú separado del partido. Los botones son nodos Button accesibles por teclado.
const Ink = preload("res://scripts/pixel_ink.gd")
const ArcadeButton = preload("res://scripts/menu_button.gd")
const WalkCharacter = preload("res://scripts/walk_character.gd")
const ArcadeScreens = preload("res://scripts/arcade_screens.gd")
const PowerIcon = preload("res://effects/power_icon.gd")
const Rules = preload("res://scripts/rules.gd")
var volume_sliders: Array[HSlider] = []
var name_fields: Array[LineEdit] = []
const BLUE := Color("50ddff")
const WHITE := Color("e4faff")
const DIFFICULTIES := ["FACIL", "NORMAL", "DIFICIL"]
var backdrop: Texture2D
var page := "home"
var selected := 0
var buttons: Array[Button] = []
var home_buttons: Array[Button] = []
var page_buttons: Array[Button] = []
var home_root: Control
var page_root: Control
var game: Node
var elapsed := 0.0
var animated_background: TextureRect
var walkers: Array[Node2D] = []

func _ready() -> void:
 size = Vector2(1280, 800)
 mouse_filter = Control.MOUSE_FILTER_STOP
 if ResourceLoader.exists("res://assets/arcade_clean.png"):
  backdrop = load("res://assets/arcade_clean.png")
 if backdrop:
  animated_background = TextureRect.new()
  animated_background.name = "AnimatedArcade"
  animated_background.texture = backdrop
  animated_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
  animated_background.stretch_mode = TextureRect.STRETCH_SCALE
  animated_background.size = Vector2(1280, 800)
  animated_background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
  animated_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
  animated_background.show_behind_parent = true
  add_child(animated_background)
 for index in range(2):
  var walker := Node2D.new()
  walker.set_script(WalkCharacter)
  walker.name = "WalkerLeft" if index == 0 else "WalkerRight"
  walker.character_row = index
  walker.route_left = 140.0 if index == 0 else 945.0
  walker.route_right = 335.0 if index == 0 else 1140.0
  walker.time_offset = 1.6 if index == 0 else 7.5
  walker.show_behind_parent = true
  add_child(walker)
  walkers.append(walker)
 if not Engine.is_editor_hint():
  game = get_parent()
 home_root = Control.new()
 home_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(home_root)
 page_root = Control.new()
 page_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(page_root)
 var names := ["JUGAR", "MODO DE JUEGO", "DIFICULTAD", "OPCIONES", "CONTROLES", "PODERES", "LOGROS", "SALIR"]
 var icons := ["play", "pad", "bars", "gear", "pad", "bars", "cup", "exit"]
 for i in names.size():
  var button := _button(home_root, names[i], icons[i], Rect2(420, 220 + i * 62, 440, 55))
  button.primary = i == 0
  button.pressed.connect(_home_action.bind(i))
  home_buttons.append(button)
 page_root.hide()
 buttons = home_buttons
 refresh()
 if not Engine.is_editor_hint():
  focus_first.call_deferred()

func _button(parent: Control, caption: String, icon: String, rect: Rect2) -> Button:
 var button := Button.new()
 button.set_script(ArcadeButton)
 button.caption = caption
 button.symbol = icon
 button.position = rect.position
 button.size = rect.size
 parent.add_child(button)
 button.focus_entered.connect(_focused.bind(button))
 return button

func _focused(button: Button) -> void:
 var index := buttons.find(button)
 if index >= 0:
  if is_instance_valid(game): game._sound("select")
  selected = index
  for item in buttons:
   item.highlighted = false
   item.queue_redraw()

func focus_first() -> void:
 if visible and not buttons.is_empty():
  buttons[0].grab_focus()
  selected = 0

func refresh() -> void:
 if home_buttons.is_empty():
  return
 var difficulty: int = game.difficulty if is_instance_valid(game) else 1
 home_buttons[2].detail = "<  %s  >" % DIFFICULTIES[difficulty]
 home_buttons[1].detail = "<  VS AIR BOT  >" if not is_instance_valid(game) or game.game_mode == 0 else "<  2 JUGADORES  >"
 if Engine.is_editor_hint():
  home_buttons[0].highlighted = true
 for button in buttons:
  button.queue_redraw()
 queue_redraw()

func open_home() -> void:
 show()
 show_page("home")

func _input(event: InputEvent) -> void:
 if Engine.is_editor_hint() or not visible or not event is InputEventKey or not event.pressed:
  return
 if page == "audio" and get_viewport().gui_get_focus_owner() is HSlider:
  if event.physical_keycode == KEY_ESCAPE:
   show_page("options")
   get_viewport().set_input_as_handled()
  return
 if page == "names" and get_viewport().gui_get_focus_owner() is LineEdit:
  if event.physical_keycode == KEY_ESCAPE:
   show_page("home")
   get_viewport().set_input_as_handled()
  return
 var key: int = event.physical_keycode
 if key == 0:
  key = event.keycode
 if key in [KEY_UP, KEY_W, KEY_DOWN, KEY_S]:
  var direction := -1 if key in [KEY_UP, KEY_W] else 1
  selected = posmod(selected + direction, buttons.size())
  buttons[selected].grab_focus()
 elif key in [KEY_ENTER, KEY_SPACE, KEY_Z]:
  if not event.echo:
   buttons[selected].click_direction = 1
   buttons[selected].pressed.emit()
 elif key in [KEY_ESCAPE, KEY_X]:
  if page != "home":
   show_page("home")
 elif key in [KEY_LEFT, KEY_A, KEY_RIGHT, KEY_D] and page == "home" and selected in [1, 2]:
  if selected == 2:
   _change_difficulty(-1 if key in [KEY_LEFT, KEY_A] else 1)
  else:
   _change_mode()
 else:
  return
 get_viewport().set_input_as_handled()

func _home_action(index: int) -> void:
 if not is_instance_valid(game):
  return
 game._sound("button")
 match index:
  0: show_page("names")
  1: _change_mode()
  2: _change_difficulty(home_buttons[2].click_direction)
  3: show_page("options")
  4: show_page("controls")
  5: show_page("powers")
  6: show_page("achievements")
  7: get_tree().quit()

func _change_mode() -> void:
 game.game_mode = 1 - game.game_mode
 game.save_profile()
 refresh()

func _change_difficulty(direction: int) -> void:
 if not is_instance_valid(game):
  return
 game.difficulty = posmod(game.difficulty + direction, 3)
 game.save_profile()
 refresh()

func show_page(next_page: String) -> void:
 page = next_page
 for child in page_root.get_children():
  page_root.remove_child(child)
  child.queue_free()
 page_buttons.clear()
 name_fields.clear()
 volume_sliders.clear()
 home_root.visible = page == "home"
 page_root.visible = page != "home"
 if page == "home":
  buttons = home_buttons
 else:
  if page == "options":
   var names := ["SONIDO", "PANTALLA", "RASTRO DEL DISCO", "CONTROL JUGADOR 1"]
   for i in names.size():
    var button := _button(page_root, names[i], "gear", Rect2(420, 300 + i * 69, 440, 62))
    button.pressed.connect(_option.bind(i))
    page_buttons.append(button)
   _refresh_options()
   var sound_button := _button(page_root, "VOLUMEN MUSICA / EFECTOS", "gear", Rect2(420, 577, 440, 40))
   sound_button.pressed.connect(show_page.bind("audio"))
   page_buttons.append(sound_button)
  if page == "audio": _build_audio()
  if page == "powers":
   var rules_button := _button(page_root, "MID GAME / PUNTOS", "bars", Rect2(420, 581, 440, 38))
   rules_button.pressed.connect(show_page.bind("mid_rules"))
   page_buttons.append(rules_button)
  if page == "names":
   _build_names()
  var back := _button(page_root, "VOLVER", "back", Rect2(470, 626, 340, 56))
  back.pressed.connect(show_page.bind("home"))
  page_buttons.append(back)
  buttons = page_buttons
 refresh()
 focus_first()
 if page == "names":
  name_fields[0].grab_focus()
 if page == "audio":
  volume_sliders[0].grab_focus()

func _option(index: int) -> void:
 if not is_instance_valid(game):
  return
 match index:
  0: game.muted = not game.muted
  1:
   game.fullscreen = not game.fullscreen
   game.apply_display_mode()
  2: game.trail_enabled = not game.trail_enabled
  3: game.mouse_control = not game.mouse_control
 game.save_profile()
 game._sound("hit")
 _refresh_options()

func _refresh_options() -> void:
 if not is_instance_valid(game) or page_buttons.size() < 4:
  return
 page_buttons[0].detail = "DESACTIVADO" if game.muted else "ACTIVADO"
 page_buttons[1].detail = "COMPLETA" if game.fullscreen else "VENTANA"
 page_buttons[2].detail = "ACTIVADO" if game.trail_enabled else "DESACTIVADO"
 page_buttons[3].detail = "RATON" if game.mouse_control else "TECLADO WASD"
 for button in page_buttons:
  button.queue_redraw()

func _process(delta: float) -> void:
 if visible:
  elapsed += delta
  for walker in walkers:
   walker.set_time(elapsed)
  queue_redraw()

func _draw() -> void:
 if not backdrop:
  draw_rect(Rect2(0, 0, 1280, 800), Color("101b53"))
 ArcadeScreens.render(self, elapsed)
 # Sombra suave por franjas detrás de la columna para separar los controles.
 for i in range(8):
  draw_rect(Rect2(396 - i * 5, 225, 488 + i * 10, 483), Color(0.01, 0.025, 0.09, 0.032))
 _logo()
 if page != "home":
  var rect := Rect2(342, 229, 596, 475)
  Ink.panel(self, rect.grow(5), Color("040b28"), Color("0b4e9a"), 3)
  Ink.panel(self, rect, Color("081638"), BLUE, 2)
  var heading: String = {"options": "OPCIONES", "controls": "CONTROLES", "achievements": "LOGROS", "powers": "PODERES", "names": "QUIEN VA A JUGAR?", "audio": "AUDIO", "mid_rules": "MID GAME / PUNTOS"}.get(page, "")
  Ink.text(self, heading, Vector2(640, 253), 3, WHITE, true)
  draw_line(Vector2(370, 287), Vector2(910, 287), Color("1c4672"), 2)
  if page == "audio":
   _audio_labels()
  elif page == "mid_rules":
   _mid_rules()
  elif page == "powers":
   _powers_guide()
  elif page == "names":
   _names_labels()
  elif page == "controls":
   _controls()
  elif page == "achievements":
   _achievements()

 _footer()
 # Pequeños destellos ambientales; no interfieren con la interacción.
 for i in range(10):
  var p := Vector2(100 + i * 117, 202 + fmod(elapsed * (7 + i % 3) + i * 63, 480))
  if p.x < 360 or p.x > 940:
   draw_rect(Rect2(p, Vector2(2, 2)), Color(0.3, 0.8, 1, 0.25 + sin(elapsed + i) * 0.15))

func _logo() -> void:
 var label := "AIR RUSH"
 var pos := Vector2(640, 57)
 for offset in [Vector2(-7, -7), Vector2(7, -7), Vector2(-7, 7), Vector2(7, 7)]:
  Ink.text(self, label, pos + offset + Vector2(0, 8), 13, Color("0585d9"), true)
 for offset in [Vector2(-4, -4), Vector2(4, -4), Vector2(-4, 4), Vector2(4, 4)]:
  Ink.text(self, label, pos + offset + Vector2(0, 5), 13, Color("030b2c"), true)
 var origin := pos - Vector2(Ink.width(label, 13) / 2, 0)
 var colors := [Color("fff5ba"), Color("ffe181"), Color("ffcb56"), Color("ffad39"), Color("ff7b3c"), Color("fa4b5b"), Color("dc345f")]
 for letter in label:
  var rows: PackedStringArray = Ink.GLYPHS.get(letter, "000/000/000/000/000/000/000").split("/")
  for y in rows.size():
   for x in rows[y].length():
    if rows[y][x] == "1":
     draw_rect(Rect2(origin + Vector2(x, y) * 13, Vector2(13, 13)), colors[y])
  origin.x += (rows[0].length() + 1) * 13
 for side in [-1, 1]:
  for row in range(3):
   var near_x: float = 640 + side * 302
   var far_x: float = 640 + side * (416 - row * 22)
   var y := 70 + row * 27
   var points := PackedVector2Array([Vector2(near_x, y), Vector2(far_x, y - 9), Vector2(far_x - side * 7, y + 9), Vector2(near_x, y + 15)])
   draw_colored_polygon(points, Color("96edff"))
   points.append(points[0])
   draw_polyline(points, Color("006bc4"), 4)
 Ink.panel(self, Rect2(335, 166, 610, 39), Color("041538"), Color("0877be"), 2)
 Ink.text(self, "<< AIR HOCKEY ARCADE >>", Vector2(640, 175), 3, BLUE, true)

func _controls() -> void:
 var lines := [
  ["JUGADOR 1: W/S + A/D", "RATON OPCIONAL EN AJUSTES"],
  ["JUGADOR 2: FLECHAS", "MODO LOCAL EN EL MISMO TECLADO"],
  ["P / ESC", "PAUSA O CONTINUA LA PARTIDA"],
  ["X EN PAUSA", "REGRESA AL MENU DE INICIO"],
  ["R / M", "REINICIA / ACTIVA O SILENCIA SONIDO"]
 ]
 for i in lines.size():
  Ink.text(self, lines[i][0], Vector2(640, 308 + i * 57), 2, WHITE, true)
  Ink.text(self, lines[i][1], Vector2(640, 332 + i * 57), 2, BLUE, true)
 Ink.text(self, "MARCA EN LA DERECHA. EL PRIMERO A 7 GANA.", Vector2(640, 601), 2, Color("ffd677"), true)

func _achievements() -> void:
 var stats: Dictionary = game.stats if is_instance_valid(game) else {}
 var achievements := [
  ["PRIMER GOL", "MARCA TU PRIMER GOL", int(stats.get("goals", 0)) >= 1],
  ["PRIMERA VICTORIA", "GANA UNA PARTIDA", int(stats.get("wins", 0)) >= 1],
  ["SIN CONCEDER", "GANA 7 A 0", int(stats.get("perfect_wins", 0)) >= 1],
  ["REY DEL ARCADE", "GANA EN DIFICIL", int(stats.get("hard_wins", 0)) >= 1]
 ]
 for i in achievements.size():
  var y := 305 + i * 73
  var unlocked: bool = achievements[i][2]
  var tint := Color("ffd674") if unlocked else Color("5b749e")
  Ink.panel(self, Rect2(373, y, 534, 62), Color("0d2048"), tint.darkened(0.45))
  Ink.text(self, "%02d" % (i + 1), Vector2(390, y + 20), 3, tint)
  Ink.text(self, achievements[i][0], Vector2(453, y + 10), 2, tint)
  Ink.text(self, achievements[i][1], Vector2(453, y + 33), 2, Color("9bb5d8"))
  Ink.text(self, "LOGRADO" if unlocked else "PENDIENTE", Vector2(894, y + 50) - Vector2(Ink.width("LOGRADO" if unlocked else "PENDIENTE", 1), 0), 1, tint)

func _build_names() -> void:
 for side in range(2 if game.game_mode == 1 else 1):
  var field := LineEdit.new()
  field.position = Vector2(414, 338 + side * 101)
  field.size = Vector2(452, 46)
  field.max_length = 12
  field.placeholder_text = "Escribe tu nombre"
  field.text = game.player_names[side]
  field.alignment = HORIZONTAL_ALIGNMENT_CENTER
  field.add_theme_font_size_override("font_size", 24)
  field.add_theme_color_override("font_color", WHITE)
  field.add_theme_color_override("caret_color", BLUE)
  for state in ["normal", "focus"]:
   var style := StyleBoxFlat.new()
   style.bg_color = Color("06102a")
   style.border_color = (Rules.RED if side == 0 else BLUE).lightened(0.3 if state == "focus" else 0)
   style.set_border_width_all(2)
   field.add_theme_stylebox_override(state, style)
  field.text_submitted.connect(_name_submitted.bind(side))
  page_root.add_child(field)
  name_fields.append(field)
 var begin := _button(page_root, "EMPEZAR PARTIDA", "play", Rect2(420, 549, 440, 56))
 begin.pressed.connect(_begin_named_match)
 page_buttons.append(begin)

func _name_submitted(_text: String, side: int) -> void:
 if side + 1 < name_fields.size():
  name_fields[side + 1].grab_focus()
 else:
  _begin_named_match()

func _begin_named_match() -> void:
 for side in name_fields.size():
  var value: String = game.clean_name(name_fields[side].text)
  if value.is_empty():
   name_fields[side].text = ""
   name_fields[side].placeholder_text = "Escribe al menos una letra o numero"
   name_fields[side].grab_focus()
   return
  game.player_names[side] = value
 game.save_profile()
 game._sound("button")
 game.start_match()

func _names_labels() -> void:
 Ink.text(self, "TU NOMBRE / PALETA ROJA", Vector2(640, 309), 2, Rules.RED, true)
 Ink.text(self, "NOMBRE / PALETA AZUL" if game.game_mode == 1 else "RIVAL: BOT", Vector2(640, 410), 2, BLUE, true)
 if game.game_mode == 0:
  Ink.text(self, "JUEGAS CONTRA LA COMPUTADORA", Vector2(640, 450), 2, WHITE, true)
 Ink.text(self, "HASTA 12 CARACTERES. ENTER PARA CONTINUAR.", Vector2(640, 512), 1, WHITE, true)

func _powers_guide() -> void:
 Ink.text(self, "RECOGE LOS ICONOS CON TU PALETA", Vector2(640, 301), 2, WHITE, true)
 var descriptions := [
  ["REFLEJA EL DISCO EN TU PORTERIA.", "6 SEGUNDOS DE PROTECCION."],
  ["POTENCIA EL SIGUIENTE GOLPE.", "USALO ANTES DE 12 SEGUNDOS."],
  ["PALETA UN 45% MAS RAPIDA.", "DURA 5 SEGUNDOS."],
  ["DISCO RAPIDO Y ESTELA DE FUEGO.", "DURA 4 SEGUNDOS."],
  ["3 MINI-PUCKS DURANTE 6 SEGUNDOS.", "SENUELOS: NO MARCAN GOLES."],
  ["ATRACCION SUAVE CERCA DE TI.", "DURA 6 SEGUNDOS."]]
 for kind in range(6):
  var x := 369 + (kind % 2) * 280
  var y := 342 + int(kind / 2.0) * 78
  PowerIcon.draw_icon(self, kind, Vector2(x + 18, y + 11), 17)
  Ink.text(self, Rules.POWER_NAMES[kind], Vector2(x + 45, y + 3), 2, Rules.POWER_COLORS[kind])
  Ink.text(self, descriptions[kind][0], Vector2(x, y + 34), 1, WHITE)
  Ink.text(self, descriptions[kind][1], Vector2(x, y + 48), 1, Color("9fc1dc"))

func _mid_rules() -> void:
 var lines := [
  ["02:50 - 03:20", "EL MODO FICHAS DURA 30 SEGUNDOS."],
  ["PUCK +50 / FICHA +2", "GANA QUIEN MARQUE 7 GOLES CON EL PUCK."],
  ["TOCA LAS FICHAS", "GANAS SU EFECTO Y LAS LANZAS AL RIVAL."],
  ["DEFIENDE TU PORTERIA", "LAS FICHAS SOLO SUMAN SI ENTRAN."],
  ["PREMIOS TEMPORALES", "VERDE TURBO / AZUL ESCUDO / MORADO CARGA"],
  ["ROJO FUEGO / NARANJA COMBO", "CIAN IMAN / AMARILLO DISPARO RAPIDO"]]
 for i in lines.size():
  Ink.text(self, lines[i][0], Vector2(640, 314 + i * 48), 2, Rules.POWER_COLORS[i], true)
  Ink.text(self, lines[i][1], Vector2(640, 338 + i * 48), 1, WHITE, true)

func _build_audio() -> void:
 for side in 2:
  var slider := HSlider.new()
  slider.position = Vector2(420, 355 + side * 120)
  slider.size = Vector2(440, 34)
  slider.min_value = 0
  slider.max_value = 100
  slider.step = 5
  slider.value = roundf((game.music_volume if side == 0 else game.effects_volume) * 100)
  var style := StyleBoxFlat.new()
  style.bg_color = Color("163855")
  style.set_border_width_all(2)
  style.border_color = BLUE
  style.content_margin_top = 5
  style.content_margin_bottom = 5
  slider.add_theme_stylebox_override("slider", style)
  page_root.add_child(slider)
  volume_sliders.append(slider)
  slider.value_changed.connect(_volume_changed.bind(side))

func _volume_changed(value: float, side: int) -> void:
 if side == 0: game.music_volume = value / 100.0
 else: game.effects_volume = value / 100.0
 game.audio.set_levels(game.music_volume, game.effects_volume, game.muted)
 game.save_profile()
 queue_redraw()

func _audio_labels() -> void:
 Ink.text(self, "MUSICA  %d%%" % roundi(game.music_volume * 100), Vector2(640, 318), 3, BLUE, true)
 Ink.text(self, "EFECTOS  %d%%" % roundi(game.effects_volume * 100), Vector2(640, 438), 3, WHITE, true)
 Ink.text(self, "VOLUMENES INDEPENDIENTES", Vector2(640, 569), 2, BLUE, true)

func _footer() -> void:
 if page == "names":
  Ink.text(self, "ESCRIBE TU NOMBRE  /  TAB CAMBIA CAMPO  /  ESC VOLVER", Vector2(640, 749), 1, WHITE, true)
  return
 Ink.panel(self, Rect2(385, 735, 510, 39), Color(0.02, 0.04, 0.17, 0.88), Color("164b89"))
 Ink.text(self, "Z / ENTER  SELECCIONAR", Vector2(405, 747), 2, WHITE)
 Ink.text(self, "X / ESC  VOLVER", Vector2(722, 747), 2, WHITE)
 Ink.text(self, "MOUSE O FLECHAS PARA NAVEGAR", Vector2(640, 786), 1, BLUE, true)
