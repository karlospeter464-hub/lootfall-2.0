extends Node2D

signal impact(at: Vector2, damage: float, primary: Object)

@export_range(100, 1500, 25) var speed: float = 650.0
@export_range(0.1, 5.0, 0.1) var lifetime: float = 1.8

var direction: Vector2 = Vector2.RIGHT
var damage: float = 14.0
var opening_bonus: float = 0.0
var age: float = 0.0

func _physics_process(delta: float) -> void:
	var next_position: Vector2 = global_position + direction * speed * delta
	# Sweep the full frame segment so fast shots cannot skip an enemy.
	var query := PhysicsRayQueryParameters2D.create(global_position, next_position, 2)
	query.hit_from_inside = true
	var result: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
	if not result.is_empty():
		var body: Object = result.collider
		if body.has_method("take_damage"):
			var full_health: bool = body.get("health") != null and body.get("max_health") != null and is_equal_approx(float(body.get("health")), float(body.get("max_health")))
			body.call("take_damage", damage * (1.0 + opening_bonus if full_health else 1.0), direction)
		impact.emit(result.position, damage, body)
		queue_free()
		return
	global_position = next_position
	age += delta
	if age >= lifetime:
		queue_free()
	queue_redraw()

func _draw() -> void:
	draw_line(-direction * 24, Vector2.ZERO, Color(0.95, 0.3, 0.1, 0.3), 12)
	draw_line(-direction * 17, Vector2.ZERO, Color("f58d4d"), 5)
	draw_circle(Vector2.ZERO, 5, Color("ffe7b1"))
