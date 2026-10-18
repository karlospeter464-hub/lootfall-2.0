extends "res://scripts/enemy.gd"

var windup: float = 1.1
var attack_interval: float = 2.8
var attack_radius: float = 38.0
var preferred_distance: float = 280.0
var cooldown: float = 1.0
var charging: bool = false
var charge_left: float = 0.0
var marked_position: Vector2
var impact_left: float = 0.0

func _physics_process(delta: float) -> void:
	if dead or frozen or not is_instance_valid(target):
		return
	flash = maxf(0.0, flash - delta)
	impact_left = maxf(0.0, impact_left - delta)
	knockback = knockback.move_toward(Vector2.ZERO, 600 * delta)
	if charging:
		charge_left = maxf(0.0, charge_left - delta)
		velocity = knockback
		if charge_left <= 0:
			charging = false
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
			charge_left = windup
			marked_position = target.global_position
			velocity = Vector2.ZERO
	move_and_slide()
	position = position.clamp(bounds.position + Vector2.ONE * 17, bounds.end - Vector2.ONE * 17)
	queue_redraw()

func _draw() -> void:
	super._draw()
	draw_colored_polygon(PackedVector2Array([Vector2(0, -29), Vector2(18, -5), Vector2(0, 13), Vector2(-18, -5)]), Color("739bd0") if flash <= 0 else Color("fff1cc"))
	draw_circle(Vector2(0, -6), 6, Color("19253a"))
	draw_circle(Vector2(0, -6), 2, Color("f5d18b"))
	if charging or impact_left > 0:
		var point: Vector2 = to_local(marked_position)
		var color := Color("ed8ca8") if charging else Color("ffc2d2")
		draw_line(Vector2.ZERO, point, Color(color, 0.5), 1, true)
		draw_circle(point, attack_radius, Color(color, 0.12 if charging else 0.35))
		draw_arc(point, attack_radius, 0, TAU, 48, color, 2, true)
		if charging:
			draw_arc(point, attack_radius + 5, -PI / 2, -PI / 2 + TAU * (1.0 - charge_left / windup), 48, color, 3, true)
