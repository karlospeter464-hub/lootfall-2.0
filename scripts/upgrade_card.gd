extends Button

const TINTS := [Color("e8a16d"), Color("91cfcd"), Color("d4bf83"), Color("e88f79"), Color("9bb6df"), Color("c2a0e1")]
const CATEGORIES := ["POWER", "TEMPO", "COVERAGE", "ON KILL", "PIERCE", "HIT CYCLE"]
var game
var kind: int = 0
var description: String
var age: float = 0
var hover_amount: float = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	custom_minimum_size = Vector2(275, 318)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("192332") if state == "normal" else Color("253447")
		style.border_color = TINTS[kind].darkened(0.4) if state == "normal" else TINTS[kind]
		style.set_border_width_all(2 if state != "focus" else 3)
		style.set_corner_radius_all(12)
		add_theme_stylebox_override(state, style)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		add_theme_color_override(state, Color.TRANSPARENT)
	var column := VBoxContainer.new()
	column.position = Vector2(15, 112)
	column.size = Vector2(245, 191)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 10)
	add_child(column)
	for row in [game.UPGRADE_TITLES[kind], description, context()]:
		var label := Label.new()
		label.text = row
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.add_theme_font_size_override("font_size", 22 if row == game.UPGRADE_TITLES[kind] else (14 if row == context() else 17))
		label.add_theme_color_override("font_color", TINTS[kind] if row == context() else Color("f2e7d4"))
		column.add_child(label)
	tooltip_text = game.card_description(kind)

func context() -> String:
	return ["Stronger direct hits & damage effects", "More Echo casts" if game.equipment.scepter == "echo_scepter" else "More casts. Smaller openings.", "More lanes for Piercing Flame" if game.mechanic_cards.has(4) else "Spread your fire across the field", "Pairs with damage & crowded waves", "Reach the enemy behind your target", "Four direct hits empower your main shot"][kind]

func _process(delta: float) -> void:
	age += delta
	hover_amount = move_toward(hover_amount, 1 if is_hovered() or has_focus() else 0, delta * 8)
	pivot_offset = size / 2
	scale = Vector2.ONE * (lerpf(0.94, 1, minf(age * 6, 1)) + hover_amount * 0.018)
	modulate.a = minf(1, age * 7)
	queue_redraw()

func _draw() -> void:
	var at := Vector2(size.x / 2, 61)
	var tint: Color = TINTS[kind]
	draw_colored_polygon(PackedVector2Array([at + Vector2(0,-39), at + Vector2(39,0), at + Vector2(0,39), at + Vector2(-39,0)]), Color(tint, 0.08 + hover_amount * 0.06))
	draw_arc(at, 32, 0, TAU, 32, Color(tint, 0.4), 1.5, true)
	match kind:
		0:
			draw_colored_polygon(PackedVector2Array([at + Vector2(0,-24), at + Vector2(16,5), at + Vector2(7,19), at + Vector2(-10,18), at + Vector2(-18,3)]), tint)
			draw_line(at + Vector2(0,13), at + Vector2(0,-4), Color("fff0c7"), 4, true)
		1:
			for index in 3:
				draw_polyline(PackedVector2Array([at + Vector2(-14 + index*12,-20), at + Vector2(-22 + index*12,0), at + Vector2(-9 + index*12,0), at + Vector2(-17 + index*12,20)]), tint, 3, true)
		2:
			for index in 3:
				var direction := Vector2.from_angle(-PI / 2 + (index - 1) * 0.65)
				draw_line(at + Vector2(0,21), at + direction * 24, tint, 4, true)
				draw_circle(at + direction * 24, 4, tint)
		3:
			for index in 8:
				var direction := Vector2.from_angle(index * TAU / 8)
				draw_line(at + direction * 10, at + direction * 25, tint, 3, true)
			draw_circle(at, 7, tint)
		4:
			for y in [-12, 12]: draw_arc(at + Vector2(0,y), 10, 0, TAU, 16, tint, 2, true)
			draw_line(at + Vector2(0,27), at - Vector2(0,26), tint, 3, true)
		5:
			for index in 4:
				var angle: float = index * TAU / 4
				draw_circle(at + Vector2.from_angle(angle) * 23, 4, tint)
			draw_polyline(PackedVector2Array([at + Vector2(5,-15), at + Vector2(-7,2), at + Vector2(6,2), at + Vector2(-4,16)]), tint, 4, true)
	draw_string(ThemeDB.fallback_font, Vector2(18, 20), CATEGORIES[kind], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(tint, 0.8))
	draw_line(Vector2(35, 105), Vector2(size.x - 35, 105), Color(tint, 0.28), 1, true)
