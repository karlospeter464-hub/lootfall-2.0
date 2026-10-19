extends CharacterBody2D

const MIN_CAST_INTERVAL: float = 0.08
const MAX_PROJECTILES_PER_CAST: int = 9

signal health_changed(current: float, maximum: float)
signal defeated
signal survived_hit
signal cast(origin: Vector2, direction: Vector2, damage: float)

@export_range(50, 600, 5) var move_speed: float = 245.0
@export_range(1, 500, 1) var max_health: float = 100.0
@export_range(1, 100, 1) var base_damage: float = 14.0
@export_range(0.08, 2.0, 0.01) var base_cast_interval: float = 0.36
@export_range(0.1, 2.0, 0.05) var hit_protection: float = 0.7
@export var use_artwork: bool = true

@onready var artwork: Sprite2D = get_node_or_null("Artwork")
var visual_clock: float = 0.0
var cast_flash: float = 0.0
var artwork_base_scale: Vector2 = Vector2.ONE

var health: float
var health_limit: float
var hurt_haste_ratio: float = 0.0
var hurt_haste_duration: float = 3.0
var haste_remaining: float = 0.0
var damage: float
var cast_interval: float
var projectile_count: int
var cooldown: float = 0.0
var protection: float = 0.0
var aim: Vector2 = Vector2.RIGHT
var arena_bounds: Rect2 = Rect2(64, 128, 1152, 592)
var controls_enabled: bool = true
var invulnerable: bool = false
var spread_angle: float = 0.19
var main_shot: bool = true
var overcharge_enabled: bool = false
var overcharge_hits: int = 0
var overcharge_ready: bool = false
var kindling_remaining: float = 0.0
var momentum_hits: int = 0
var momentum_remaining: float = 0.0
var momentum_bonus: float = 0.0
var momentum_duration: float = 3.0

func _ready() -> void:
	if is_instance_valid(artwork):
		artwork_base_scale = artwork.scale
	reset_run()

func reset_run() -> void:
	health = max_health
	health_limit = max_health
	haste_remaining = 0.0
	damage = base_damage
	cast_interval = base_cast_interval
	projectile_count = 1
	cooldown = 0.0
	protection = 0.0
	invulnerable = false
	velocity = Vector2.ZERO
	overcharge_enabled = false
	overcharge_hits = 0
	overcharge_ready = false
	main_shot = true
	kindling_remaining = 0.0
	momentum_hits = 0
	momentum_remaining = 0.0
	visual_clock = 0.0
	cast_flash = 0.0
	update_artwork(0.0)
	health_changed.emit(health, max_health)
	queue_redraw()

func _physics_process(delta: float) -> void:
	cooldown = maxf(0.0, cooldown - delta)
	protection = maxf(0.0, protection - delta)
	haste_remaining = maxf(0.0, haste_remaining - delta)
	update_artwork(delta)
	kindling_remaining = maxf(0.0, kindling_remaining - delta)
	momentum_remaining = maxf(0.0, momentum_remaining - delta)
	if controls_enabled and health > 0.0:
		velocity = Input.get_vector("move_left", "move_right", "move_up", "move_down") * effective_move_speed()
		move_and_slide()
		position = position.clamp(arena_bounds.position + Vector2.ONE * 17, arena_bounds.end - Vector2.ONE * 17)
		var mouse_direction: Vector2 = get_global_mouse_position() - global_position
		if mouse_direction.length_squared() > 1.0:
			aim = mouse_direction.normalized()
		if Input.is_action_pressed("cast"):
			attack(aim)
	queue_redraw()

func effective_interval() -> float:
	return interval_with_haste(cast_interval)

func effective_move_speed() -> float:
	return move_speed * (1.0 + momentum_bonus if momentum_remaining > 0 else 1.0)

func interval_with_haste(interval: float) -> float:
	return maxf(MIN_CAST_INTERVAL, interval * (1.0 - hurt_haste_ratio if haste_remaining > 0 else 1.0))

func attack(direction: Vector2) -> void:
	if cooldown > 0.0 or health <= 0.0 or direction.is_zero_approx():
		return
	cooldown = effective_interval()
	cast_flash = 0.12
	for index in mini(projectile_count, MAX_PROJECTILES_PER_CAST):
		# Preserve the aimed shot and alternate additional shots on either side.
		var spread: float = 0.0
		if index > 0:
			spread = ceilf(index / 2.0) * spread_angle * (-1.0 if index % 2 == 1 else 1.0)
		var shot_direction: Vector2 = direction.normalized().rotated(spread)
		main_shot = index == 0
		cast.emit(global_position + shot_direction * 25, shot_direction, damage)
	main_shot = true

