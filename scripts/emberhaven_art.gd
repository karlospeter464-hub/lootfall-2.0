extends Control

var clock: float = 0
var restoration: float = 0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _draw() -> void:
	draw_rect(Rect2(0,0,1280,800), Color("101b29"))
	var green := Color("172b30").lerp(Color("254638"), restoration)
	for layer in 3:
		var points := PackedVector2Array([Vector2(0,800), Vector2(0,610 + layer * 30)])
		for index in 14:
			points.append(Vector2(index * 100, 600 + layer * 35 - sin(index * 0.8 + layer) * 28))
		points.append(Vector2(1280,800))
		draw_colored_polygon(points, green.darkened(layer * 0.14))
	# Emberhaven's lanterns and planted terraces emerge beneath the expedition menu.
	for index in 9:
		var at := Vector2(70 + index * 146, 690 + sin(index * 1.7) * 34)
		draw_rect(Rect2(at, Vector2(76,66)), Color("1a292f"))
		draw_colored_polygon(PackedVector2Array([at + Vector2(-8,0),at + Vector2(38,-35),at + Vector2(84,0)]), Color("263633"))
		for window in 2:
			var light: Vector2 = at + Vector2(16 + window * 33, 22)
			draw_rect(Rect2(light,Vector2(12,18)), Color(0.85,0.62,0.3,0.5 + sin(clock * 1.3 + index) * 0.06))
		for sprout in 4:
			var root := at + Vector2(sprout * 20, 70)
			var height: float = 6 + restoration * 22
			draw_line(root,root + Vector2(sin(clock + sprout) * 2,-height),Color("527653"),2,true)
	for index in 12:
		var at := Vector2(85 + index * 103, 775 + sin(clock * 0.4 + index) * 8)
		draw_circle(at,1.5,Color(0.7,0.85,0.56,0.25 + restoration * 0.3))
