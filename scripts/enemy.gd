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
	move_and_slide()
	position = position.clamp(bounds.position + Vector2.ONE * 17, bounds.end - Vector2.ONE * 17)
	if global_position.distance_to(target.global_position) < 33.0:
		target.call("take_damage", contact_damage)
	queue_redraw()

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
	draw_set_transform(Vector2(0, absf(stride) * -2), stride * 0.04, Vector2(facing, 1))
	var red := Color("cf6677") if flash <= 0 else Color("fff1cc")
	draw_colored_polygon(PackedVector2Array([Vector2(-20, -6), Vector2(-8, -17), Vector2(15, -10), Vector2(22, 8), Vector2(8, 18), Vector2(-16, 15)]), Color("101421"))
	draw_colored_polygon(PackedVector2Array([Vector2(-16, -4), Vector2(-7, -12), Vector2(11, -8), Vector2(17, 8), Vector2(5, 14), Vector2(-12, 11)]), red.darkened(0.35))
	draw_line(Vector2(-12, 9), Vector2(-20, 20 + stride * 2), Color("9b596f"), 5)
	draw_line(Vector2(9, 11), Vector2(18, 21 - stride * 2), Color("9b596f"), 5)
	draw_colored_polygon(PackedVector2Array([Vector2(-8, -19), Vector2(5, -25), Vector2(18, -16), Vector2(11, -5), Vector2(-4, -6)]), Color("101421"))
	draw_colored_polygon(PackedVector2Array([Vector2(-5, -17), Vector2(5, -21), Vector2(14, -15), Vector2(8, -9), Vector2(-2, -9)]), red)
	draw_line(Vector2(2, -16), Vector2(10, -13), Color("fff0bf"), 2.5)
	draw_set_transform(Vector2.ZERO)
