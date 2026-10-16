extends Node2D

signal collected
var player: Node2D
var pickup_radius: float = 36.0
var taken: bool = false
var pulse: float = 0.0

func _physics_process(delta: float) -> void:
	pulse += delta
	if not taken and is_instance_valid(player) and global_position.distance_to(player.global_position) <= pickup_radius:
		taken = true
		collected.emit()
		queue_free()
	queue_redraw()

func _draw() -> void:
	var glow: Color = Color(0.95, 0.62, 0.25, 0.1 + 0.04 * sin(pulse * 4))
	draw_circle(Vector2.ZERO, 30, glow)
	draw_arc(Vector2.ZERO, 22 + sin(pulse * 4) * 2, 0, TAU, 32, Color("e7b25c"), 2)
	draw_rect(Rect2(-10, -13, 20, 26), Color("d6ac6b"))
	draw_rect(Rect2(-7, -10, 14, 20), Color("683b40"))
	draw_line(Vector2(-5, -2), Vector2(5, -2), Color("ffe4a2"), 2)
	draw_line(Vector2(-5, 3), Vector2(5, 3), Color("ffe4a2"), 2)
	draw_string(ThemeDB.fallback_font, Vector2(-47, -37), "CINDER CODEX", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("f3dca8"))
