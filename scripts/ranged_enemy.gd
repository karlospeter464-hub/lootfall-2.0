extends "res://scripts/enemy.gd"

var windup: float = 1.4
var attack_interval: float = 2.0
var attack_radius: float = 38.0
@export_range(120, 400, 10) var preferred_distance: float = 210.0
var cooldown: float = 0.35
var charging: bool = false
var charge_left: float = 0.0
var marked_position: Vector2
var impact_left: float = 0.0
var interrupt_hits: int = 3
var concentration_hits: int = 0
var interrupted_left: float = 0.0
var interruptions: int = 0
var protected_cast: bool = false

func take_projectile_hit(amount: float, direction: Vector2 = Vector2.ZERO) -> void:
	super.take_projectile_hit(amount, direction)
	if dead or amount <= 0 or not charging or interrupt_hits <= 0 or protected_cast:
		return
	concentration_hits += 1
	if concentration_hits >= interrupt_hits:
		charging = false
		charge_left = 0.0
		concentration_hits = 0
		impact_left = 0.0
		cooldown = attack_interval
		interrupted_left = 1.0
		interruptions += 1
		protected_cast = not boss_name.is_empty()
	queue_redraw()

func take_damage(amount: float, direction: Vector2 = Vector2.ZERO) -> void:
	super.take_damage(amount, direction)
	if dead:
		charging = false
		charge_left = 0.0
		concentration_hits = 0
		impact_left = 0.0
		interrupted_left = 0.0
		protected_cast = false

func _physics_process(delta: float) -> void:
	if dead or frozen or not is_instance_valid(target):
		return
	flash = maxf(0.0, flash - delta)
	impact_left = maxf(0.0, impact_left - delta)
	interrupted_left = maxf(0.0, interrupted_left - delta)
	knockback = knockback.move_toward(Vector2.ZERO, 600 * delta)
	if charging:
		charge_left = maxf(0.0, charge_left - delta)
		velocity = knockback
		if charge_left <= 0:
			charging = false
			concentration_hits = 0
			protected_cast = false
			impact_left = 0.25
			cooldown = attack_interval
			if target.global_position.distance_to(marked_position) <= attack_radius:
				target.call("take_damage", contact_damage)
	else:
		cooldown = maxf(0.0, cooldown - delta)
		var distance: float = global_position.distance_to(target.global_position)
		var move_direction: Vector2 = global_position.direction_to(target.global_position)
		velocity = move_direction * move_speed * (1.0 if distance > preferred_distance + 30 else (-1.0 if distance < preferred_distance - 30 else 0.0)) + knockback
		if cooldown <= 0:
			charging = true
			concentration_hits = 0
			charge_left = windup
			marked_position = target.global_position
			velocity = Vector2.ZERO
	companion_motion(delta)
	move_and_slide()
	position = position.clamp(bounds.position + Vector2.ONE * 17, bounds.end - Vector2.ONE * 17)
	queue_redraw()

func _draw() -> void:
	super._draw()
	if interrupted_left > 0:
		draw_string(ThemeDB.fallback_font, Vector2(-29, -40), "BROKEN", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("99f5dc"))
		draw_line(Vector2(-23, -24), Vector2(-32, -33), Color("99f5dc"), 3)
		draw_line(Vector2(23, -24), Vector2(32, -33), Color("99f5dc"), 3)
	if charging and protected_cast:
		draw_string(ThemeDB.fallback_font, Vector2(-42, -47), "STEADY CAST", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("ffd18c"))
	elif charging and interrupt_hits > 0:
		draw_string(ThemeDB.fallback_font, Vector2(-42, -47), "INTERRUPT %d/%d" % [concentration_hits, interrupt_hits], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("99f5dc"))
		for index in interrupt_hits:
			draw_circle(Vector2((index - (interrupt_hits - 1) / 2.0) * 7, -36), 2.5, Color("99f5dc") if index < concentration_hits else Color("47526a"))
	if charging or impact_left > 0:
		var point: Vector2 = to_local(marked_position)
		# Boss body scaling must not enlarge the warning beyond its world-space hit radius.
		var local_radius: float = attack_radius / global_scale.x
		var color := Color("ed8ca8") if charging else Color("ffc2d2")
		draw_line(Vector2.ZERO, point, Color(color, 0.5), 1, true)
		draw_circle(point, local_radius, Color(color, 0.12 if charging else 0.35))
		draw_arc(point, local_radius, 0, TAU, 48, color, 2, true)
		if charging:
			draw_arc(point, local_radius + 5 / global_scale.x, -PI / 2, -PI / 2 + TAU * (1.0 - charge_left / windup), 48, color, 3, true)

func draw_body() -> void:
	var blue := Color("8c8bbd") if flash <= 0 else Color("fff1cc")
	draw_arc(Vector2(0, 18), 23, 0, TAU, 24, Color("5e597e"), 1.5)
	for index in 4:
		var rune: Vector2 = Vector2.from_angle(index * PI / 2 + visual_clock * 0.4) * 23
		draw_line(rune + Vector2(0, 18), rune * 1.18 + Vector2(0, 14), Color("aaa3dc"), 2)
	draw_set_transform(Vector2(0, sin(visual_clock * 3.5) * 2.5 - 3))
	draw_colored_polygon(PackedVector2Array([Vector2(0, -30), Vector2(17, -10), Vector2(12, 4), Vector2(17, 22), Vector2(0, 14), Vector2(-13, 23), Vector2(-11, 1), Vector2(-17, -10)]), Color("101421"))
	draw_colored_polygon(PackedVector2Array([Vector2(0, -25), Vector2(12, -10), Vector2(7, 3), Vector2(11, 17), Vector2(0, 10), Vector2(-8, 17), Vector2(-7, 0), Vector2(-12, -10)]), blue.darkened(0.3))
	draw_colored_polygon(PackedVector2Array([Vector2(0, -24), Vector2(10, -10), Vector2(0, -2), Vector2(-10, -10)]), blue)
	draw_circle(Vector2(0, -10), 5, Color("1a2034"))
	draw_line(Vector2(-3, -10), Vector2(3, -10), Color("ffe1a3"), 2)
	draw_polyline(PackedVector2Array([Vector2(0, -1), Vector2(4, 4), Vector2(0, 9), Vector2(-4, 4), Vector2(0, -1)]), Color("c7b5f0"), 1.5, true)
	if charging:
		var readiness: float = clampf(1 - charge_left / windup, 0, 1)
		draw_arc(Vector2(0, -10), 21, -PI / 2, -PI / 2 + TAU * readiness, 32, Color("ed8ca8"), 3)
		draw_line(Vector2(-20, -1), Vector2(-25, -15 - readiness * 6), Color("ed8ca8"), 3)
		draw_line(Vector2(20, -1), Vector2(25, -15 - readiness * 6), Color("ed8ca8"), 3)
	draw_set_transform(Vector2.ZERO)
