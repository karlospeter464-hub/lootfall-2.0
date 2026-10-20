extends SceneTree

var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	if not OS.get_cmdline_user_args().has("--test-mode"):
		quit(1)
		return
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func run() -> void:
	var game = load("res://scenes/arena.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.restart_run()
	game.set_process(false)
	game.player.controls_enabled = false
	var player = game.player
	var art: Sprite2D = player.artwork
	check(not player.use_artwork and not art.visible, "Procedural mage is the Visual Lift default")
	player.use_artwork = true
	player.update_artwork(0)
	var image := Image.new()
	var image_error: Error = image.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/art/characters/apprentice/apprentice_crimson_grimoire.png"))
	print("ART SOURCE: ", image.get_size(), "; alpha bounds ", image.get_used_rect(), "; format ", image.get_format())
	check(image_error == OK and image.get_size() == Vector2i(1086, 1448) and image.detect_alpha() == Image.ALPHA_BLEND, "Original illustration is RGBA with real partial transparency")
	check(image.get_pixel(0, 0).a == 0 and image.get_pixel(1085, 1447).a == 0, "Source corners are transparent, not opaque black")
	check(art.visible and art.texture != null and art.texture.get_image().has_mipmaps(), "Scene uses imported art with mipmaps")
	check(art.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS, "Strong minification uses linear mipmap filtering")
	check(art.to_global(Vector2(600, 1410) + art.offset).is_equal_approx(player.global_position), "Foot anchor coincides with unchanged player position")
	check(player.get_node("CollisionShape2D").shape.radius == 15 and player.collision_layer == 1 and player.collision_mask == 0, "Collision geometry and layers are unchanged")
	var before: Vector2 = player.position
	player.aim = Vector2.UP
	player.update_artwork(0.4)
	check(art.rotation == 0 and player.rotation == 0, "Humanoid illustration does not rotate with aim")
	check(player.position == before and art.position == Vector2.ZERO and absf(art.scale.y - player.artwork_base_scale.y) < 0.001, "Breathing changes only artwork, anchored at the feet")
	check(player.move_speed == 245 and player.damage == 14 and player.cast_interval == 0.36, "Art does not alter base movement or attack values")
	game.begin_wave()
	var casts: Array = []
	player.cast.connect(func(origin, direction, amount): casts.append([origin, direction, amount]))
	for direction in [Vector2.RIGHT, Vector2.UP, Vector2(-1, 1).normalized()]:
		player.cooldown = 0
		player.attack(direction)
		var cast: Array = casts.back()
		check(cast[0].is_equal_approx(player.global_position + direction * 25) and cast[1].is_equal_approx(direction) and cast[2] == 14, "Existing main projectile origin/direction/damage preserved: " + str(direction))
	check(player.cast_flash == 0.12, "Accepted attack starts visual-only cast feedback")
	player.attack(Vector2.RIGHT)
	check(casts.size() == 3, "Cast feedback does not bypass cooldown")
	player.take_damage(10)
	player.update_artwork(0)
	check(player.health == 90 and art.self_modulate.r > 1, "Existing real damage flashes imported artwork")
	player.use_artwork = false
	player.update_artwork(0)
	check(not art.visible and player.health == 90 and player.damage == 14, "Inspector fallback hides art without changing game state")
	player.use_artwork = true
	player.update_artwork(0)
	art.texture = null
	player.update_artwork(0)
	check(not art.visible, "Missing texture on an existing node selects the placeholder")
	art.texture = load("res://assets/art/characters/apprentice/apprentice_crimson_grimoire.png")
	player.update_artwork(0)
	var clock: float = player.visual_clock
	paused = true
	for index in 3:
		await physics_frame
	check(player.visual_clock == clock, "Normal pause freezes visual animation with gameplay")
	paused = false
	player.reset_run()
	check(player.cast_flash == 0 and player.visual_clock == 0 and art.self_modulate == Color.WHITE, "New run clears temporary visual feedback")
	game.queue_free()
	await process_frame
	print("PLAYER ART TEST: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
