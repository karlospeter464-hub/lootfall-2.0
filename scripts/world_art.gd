extends RefCounted

const WORLD = preload("res://scripts/world_regions.gd")
const BOUNDS := Rect2(64, 128, 1152, 592)
# Separate basins with dry margins; water and banks share one shoreline.
const MARSH_POOLS := [Rect2(130, 194, 310, 170), Rect2(645, 178, 440, 154), Rect2(505, 395, 260, 200), Rect2(135, 515, 235, 125), Rect2(910, 464, 235, 170)]

static func pool_outline(index: int, scale: float = 1.0) -> PackedVector2Array:
	var basin: Rect2 = MARSH_POOLS[index]
	var points := PackedVector2Array()
	for vertex in 29:
		var angle: float = vertex * TAU / 29
		var radius: float = 0.76 + sin(angle * 2 + index) * 0.12 + sin(angle * 3 - index) * 0.07 + noise(index * 37 + vertex * 13) * 0.04
		points.append(basin.get_center() + Vector2(cos(angle), sin(angle)) * basin.size * 0.5 * radius * scale)
	return points

static func noise(seed: int) -> float:
	return float(posmod(seed * 73 + seed * seed * 19 + 37, 997)) / 997.0

static func patch(canvas: CanvasItem, at: Vector2, span: Vector2, tint: Color, seed: int) -> void:
	var points := PackedVector2Array()
	for vertex in 11:
		var angle: float = vertex * TAU / 11
		var radius: float = 0.78 + noise(seed + vertex * 13) * 0.22
		points.append((at + Vector2(cos(angle), sin(angle)) * span * radius).clamp(BOUNDS.position, BOUNDS.end))
	canvas.draw_colored_polygon(points, tint)

