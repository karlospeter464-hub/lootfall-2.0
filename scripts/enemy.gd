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
	var color: Color = Color("ba6d78") if flash <= 0 else Color("fff1cc")
	draw_colored_polygon(PackedVector2Array([Vector2(-17, 10), Vector2(-14, -8), Vector2(-5, -19), Vector2(8, -15), Vector2(17, 0), Vector2(12, 16), Vector2(-5, 19)]), color.darkened(0.25))
	draw_circle(Vector2(0, -4), 10, color)
	draw_line(Vector2(-6, -5), Vector2(-1, -3), Color("ffe0a8"), 3)
	draw_line(Vector2(2, -3), Vector2(7, -5), Color("ffe0a8"), 3)
	if health < max_health:
		draw_rect(Rect2(-17, -28, 34, 4), Color("281f2b"))
		draw_rect(Rect2(-17, -28, 34 * health / max_health, 4), Color("df9194"))
	if not boss_name.is_empty():
		draw_polyline(PackedVector2Array([Vector2(-19, -30), Vector2(-21, -39), Vector2(-9, -34), Vector2(0, -44), Vector2(9, -34), Vector2(21, -39), Vector2(19, -30)]), Color("ffd18c"), 3, true)
