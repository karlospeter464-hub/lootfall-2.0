extends "res://scripts/enemy.gd"

signal armor_absorbed(at: Vector2, amount: float)

@export_range(0, 50, 1) var armor: float = 8.0
@export_range(0.05, 1, 0.05) var minimum_ratio: float = 0.2
@export_range(0.2, 2, 0.1) var charge_warning: float = 0.7
@export_range(0.1, 1, 0.05) var charge_duration: float = 0.4
@export_range(0.2, 2, 0.1) var charge_recovery: float = 0.8
@export_range(0.5, 8, 0.5) var charge_interval: float = 2.0
@export_range(300, 1500, 50) var charge_speed: float = 850.0

enum Charge { WALKING, WARNING, RUSHING, RECOVERY }
var charge_state: Charge = Charge.WALKING
var charge_left: float = 0.0
var charge_cooldown: float = 0.0
var charge_direction: Vector2 = Vector2.RIGHT
var charge_hit: bool = false
var charge_end: Vector2 = Vector2.ZERO
var escorts_cleared: Callable

func _physics_process(delta: float) -> void:
	if dead or frozen or not is_instance_valid(target) or get_tree().paused:
		return
	if boss_name.is_empty() or not escorts_cleared.is_valid():
		super._physics_process(delta)
		return
	charge_cooldown = maxf(0, charge_cooldown - delta)
	if charge_state == Charge.WALKING:
		if charge_cooldown <= 0 and escorts_cleared.call():
			var margin: float = maxf(17, 16 * scale.x)
			position = position.clamp(bounds.position + Vector2.ONE * margin, bounds.end - Vector2.ONE * margin)
			charge_direction = global_position.direction_to(target.global_position)
			if charge_direction.is_zero_approx():
				charge_direction = Vector2.RIGHT
			charge_state = Charge.WARNING
			charge_left = charge_warning
			var distance: float = charge_speed * charge_duration
			for axis in 2:
				if not is_zero_approx(charge_direction[axis]):
					var edge: float = bounds.end[axis] - margin if charge_direction[axis] > 0 else bounds.position[axis] + margin
					distance = minf(distance, maxf(0, (edge - position[axis]) / charge_direction[axis]))
			charge_end = position + charge_direction * distance
			knockback = Vector2.ZERO
			velocity = Vector2.ZERO
		else:
			super._physics_process(delta)
	else:
		flash = maxf(0, flash - delta)
		if charge_state == Charge.RUSHING:
			var origin: Vector2 = global_position
			# Fixed direction and swept contact prevent tracking and frame-skipped hits.
			position = position.move_toward(charge_end, charge_speed * minf(delta, charge_left))
			var nearest: Vector2 = Geometry2D.get_closest_point_to_segment(target.global_position, origin, global_position)
			if not charge_hit and nearest.distance_to(target.global_position) < 33:
				charge_hit = true
				target.take_damage(contact_damage)
			if position.is_equal_approx(charge_end):
				charge_left = 0
		charge_left = maxf(0, charge_left - delta)
		if charge_left <= 0:
			match charge_state:
				Charge.WARNING:
					charge_state = Charge.RUSHING
					charge_left = charge_duration
					charge_hit = false
				Charge.RUSHING:
					charge_state = Charge.RECOVERY
					charge_left = charge_recovery
				Charge.RECOVERY:
					charge_state = Charge.WALKING
					charge_cooldown = charge_interval
	queue_redraw()

func take_damage(amount: float, direction: Vector2 = Vector2.ZERO) -> void:
	if dead or amount <= 0:
		return
	var reduced: float = maxf(amount - armor, amount * minimum_ratio)
	if amount > reduced:
		armor_absorbed.emit(global_position, amount - reduced)
	super.take_damage(reduced, direction)

func _draw() -> void:
	super._draw()
	if charge_state in [Charge.WARNING, Charge.RUSHING] and not dead:
		var end: Vector2 = (charge_end - position) / global_scale.x
		draw_line(Vector2.ZERO, end, Color(1, 0.55, 0.2, 0.25), 66 / global_scale.x)
		draw_circle(end, 33 / global_scale.x, Color(1, 0.55, 0.2, 0.2))
		draw_line(Vector2.ZERO, end, Color("ffd291"), 3)
		draw_string(ThemeDB.fallback_font, Vector2(-38, -54), "CHARGE" if charge_state == Charge.WARNING else "RUSH", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("ffd291"))
	elif charge_state == Charge.RECOVERY and not dead:
		draw_string(ThemeDB.fallback_font, Vector2(-38, -54), "RECOVERY", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("baf7ff"))
	if armor > 0 and minimum_ratio < 1:
		var shield := PackedVector2Array([Vector2(-29, -25), Vector2(29, -25), Vector2(31, 18), Vector2(0, 34), Vector2(-31, 18), Vector2(-29, -25)])
		draw_polyline(shield, Color("c0f1ff") if flash > 0 else Color("6398b6"), 4 if flash > 0 else 1.5, true)

func draw_body() -> void:
	var moving: float = minf(velocity.length() / move_speed, 1.0) if charge_state == Charge.WALKING else 0.0
	var stomp: float = absf(sin(visual_clock * 7)) * moving
	var lean: float = charge_direction.x * 0.14 if charge_state == Charge.RUSHING else 0.0
	draw_set_transform(Vector2(0, -stomp), lean)
	var stone := Color("789d9c") if flash <= 0 else Color("fff1cc")
	draw_colored_polygon(PackedVector2Array([Vector2(-28, -24), Vector2(-14, -29), Vector2(0, -21), Vector2(14, -29), Vector2(28, -24), Vector2(30, 12), Vector2(16, 25), Vector2(-16, 25), Vector2(-30, 12)]), Color("101421"))
	draw_colored_polygon(PackedVector2Array([Vector2(-24, -21), Vector2(-14, -24), Vector2(-7, -16), Vector2(-13, 9), Vector2(-25, 6)]), stone)
	draw_colored_polygon(PackedVector2Array([Vector2(24, -21), Vector2(14, -24), Vector2(7, -16), Vector2(13, 9), Vector2(25, 6)]), stone.darkened(0.25))
	draw_colored_polygon(PackedVector2Array([Vector2(-10, -14), Vector2(10, -14), Vector2(14, 12), Vector2(0, 23), Vector2(-14, 12)]), Color("344a56"))
	draw_rect(Rect2(-10, -28, 20, 13), Color("101421"))
	draw_line(Vector2(-6, -22), Vector2(6, -22), Color("e4d0a4"), 3)
	draw_polyline(PackedVector2Array([Vector2(0, -9), Vector2(8, 3), Vector2(0, 13), Vector2(-8, 3), Vector2(0, -9)]), Color("b6e3dc") if charge_state != Charge.RUSHING else Color("ffb875"), 3, true)
	draw_line(Vector2(-13, 14), Vector2(-16, 24 + stomp * 2), stone, 7)
	draw_line(Vector2(13, 14), Vector2(16, 24 - stomp * 2), stone.darkened(0.2), 7)
	if charge_state == Charge.RUSHING:
		for index in 3:
			var start: Vector2 = -charge_direction * (28 + index * 8) + charge_direction.orthogonal() * (index - 1) * 12
			draw_line(start, start - charge_direction * 18, Color("e9b97d"), 2)
	draw_set_transform(Vector2.ZERO)