static func floor_scene(canvas: CanvasItem, region: int, healing: float) -> void:
	var data: Dictionary = WORLD.REGIONS[region]
	var soil: Color = Color(data.blight).lerp(Color(data.healthy), healing)
	var stone := Color("41424a").lerp(Color("46534b"), healing)
	canvas.draw_rect(Rect2(0, 0, 1280, 800), Color("0d141d"))
	canvas.draw_rect(BOUNDS.grow(10), Color("171d28"))
	canvas.draw_rect(BOUNDS.grow(6), Color(data.accent).darkened(0.65), false, 1)
	canvas.draw_rect(BOUNDS, soil.darkened(0.07))
	# Shared faceted shapes, irregular placement and quiet values keep warnings readable.
	for index in 24:
		var at := Vector2(130 + noise(index * 11 + 2) * 1000, 175 + noise(index * 17 + 8) * 490)
		var threshold: float = 0.08 + noise(index * 23) * 0.84
		var clean: float = smoothstep(threshold - 0.08, threshold + 0.08, healing)
		var earth: Color = soil.lightened(0.015 + noise(index) * 0.025)
		patch(canvas, at, Vector2(90 + noise(index * 3) * 75, 35 + noise(index * 7) * 30), earth, index)
		patch(canvas, at + Vector2(5, 4), Vector2(63, 23), Color("26322f").lerp(Color("3b5441"), clean).lerp(soil, 0.4), index + 71)
		if clean < 1:
			var crack := PackedVector2Array([at - Vector2(24, 9), at - Vector2(8, 3), at + Vector2(1, 9), at + Vector2(24, 13)])
			canvas.draw_polyline(crack, Color(Color("171f28"), (1 - clean) * 0.6), 1.5, true)
		if clean > 0:
			for blade in 5:
				var root: Vector2 = at + Vector2(noise(index + blade * 7) * 60 - 30, noise(index + blade * 19) * 20)
				var green := Color("678568") if region != 2 else Color("668e80")
				canvas.draw_line(root, root + Vector2(-4, -8 - noise(blade + index) * 8) * clean, Color(green, clean * 0.65), 1.5, true)
				canvas.draw_line(root, root + Vector2(4, -6) * clean, Color(green, clean * 0.45), 1.5, true)
			if healing >= 0.75 and index % 4 == 0:
				canvas.draw_circle(at + Vector2(9, -7), 1.8, Color("c4c6a0"))
	if region == 0:
		for index in 150:
			var root := Vector2(85 + noise(index * 29) * 1100, 148 + noise(index * 43) * 550)
			var growth: float = smoothstep(noise(index * 17) * 0.9, 1.0, healing)
			canvas.draw_line(root, root + Vector2(3, -5) * growth, Color(Color("6a8160"), 0.35 * growth), 1, true)
	if region == 2:
		for index in MARSH_POOLS.size():
			var water := Color("30383d").lerp(Color("385b61"), healing)
			canvas.draw_colored_polygon(pool_outline(index, 1.09), soil.darkened(0.19))
			canvas.draw_colored_polygon(pool_outline(index), water)
			var shore: PackedVector2Array = pool_outline(index, 1.08)
			for reed in range(0, shore.size(), 2):
				if noise(index * 47 + reed * 5) < 0.35:
					continue
				var base: Vector2 = shore[reed]
				var green := Color("505d50").lerp(Color("7c9272"), healing)
				canvas.draw_line(base + Vector2(-3, 2), base + Vector2(-6, -9), green, 1.5, true)
				canvas.draw_line(base, base + Vector2(2, -12), green.lightened(0.04), 1.5, true)
				canvas.draw_line(base + Vector2(3, 1), base + Vector2(7, -7), green, 1.2, true)
	else:
		# Sunken paving is cosmetic; it never changes movement or enemy spawning.
		for index in 13:
			var at := Vector2(125 + index * 79, 430 + sin(index * 0.65) * 50 + noise(index * 41) * 18)
			patch(canvas, at + Vector2(0, 3), Vector2(32, 12), soil.darkened(0.18), index + 300)
			patch(canvas, at, Vector2(30, 10), stone.darkened(0.2 if region == 1 else 0.1), index + 300)
	for index in (16 if region == 1 else 8):
		var at := Vector2(105 + noise(index * 19 + 10) * 1060, (215 if region == 1 else 155) + noise(index * 3) * 20 if index % 2 == 0 else 668 + noise(index * 5) * 22)
		patch(canvas, at + Vector2(0, 9), Vector2(40, 11), soil.darkened(0.23), index + 110)
		if region == 1:
			var tip: Vector2 = at + Vector2(noise(index) * 10 - 5, -35 - noise(index + 4) * 18)
			canvas.draw_line(at + Vector2(0, 12), tip, Color("1b242c"), 8, true)
			canvas.draw_line(tip + Vector2(1, 20), tip + Vector2(-21, -6), Color("1b242c"), 4, true)
			canvas.draw_line(tip + Vector2(0, 17), tip + Vector2(23, -3), Color("1b242c"), 4, true)
			var growth: float = smoothstep(0.25, 0.8, healing)
			if growth > 0:
				patch(canvas, tip + Vector2(-15, 0), Vector2(37, 29) * growth, Color("304b3c"), index + 240)
				patch(canvas, tip + Vector2(12, -9), Vector2(33, 32) * growth, Color("3e5e47"), index + 215)
				patch(canvas, tip + Vector2(0, 8), Vector2(25, 23) * growth, Color("42634a"), index + 270)
		else:
			patch(canvas, at, Vector2(18 + noise(index) * 12, 10), Color("333842"), index + 200)
			patch(canvas, at - Vector2(2, 3), Vector2(13, 6), stone, index + 200)
			if healing > 0.5:
				patch(canvas, at + Vector2(12, 2), Vector2(14, 5), Color("42604b"), index + 260)
	canvas.draw_rect(BOUNDS.grow(-3), Color(0.02, 0.03, 0.05, 0.28), false, 6)
