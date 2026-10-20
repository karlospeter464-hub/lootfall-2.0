extends RefCounted

const WORLD = preload("res://scripts/world_regions.gd")

static func floor_scene(canvas: CanvasItem, region: int, healing: float) -> void:
	var data: Dictionary = WORLD.REGIONS[region]
	var bounds := Rect2(64, 128, 1152, 592)
	var soil: Color = Color(data.blight).lerp(Color(data.healthy), healing)
	canvas.draw_rect(Rect2(0, 0, 1280, 800), Color("101621"))
	canvas.draw_rect(bounds.grow(10), Color("151c29"))
	canvas.draw_rect(bounds.grow(6), Color(data.accent).darkened(0.5), false, 1)
	canvas.draw_rect(bounds, soil)
	# Coordinate hashes keep decoration deterministic and independent of loot RNG.
	for row in 8:
		for column in 15:
			var index: int = row * 15 + column
			var point := Vector2(100 + column * 76 + ((index * 19) % 31) - 15, 157 + row * 73 + ((index * 29) % 25) - 12)
			var noise: float = float((index * 37 + 17) % 101) / 100
			var clean: bool = noise < healing
			if region == 2 and index % 3 == 0:
				var pool := PackedVector2Array()
				for vertex in 18:
					pool.append(point + Vector2(cos(vertex * TAU / 18) * (26 + noise * 17), sin(vertex * TAU / 18) * (9 + noise * 7)))
				canvas.draw_colored_polygon(pool, Color(data.water).lerp(Color("527a76"), healing).darkened(0.35 if not clean else 0.05))
				canvas.draw_line(point + Vector2(-10, -2), point + Vector2(8, -2), Color(0.55, 0.77, 0.75, 0.12 + healing * 0.12), 1)
			elif region == 0 and index % 3 == 0:
				canvas.draw_colored_polygon(PackedVector2Array([point, point + Vector2(33, -10), point + Vector2(37, 15), point + Vector2(12, 25)]), soil.lightened(0.018 + noise * 0.02))
			if clean:
				var green := Color("709477") if region != 2 else Color("71a797")
				for blade in 3:
					var root: Vector2 = point + Vector2(blade * 6, 8)
					canvas.draw_line(root, root + Vector2(blade * 3 - 3, -5 - noise * 9), Color(green, 0.5), 2)
				if healing >= 0.75 and index % 7 == 0:
					canvas.draw_circle(point + Vector2(6, -4), 2, Color("d8c9a4"))
			elif index % 3 == 0:
				canvas.draw_polyline(PackedVector2Array([point, point + Vector2(11, 4), point + Vector2(14, 16), point + Vector2(24, 19)]), Color("1d202b"), 2)
	# Grove trunks and field/marsh stones stay decorative, with no collision.
	for index in 10:
		var point := Vector2(100 + index * 118, 162 if index % 2 == 0 else 678)
		if region == 1:
			canvas.draw_line(point + Vector2(0, 20), point - Vector2(4, 21), Color("181e2a"), 9)
			canvas.draw_line(point - Vector2(4, 6), point - Vector2(20, 22), Color("181e2a"), 5)
			canvas.draw_line(point - Vector2(3, 10), point + Vector2(15, -29), Color("181e2a"), 4)
			if healing >= 0.5:
				canvas.draw_circle(point + Vector2(-14, -23), 13, Color("385345"))
				canvas.draw_circle(point + Vector2(10, -30), 15, Color("42634e"))
		else:
			canvas.draw_colored_polygon(PackedVector2Array([point + Vector2(-13, 9), point + Vector2(-7, -8), point + Vector2(9, -10), point + Vector2(15, 8)]), soil.darkened(0.25))
	canvas.draw_rect(bounds.grow(-3), Color(0.02, 0.03, 0.05, 0.35), false, 6)
	canvas.draw_arc(bounds.get_center(), 93, 0, TAU, 80, Color(Color(data.accent), 0.09), 1)