func record_direct_hit() -> void:
	if momentum_bonus > 0:
		momentum_hits += 1
		if momentum_hits >= 4:
			momentum_hits = 0
			momentum_remaining = momentum_duration
	if not overcharge_enabled or overcharge_ready:
		return
	overcharge_hits += 1
	if overcharge_hits >= 4:
		overcharge_hits = 0
		overcharge_ready = true
	queue_redraw()

func take_damage(amount: float) -> void:
	if amount <= 0.0 or protection > 0.0 or health <= 0.0 or (OS.is_debug_build() and invulnerable):
		return
	health = maxf(0.0, health - amount)
	if hurt_haste_ratio > 0 and health > 0:
		haste_remaining = hurt_haste_duration
	protection = hit_protection
	health_changed.emit(health, health_limit)
	if health <= 0.0:
		defeated.emit()
	else:
		survived_hit.emit()
	queue_redraw()

func _draw() -> void:
	draw_ellipse_shadow()
	if kindling_remaining > 0:
		draw_arc(Vector2.ZERO, 34, 0, TAU, 32, Color("ffb057"), 3)
	if momentum_remaining > 0:
		draw_arc(Vector2(0, 18), 28, 0, PI, 18, Color("84b8db"), 4)
	if not is_instance_valid(artwork) or not artwork.visible:
		draw_placeholder()
	if cast_flash > 0 and is_instance_valid(artwork) and artwork.visible:
		draw_circle(aim * 25, 5 + cast_flash * 35, Color(1, 0.75, 0.4, cast_flash / 0.12))
	draw_arc(Vector2.ZERO, 25, aim.angle() - 0.25, aim.angle() + 0.25, 10, Color("f0ca88"), 2)
	if overcharge_enabled:
		draw_arc(Vector2.ZERO, 30, -PI / 2, -PI / 2 + TAU * (1.0 if overcharge_ready else overcharge_hits / 4.0), 24, Color("baf7ff"), 3)
		if overcharge_ready:
			draw_circle(aim * 20, 9, Color("baf7ff"))

func update_artwork(delta: float) -> void:
	cast_flash = maxf(0.0, cast_flash - delta)
	if not is_instance_valid(artwork):
		return
	artwork.visible = use_artwork and artwork.texture != null
	visual_clock += delta
	# A tiny breath scales around the foot pivot; the gameplay body never moves.
	artwork.scale = artwork_base_scale * Vector2(1.0, 1.0 + sin(visual_clock * 2.5) * 0.006)
	artwork.self_modulate = Color(1.6, 1.35, 1.2) if protection > 0 else Color.WHITE

func draw_placeholder() -> void:
	var robe: Color = Color("498cbb") if protection <= 0.0 else Color("e8cab0")
	draw_colored_polygon(PackedVector2Array([Vector2(-16, 16), Vector2(-11, -8), Vector2(0, -20), Vector2(12, -8), Vector2(17, 16), Vector2(0, 23)]), robe.darkened(0.3))
	draw_circle(Vector2(0, -5), 12, robe)
	draw_circle(Vector2(2, -3), 7, Color("162332"))
	draw_line(Vector2(-2, -3), Vector2(6, -3), Color("a5e4ee"), 2)
	draw_line(Vector2(-10, 8), Vector2(10, 8), Color("d0ad73"), 3)
	var hand: Vector2 = aim * 20
	draw_line(hand - aim.orthogonal() * 12, hand + aim.orthogonal() * 12, Color("b69d7c"), 4)
	draw_circle(hand - aim.orthogonal() * 14, 5, Color("f8b268"))
	draw_rect(Rect2(-24, 1, 13, 15), Color("b8a688"))
	draw_line(Vector2(-18, 2), Vector2(-18, 15), Color("4e5263"), 2)

func draw_ellipse_shadow() -> void:
	draw_set_transform(Vector2.ZERO if is_instance_valid(artwork) and artwork.visible else Vector2(0, 18), 0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, 23, Color(0, 0, 0, 0.4))
	draw_set_transform(Vector2.ZERO)
