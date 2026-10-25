extends Node2D

# Isolated visual proof only: no reference from the production Player scene.
var player: CharacterBody2D
var art: Sprite2D
var motion := Node2D.new()
var animator := AnimationPlayer.new()
var enabled: bool = true
var source_image: Image
var used_rect: Rect2i

func setup(actor: CharacterBody2D) -> void:
	player = actor
	art = player.artwork
	source_image = Image.load_from_file("res://tests/fixtures/apprentice_method_a_reference.png")
	assert(source_image != null and not source_image.is_empty(), "Prototype PNG must load")
	used_rect = source_image.get_used_rect()
	source_image.generate_mipmaps()
	art.texture = ImageTexture.create_from_image(source_image)
	art.centered = false
	# Temporary measured foot point for this illustration, not a final sprite contract.
	art.offset = Vector2(-590, -1410)
	player.artwork_base_scale = Vector2.ONE * (64.0 / used_rect.size.y)
	art.scale = player.artwork_base_scale
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	motion.name = "VisualMotion"
	motion.show_behind_parent = true
	player.add_child(motion)
	art.reparent(motion, false)
	motion.add_child(animator)
	var library := AnimationLibrary.new()
	library.add_animation("idle", make_animation(2.0, true, [Vector2.ONE, Vector2(1.0, 1.012), Vector2.ONE], [0.0, 0.0, 0.0], [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]))
	library.add_animation("move", make_animation(0.4, true, [Vector2.ONE, Vector2(1.015, 0.99), Vector2.ONE], [-0.025, 0.025, -0.025], [Vector2.ZERO, Vector2(0, -1.5), Vector2.ZERO]))
	library.add_animation("cast", make_animation(0.12, false, [Vector2.ONE, Vector2(1.025, 0.975), Vector2.ONE], [0.0, -0.035, 0.0], [Vector2.ZERO, Vector2(-1.5, 0), Vector2.ZERO]))
	animator.add_animation_library("", library)
	set_enabled(true)

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

func set_enabled(value: bool) -> void:
	enabled = value
	player.use_artwork = value
	player.update_artwork(0)
	if not value:
		animator.stop()
		motion.transform = Transform2D.IDENTITY
	else:
		animator.play("idle")
	player.queue_redraw()

func _process(_delta: float) -> void:
	if not enabled or not is_instance_valid(player) or get_tree().paused:
		return
	var state: String = "cast" if player.cast_flash > 0 else ("move" if player.velocity.length_squared() > 1 else "idle")
	if animator.current_animation != state:
		animator.play(state)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_V:
		set_enabled(not enabled)
