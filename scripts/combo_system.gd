extends Node
signal high_combo(side: int, value: int)
const TIMEOUT := 4.5
var counts := [0, 0]
var remaining := [0.0, 0.0]
var hit_guard := [0.0, 0.0]
var celebration := [0.0, 0.0]
func reset() -> void:
 counts = [0, 0]
 remaining = [0.0, 0.0]
 hit_guard = [0.0, 0.0]
 celebration = [0.0, 0.0]
func tick(delta: float) -> void:
 for side in 2:
  remaining[side] = maxf(0, remaining[side] - delta)
  hit_guard[side] = maxf(0, hit_guard[side] - delta)
  celebration[side] = maxf(0, celebration[side] - delta)
  if remaining[side] <= 0: counts[side] = 0
func register_hit(side: int, amount: int = 1) -> void:
 if hit_guard[side] > 0: return
 counts[1 - side] = 0
 remaining[1 - side] = 0.0
 celebration[1 - side] = 0.0
 counts[side] = mini(4, counts[side] + amount)
 remaining[side] = TIMEOUT
 hit_guard[side] = 0.17
 if counts[side] >= 3:
  celebration[side] = 0.8
  high_combo.emit(side, counts[side])
