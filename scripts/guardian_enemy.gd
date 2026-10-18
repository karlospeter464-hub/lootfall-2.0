extends "res://scripts/enemy.gd"

@export_range(0, 50, 1) var armor: float = 8.0
@export_range(0.05, 1, 0.05) var minimum_ratio: float = 0.2

func take_damage(amount: float, direction: Vector2 = Vector2.ZERO) -> void:
	super.take_damage(maxf(amount - armor, amount * minimum_ratio) if amount > 0 else 0.0, direction)

func _draw() -> void:
	super._draw()
	var color := Color("8ebcac") if flash <= 0 else Color("fff1cc")
	draw_colored_polygon(PackedVector2Array([Vector2(-23, -20), Vector2(23, -20), Vector2(26, 16), Vector2(0, 27), Vector2(-26, 16)]), color.darkened(0.35))
	draw_rect(Rect2(-18, -16, 36, 31), color)
	draw_line(Vector2(-10, -1), Vector2(0, -12), Color("203b40"), 4)
	draw_line(Vector2(0, -12), Vector2(10, -1), Color("203b40"), 4)
	draw_line(Vector2(0, -12), Vector2(0, 11), Color("203b40"), 4)
	draw_string(ThemeDB.fallback_font, Vector2(-24, -35), "RUNE", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, color)
