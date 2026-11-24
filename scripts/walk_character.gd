@tool
extends Node2D
## Sprites independientes: la fase de los pasos depende de la distancia recorrida.
@export var character_row := 0
@export var route_left := 140.0
@export var route_right := 335.0
@export var floor_y := 558.0
@export var time_offset := 0.0
var sprite: AnimatedSprite2D
var frame_sizes: Array[Vector2] = []
var frame_count := 4
var walking := true
var direction := 1
const WALK_SPEED := 38.0
const PIXELS_PER_FRAME := 7.5
const TURN_PAUSE := 0.35

func _ready() -> void:
 if not ResourceLoader.exists("res://assets/walk_sheet.png"):
  return
 var sheet: Texture2D = load("res://assets/walk_sheet.png")
 var pixels := sheet.get_image()
 var frames := SpriteFrames.new()
 frames.set_animation_loop("default", true)
 frames.set_animation_speed("default", WALK_SPEED / PIXELS_PER_FRAME)
 var max_height := 1.0
 for column in frame_count:
  var x0 := int(sheet.get_width() * column / 4.0)
  var x1 := int(sheet.get_width() * (column + 1) / 4.0)
  var y0 := int(sheet.get_height() * character_row / 2.0)
  var y1 := int(sheet.get_height() * (character_row + 1) / 2.0)
  var cell := Rect2i(x0, y0, x1 - x0, y1 - y0)
  var bounds := _content_bounds(pixels.get_region(cell))
  var atlas := AtlasTexture.new()
  atlas.atlas = sheet
  atlas.region = Rect2(bounds.position + cell.position, bounds.size)
  frames.add_frame("default", atlas)
  frame_sizes.append(Vector2(bounds.size))
  max_height = maxf(max_height, bounds.size.y)
 sprite = AnimatedSprite2D.new()
 sprite.name = "WalkSprite"
 sprite.sprite_frames = frames
 sprite.centered = false
 sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
 sprite.scale = Vector2.ONE * (156.0 / max_height)
 add_child(sprite)
 set_time(0.0)

func _content_bounds(image: Image) -> Rect2i:
 # Ignora residuos casi transparentes del atlas para que los pies no salten
 # entre fotogramas y el tamaño no dependa de píxeles invisibles.
 var min_x := image.get_width()
 var min_y := image.get_height()
 var max_x := 0
 var max_y := 0
 for y in image.get_height():
  for x in image.get_width():
   if image.get_pixel(x, y).a > 0.4:
    min_x = mini(min_x, x)
    min_y = mini(min_y, y)
    max_x = maxi(max_x, x)
    max_y = maxi(max_y, y)
 return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)

func set_time(seconds: float) -> void:
 if not is_instance_valid(sprite):
  return
 var distance := route_right - route_left
 var leg_duration := distance / WALK_SPEED
 var half_cycle := leg_duration + TURN_PAUSE
 var phase := fposmod(seconds + time_offset, half_cycle * 2.0)
 direction = 1 if phase < half_cycle else -1
 var leg_time := fmod(phase, half_cycle)
 walking = leg_time < leg_duration
 var traveled := minf(leg_time * WALK_SPEED, distance)
 position = Vector2(roundf(route_left + traveled if direction == 1 else route_right - traveled), floor_y)
 sprite.frame = int(traveled / PIXELS_PER_FRAME) % frame_count if walking else 0
 sprite.flip_h = direction < 0
 var dimensions := frame_sizes[sprite.frame]
 sprite.offset = Vector2(-dimensions.x / 2.0, -dimensions.y)
 queue_redraw()

func _draw() -> void:
 draw_set_transform(Vector2(0, 1), 0, Vector2(1, 0.22))
 draw_circle(Vector2.ZERO, 24, Color(0.01, 0.03, 0.12, 0.32))
 draw_set_transform(Vector2.ZERO)
