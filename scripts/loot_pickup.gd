extends Node2D

const CATALOG = preload("res://scripts/item_catalog.gd")
var item_id: String = "cinder_codex"
var player: Node2D
var collect: Callable
var pickup_radius: float = 36.0
var taken: bool = false
var pulse: float = 0.0
var blocked: bool = false

func _physics_process(delta: float) -> void:
	pulse += delta
	if not taken and is_instance_valid(player) and global_position.distance_to(player.global_position) <= pickup_radius:
		if collect.is_valid() and collect.call(item_id):
			taken = true
			queue_free()
		else:
			blocked = true
	queue_redraw()

func _draw() -> void:
	var color: Color = CATALOG.color(item_id)
	var glow: Color = Color(color, 0.1 + 0.04 * sin(pulse * 4))
	draw_circle(Vector2.ZERO, 30, glow)
	draw_arc(Vector2.ZERO, 22 + sin(pulse * 4) * 2, 0, TAU, 32, color, 2)
	draw_texture_rect(CATALOG.icon(item_id), Rect2(-18, -18, 36, 36), false)
	if is_instance_valid(player) and global_position.distance_to(player.global_position) <= 160:
		var left: float = clampf(global_position.x - 175, 75, 855) - global_position.x
		var top: float = 43 if global_position.y < 210 else -38
		draw_string(ThemeDB.fallback_font, Vector2(left, top), CATALOG.ITEMS[item_id].name, HORIZONTAL_ALIGNMENT_CENTER, 350, 15, color)
		if blocked:
			draw_string(ThemeDB.fallback_font, Vector2(left, top + 19), "BAG FULL — make room with I", HORIZONTAL_ALIGNMENT_CENTER, 350, 13, Color("b9c5d3"))
