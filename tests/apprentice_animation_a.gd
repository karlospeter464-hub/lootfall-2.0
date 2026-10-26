extends Node2D

# Test-only visual controller; production Player scene never references this file.
var player: CharacterBody2D
var art: Sprite2D
var motion := Node2D.new()
var animator := AnimationPlayer.new()
var enabled: bool = true
var source_image: Image
var used_rect: Rect2i
var mode: int = 2 # 0 procedural, 1 original v01/A, 2 A+.
var cast_intent: bool = false
var clock: float = 0.0
var shot_age: float = 10.0
var shot_point := Vector2.ZERO
var fire_gain: float = 1.0
var fire_material := ShaderMaterial.new()
var original_library: AnimationLibrary
var plus_library: AnimationLibrary

func setup(actor: CharacterBody2D) -> void:
	player = actor
	art = player.artwork
	source_image = Image.load_from_file("res://tests/fixtures/lootfall_apprentice_runtime_candidate_v01.png")
	assert(source_image != null and not source_image.is_empty(), "Prototype PNG must load")
	used_rect = source_image.get_used_rect()
	source_image.generate_mipmaps()
	art.texture = ImageTexture.create_from_image(source_image)
	art.centered = false
	art.offset = Vector2(-128, -300)
	player.artwork_base_scale = Vector2.ONE * (64.0 / used_rect.size.y)
	art.scale = player.artwork_base_scale
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	motion.name = "VisualMotion"
	motion.show_behind_parent = true
	player.add_child(motion)
	art.reparent(motion, false)
	motion.add_child(animator)
	original_library = AnimationLibrary.new()
	original_library.add_animation("idle", make_animation(2.0, true, [Vector2.ONE, Vector2(1.0, 1.012), Vector2.ONE], [0.0, 0.0, 0.0], [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]))
	original_library.add_animation("move", make_animation(0.4, true, [Vector2.ONE, Vector2(1.015, 0.99), Vector2.ONE], [-0.025, 0.025, -0.025], [Vector2.ZERO, Vector2(0, -1.5), Vector2.ZERO]))
	original_library.add_animation("cast", make_animation(0.12, false, [Vector2.ONE, Vector2(1.025, 0.975), Vector2.ONE], [0.0, -0.035, 0.0], [Vector2.ZERO, Vector2(-1.5, 0), Vector2.ZERO]))
	plus_library = AnimationLibrary.new()
	plus_library.add_animation("idle", make_animation(2.8, true, [Vector2.ONE, Vector2(1.004, 1.018), Vector2.ONE], [-0.012, 0.012, -0.012], [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]))
	plus_library.add_animation("move", make_animation(0.34, true, [Vector2.ONE, Vector2(1.012, 0.994), Vector2.ONE], [0.0, 0.0, 0.0], [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]))
	plus_library.add_animation("prepare", make_animation(0.10, false, [Vector2.ONE, Vector2(0.985, 1.014), Vector2(0.98, 1.02)], [0.0, -0.012, -0.02], [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]))
	plus_library.add_animation("cast", make_animation(0.24, false, [Vector2(0.98, 1.02), Vector2(1.035, 0.985), Vector2.ONE], [-0.02, 0.025, 0.0], [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]))
	fire_material.shader = load("res://tests/apprentice_fire.gdshader")
	player.cast.connect(on_cast)
	player.health_changed.connect(on_health_changed)
	set_mode(2)

func make_animation(duration: float, looping: bool, scales: Array, angles: Array, offsets: Array) -> Animation:
	var animation := Animation.new()
	animation.length = duration
	animation.loop_mode = Animation.LOOP_LINEAR if looping else Animation.LOOP_NONE
	for property in ["scale", "rotation", "position"]:
		var track: int = animation.add_track(Animation.TYPE_VALUE)
		animation.track_set_path(track, NodePath(".:" + property))
		var values: Array = scales if property == "scale" else (angles if property == "rotation" else offsets)
		for index in 3:
			animation.track_insert_key(track, duration * index / 2.0, values[index])
	return animation

func set_mode(value: int) -> void:
	assert(value >= 0 and value <= 2)
	mode = value
	enabled = mode != 0
	animator.stop()
	if animator.has_animation_library(""): animator.remove_animation_library("")
	animator.add_animation_library("", plus_library if mode == 2 else original_library)
	motion.transform = Transform2D.IDENTITY
	art.material = fire_material if mode == 2 else null
	shot_age = 10.0
	player.use_artwork = enabled
	player.update_artwork(0)
	if enabled: animator.play("idle")
	player.queue_redraw()
	queue_redraw()

func set_enabled(value: bool) -> void:
	set_mode(2 if value else 0)

func on_health_changed(_health: float, _maximum: float) -> void:
	if player.visual_clock == 0 and player.cooldown == 0 and player.cast_flash == 0:
		clock = 0.0
		set_mode(mode)

func on_cast(origin: Vector2, _direction: Vector2, _damage: float) -> void:
	if mode != 2 or not player.main_shot: return
	shot_age = 0.0
	shot_point = origin
	animator.stop()
	animator.play("cast")
	animator.advance(0)

func _process(delta: float) -> void:
	if not enabled or not is_instance_valid(player) or get_tree().paused: return
	clock += delta
	shot_age += delta
	var state: String = "idle"
	if mode == 1:
		state = "cast" if player.cast_flash > 0 else ("move" if player.velocity.length_squared() > 1 else "idle")
	else:
		var preparing: bool = (cast_intent or Input.is_action_pressed("cast")) and player.cooldown > 0 and player.cooldown <= 0.10 and shot_age >= 0.24
		state = "cast" if shot_age < 0.24 else ("prepare" if preparing else ("move" if player.velocity.length_squared() > 1 else "idle"))
		motion.skew = lerpf(motion.skew, -player.velocity.x / player.move_speed * 0.055, clampf(delta * 12, 0, 1))
		fire_gain = 1.0 + sin(clock * 11.0) * 0.10 + sin(clock * 23.0) * 0.04
		fire_material.set_shader_parameter("fire_gain", fire_gain + (0.28 if preparing else 0.0) + maxf(0, 1.0 - shot_age / 0.18) * 0.55)
	if animator.current_animation != state: animator.play(state)
	queue_redraw()

func _draw() -> void:
	if mode != 2 or not is_instance_valid(art) or not art.visible: return
	var flame: Vector2 = to_local(art.to_global(Vector2(54, 121) + art.offset))
	draw_circle(flame, 3.8 + fire_gain, Color(1.0, 0.32, 0.05, 0.11 * fire_gain))
	draw_circle(flame, 2.0, Color(1.0, 0.72, 0.26, 0.15 * fire_gain))
	if shot_age < 0.18:
		var pulse: float = shot_age / 0.18
		draw_arc(to_local(shot_point), 3 + pulse * 12, 0, TAU, 18, Color(1.0, 0.66, 0.24, (1 - pulse) * 0.85), 1.5, true)
		draw_circle(to_local(shot_point), 3 * (1 - pulse), Color(1.0, 0.92, 0.65, 1 - pulse))

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_V:
		set_mode((mode + 2) % 3)
