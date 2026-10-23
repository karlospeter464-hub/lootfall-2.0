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
	if minf(span.x, span.y) < 1: return
	var points := PackedVector2Array()
	for vertex in 11:
		var angle: float = vertex * TAU / 11
		var radius: float = 0.78 + noise(seed + vertex * 13) * 0.22
		points.append((at + Vector2(cos(angle), sin(angle)) * span * radius).clamp(BOUNDS.position, BOUNDS.end))
	canvas.draw_colored_polygon(points, tint)

static func floor_scene(canvas: CanvasItem, region: int, healing: float, clock: float = 0.0) -> void:
	var data: Dictionary = WORLD.REGIONS[region]
	var soil: Color = Color(data.blight).lerp(Color(data.healthy), healing)
	var stone := Color("41424a").lerp(Color("46534b"), healing)
	canvas.draw_rect(Rect2(0, 0, 1280, 800), Color("0d141d"))
	canvas.draw_rect(BOUNDS.grow(10), Color("171d28"))
	canvas.draw_rect(BOUNDS.grow(6), Color(data.accent).darkened(0.65), false, 1)
	canvas.draw_rect(BOUNDS, soil.darkened(0.07))
	# Expanding rooted islands reclaim the ground; plants unfold with the same saved fraction.
	for index in 44:
		var at := Vector2(115 + noise(index * 11 + 2) * 1040, 175 + noise(index * 17 + 8) * 490)
		var clean: float = growth(index, healing)
		if clean < 1:
			var crack := PackedVector2Array([at - Vector2(25, 8), at - Vector2(8, 2), at + Vector2(1, 9), at + Vector2(24, 12)])
			canvas.draw_polyline(crack, Color(Color("171f28"), (1 - clean) * 0.55), 1.5, true)
		if clean <= 0: continue
		var spread: float = sqrt(clean)
		var span := Vector2(85 + noise(index * 3) * 75, 40 + noise(index * 7) * 35) * spread
		patch(canvas, at, span, soil.lerp(Color("3d6345") if region != 2 else Color("355b4f"), 0.7), index)
		patch(canvas, at + Vector2(3, -2), span * 0.72, Color("41674a") if region != 2 else Color("406f60"), index + 71)
		for sprout in 7:
			var root := at + Vector2(noise(index * 7 + sprout * 13) * 100 - 50, noise(index * 19 + sprout * 23) * 44 - 22) * spread
			var height: float = (10 + noise(index * 5 + sprout) * 22) * clean
			var wind: float = sin(clock * 1.25 + index * 0.8 + sprout) * 2.5 * clean
			plant(canvas, root, height, wind, sprout % 3 == 0, clean * smoothstep(0.4, 0.95, healing))
		if index % 3 == 0:
			var bush: Vector2 = at + Vector2(-25, 7)
			canvas.draw_line(bush, bush + Vector2(0, -24 * clean), Color("263e2e"), 3, true)
			for branch in 3:
				var leaf_at: Vector2 = bush + Vector2((branch - 1) * 9, -12 - branch * 5) * clean
				patch(canvas, leaf_at, Vector2(15, 10) * clean, Color("52794f"), index + branch)
	if region == 0:
		for index in 100:
			var root := Vector2(85 + noise(index * 29) * 1100, 148 + noise(index * 43) * 550)
			var clean: float = growth(index % 44, healing)
			if clean > 0: plant(canvas, root, 7 * clean, sin(clock + index) * clean, false, 0)
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
			if region == 0 and healing > 0.35:
				var sapling: float = smoothstep(0.35, 1.0, healing)
				var tip: Vector2 = at + Vector2(0, -25 * sapling)
				canvas.draw_line(at, tip, Color("465638"), 3, true)
				for branch in 3:
					patch(canvas, tip + Vector2((branch - 1) * 10, branch * 4), Vector2(13, 9) * sapling, Color("6b8a52"), index + branch)
			patch(canvas, at, Vector2(18 + noise(index) * 12, 10), Color("333842"), index + 200)
			patch(canvas, at - Vector2(2, 3), Vector2(13, 6), stone, index + 200)
			if healing > 0.5:
				patch(canvas, at + Vector2(12, 2), Vector2(14, 5), Color("42604b"), index + 260)
	canvas.draw_rect(BOUNDS.grow(-3), Color(0.02, 0.03, 0.05, 0.28), false, 6)

static func growth(index: int, healing: float) -> float:
	var threshold: float = float(index) / 44 * 0.96
	return smoothstep(threshold, threshold + 0.025, healing)

static func plant(canvas: CanvasItem, root: Vector2, height: float, wind: float, flower: bool, bloom: float) -> void:
	if height < 2: return
	var tip: Vector2 = root + Vector2(wind, -height)
	var middle: Vector2 = root.lerp(tip, 0.55) + Vector2(wind * 0.3, 0)
	canvas.draw_polyline(PackedVector2Array([root, middle, tip]), Color("75945b"), 1.7, true)
	for side in [-1, 1]:
		var at: Vector2 = root.lerp(tip, 0.35 if side == -1 else 0.63)
		var leaf: Vector2 = at + Vector2(side * height * 0.38, -height * 0.15)
		canvas.draw_colored_polygon(PackedVector2Array([at, leaf, at + Vector2(side * height * 0.22, height * 0.07)]), Color("98b66c") if side == -1 else Color("658b58"))
	if flower and bloom > 0:
		var radius: float = 4.0 * bloom
		for petal in 5:
			var direction := Vector2.from_angle(petal * TAU / 5)
			canvas.draw_circle(tip + direction * radius, radius * 0.8, Color("e4be90"))
		canvas.draw_circle(tip, radius * 0.65, Color("f3db9a"))
