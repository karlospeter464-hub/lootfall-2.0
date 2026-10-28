extends CharacterBody2D

signal hit(at: Vector2, amount: float, killed: bool)
signal slain(at: Vector2)

@export_range(10, 300, 5) var move_speed: float = 85.0
@export_range(1, 500, 1) var max_health: float = 28.0
@export_range(1, 100, 1) var contact_damage: float = 14.0

var health: float
var target: Node2D
var bounds: Rect2
var flash: float = 0.0
var knockback: Vector2 = Vector2.ZERO
var dead: bool = false
var frozen: bool = false
var gravity_pull := Vector2.ZERO
var companion_slow: float = 0.0
var boss_name: String = ""
var visual_clock: float = 0.0

func _process(delta: float) -> void:
	if dead or frozen:
		return
	visual_clock += delta
	queue_redraw()

func _ready() -> void:
	health = max_health

func _physics_process(delta: float) -> void:
	if dead or frozen or not is_instance_valid(target):
		return
	flash = maxf(0.0, flash - delta)
	knockback = knockback.move_toward(Vector2.ZERO, 600 * delta)
	velocity = global_position.direction_to(target.global_position) * move_speed + knockback
	companion_motion(delta)
	move_and_slide()
	position = position.clamp(bounds.position + Vector2.ONE * 17, bounds.end - Vector2.ONE * 17)
	if global_position.distance_to(target.global_position) < 33.0:
		target.call("take_damage", contact_damage)
	queue_redraw()

func companion_motion(delta: float) -> void:
	companion_slow = maxf(0, companion_slow - delta)
	if companion_slow > 0: velocity *= 0.7
	velocity += gravity_pull

func take_projectile_hit(amount: float, direction: Vector2 = Vector2.ZERO) -> void:
	take_damage(amount, direction)

func take_damage(amount: float, direction: Vector2 = Vector2.ZERO) -> void:
	if dead or amount <= 0.0:
		return
	var actual_damage: float = minf(health, amount)
	health = maxf(0.0, health - amount)
	flash = 0.12
	knockback = direction * 130.0
	dead = health <= 0.0
	hit.emit(global_position, actual_damage, dead)
	if dead:
		collision_layer = 0
		slain.emit(global_position)
		queue_free()
	queue_redraw()

func _draw() -> void:
	draw_set_transform(Vector2(0, 13), 0, Vector2(1, 0.35))
	draw_circle(Vector2.ZERO, 22, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO)
	draw_body()
	if health < max_health:
		draw_rect(Rect2(-17, 31, 34, 4), Color("281f2b"))
		draw_rect(Rect2(-17, 31, 34 * health / max_health, 4), Color("df9194"))
	if not boss_name.is_empty():
		draw_polyline(PackedVector2Array([Vector2(-19, -30), Vector2(-21, -39), Vector2(-9, -34), Vector2(0, -44), Vector2(9, -34), Vector2(21, -39), Vector2(19, -30)]), Color("ffd18c"), 3, true)

func draw_body() -> void:
	var stride: float = sin(visual_clock * 15) * minf(velocity.length() / 85, 1.0)
	var facing: float = -1.0 if velocity.x < 0 else 1.0
	draw_set_transform(Vector2(0, -absf(stride) * 1.5), stride * 0.04, Vector2(facing, 1))
	var hide := Color("a76b81") if flash <= 0 else Color("fff1cc")
	var ink := Color("101421")
	# Separate limbs and a horned mask keep the small pursuer readable in a crowd.
	draw_line(Vector2(-6, 9), Vector2(-11 - stride * 2, 23), ink, 8)
	draw_line(Vector2(6, 9), Vector2(11 + stride * 2, 23), ink, 8)
	draw_line(Vector2(-6, 11), Vector2(-11 - stride * 2, 21), hide.darkened(0.45), 4)
	draw_line(Vector2(6, 11), Vector2(11 + stride * 2, 21), hide.darkened(0.45), 4)
	draw_colored_polygon(PackedVector2Array([Vector2(-10, -11), Vector2(9, -11), Vector2(15, 0), Vector2(8, 14), Vector2(-7, 14), Vector2(-15, 1)]), ink)
	draw_colored_polygon(PackedVector2Array([Vector2(-9, -8), Vector2(7, -8), Vector2(10, 1), Vector2(5, 10), Vector2(-5, 10), Vector2(-11, 1)]), hide.darkened(0.35))
	draw_colored_polygon(PackedVector2Array([Vector2(-11, -7), Vector2(-21, 2), Vector2(-22, 13), Vector2(-17, 17), Vector2(-14, 7), Vector2(-5, -1)]), ink)
	draw_line(Vector2(-11, -3), Vector2(-18, 4), hide, 5)
	draw_line(Vector2(-18, 4), Vector2(-18, 12), hide.darkened(0.15), 4)
	draw_colored_polygon(PackedVector2Array([Vector2(8, -7), Vector2(19, -1), Vector2(23, 11), Vector2(17, 16), Vector2(14, 5), Vector2(4, -1)]), ink)
	draw_line(Vector2(10, -3), Vector2(17, 2), hide, 5)
	draw_line(Vector2(17, 2), Vector2(20, 10), hide.darkened(0.15), 4)
	for side in [-1, 1]:
		draw_line(Vector2(side * 19, 11), Vector2(side * 22, 16), Color("d9bba4"), 1.5)
		draw_colored_polygon(PackedVector2Array([Vector2(side * 5, -21), Vector2(side * 14, -31), Vector2(side * 12, -17)]), ink)
		draw_line(Vector2(side * 9, -21), Vector2(side * 12, -28), hide, 2)
	draw_colored_polygon(PackedVector2Array([Vector2(-10, -22), Vector2(0, -27), Vector2(11, -21), Vector2(9, -10), Vector2(0, -5), Vector2(-9, -11)]), ink)
	draw_colored_polygon(PackedVector2Array([Vector2(-7, -20), Vector2(0, -23), Vector2(8, -19), Vector2(6, -12), Vector2(0, -8), Vector2(-6, -12)]), hide)
	draw_colored_polygon(PackedVector2Array([Vector2(-7, -18), Vector2(0, -15), Vector2(8, -18), Vector2(5, -11), Vector2(-5, -11)]), Color("302232"))
	draw_line(Vector2(-5, -16), Vector2(-1, -14), Color("ffe2ad"), 2)
	draw_line(Vector2(2, -14), Vector2(6, -16), Color("ffe2ad"), 2)
	draw_line(Vector2(-6, 4), Vector2(5, 6), Color("bc596c"), 3)
	draw_set_transform(Vector2.ZERO)
