extends SceneTree

const VISUAL = preload("res://tests/apprentice_animation_a.gd")
var checks: int = 0
var failures: int = 0
var output: String = "res://.godot/visual_slice_a"
var rendered_bounds: Dictionary = {}

func _initialize() -> void:
	if not OS.get_cmdline_user_args().has("--test-mode"):
		push_error("Visual slice requires -- --test-mode; normal saves are never used.")
		quit(1)
		return
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="): output = argument.trim_prefix("--output=")
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(output + "/" + name + ".png") == OK, "Save " + name)

func measure_sprite() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(160, 160)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var actor = load("res://scenes/player.tscn").instantiate()
	viewport.add_child(actor)
	actor.position = Vector2(80, 90)
	actor.controls_enabled = false
	actor.set_physics_process(false)
	await process_frame
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	rendered_bounds["current_default_1x"] = str(image.get_used_rect())
	check(image.save_png(output + "/current_sprite_1x.png") == OK, "Save actual 1x current sprite")
	viewport.queue_free()
	await process_frame

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	if DisplayServer.get_name() != "headless": await measure_sprite()
	var game = load("res://scenes/arena.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.restart_run()
	game.set_process(false)
	var player = game.player
	player.controls_enabled = false
	player.set_physics_process(false)
	game.rng.seed = 42
	game.wave = 2
	game.begin_wave()
	for index in 12:
		game.spawn_enemy()
		var enemy = game.enemies.get_child(index)
		enemy.position = Vector2(240 + (index % 4) * 230, 240 + (index / 4) * 160)
		enemy.set_physics_process(false)
		enemy.set_process(false)
		if enemy.get_script() == game.RANGED_ENEMY:
			enemy.charging = true
			enemy.charge_left = 0.6
			enemy.marked_position = player.position + Vector2(80, 70)
	game.remaining_to_spawn = 0
	game.update_hud()
	var automate: bool = OS.get_cmdline_user_args().has("--verify") or OS.get_cmdline_user_args().has("--capture")
	check(not player.use_artwork and not player.artwork.visible, "Production procedural default remains")
	if automate and DisplayServer.get_name() != "headless": await capture("before")
	var before: Transform2D = player.transform
	var radius: float = player.get_node("CollisionShape2D").shape.radius
	var health: float = player.health
	var rng_state: int = game.rng.state
	var visual = VISUAL.new()
	player.add_child(visual)
	visual.setup(player)
	visual.set_process(false)
	check(visual.source_image.detect_alpha() == Image.ALPHA_BLEND, "PNG has real partial-alpha edges")
	check(visual.source_image.get_pixel(0, 0).a == 0, "PNG corner is transparent")
	check(visual.art.texture.get_image().has_mipmaps(), "Minified illustration has mipmaps")
	check(player.artwork.visible and player.use_artwork, "Only fixture enables new PNG")
	check(player.transform == before and radius == 15 and player.health == health, "Artwork leaves actor and collision untouched")
	check(player.move_speed == 245 and player.damage == 14 and player.cast_interval == 0.36, "Base gameplay values unchanged")
	check(visual.art.to_global(Vector2(590, 1410) + visual.art.offset).is_equal_approx(player.global_position), "Prototype foot point anchored to actor")
	for state in ["idle", "move", "cast"]:
		visual.animator.play(state)
		visual.animator.seek(visual.animator.get_animation(state).length / 2, true)
		check(player.transform == before, state + " animates visuals, not physics")
		check(not visual.motion.transform.is_equal_approx(Transform2D.IDENTITY), state + " has actual transform keys")
	visual.animator.play("idle")
	visual.animator.seek(0, true)
	if automate and DisplayServer.get_name() != "headless": await capture("prototype_idle")
	var casts: Array = []
	player.cast.connect(func(origin, direction, amount): casts.append([origin, direction, amount]))
	player.attack(Vector2.RIGHT)
	visual._process(0)
	check(visual.animator.current_animation == "cast" and casts.size() == 1, "Real accepted attack selects cast")
	check(casts[0][0].is_equal_approx(player.global_position + Vector2.RIGHT * 25) and casts[0][2] == 14, "Projectile origin/damage preserved")
	player.attack(Vector2.RIGHT)
	check(casts.size() == 1, "Animation never bypasses attack cooldown")
	visual.animator.seek(0.06, true)
	if automate and DisplayServer.get_name() != "headless": await capture("prototype_cast")
	player.cast_flash = 0
	player.velocity = Vector2.RIGHT * player.move_speed
	visual._process(0)
	check(visual.animator.current_animation == "move", "Existing velocity selects movement")
	player.velocity = Vector2.ZERO
	visual._process(0)
	check(visual.animator.current_animation == "idle", "Stopping selects idle")
	player.take_damage(10)
	player.update_artwork(0)
	check(player.health == health - 10 and visual.art.self_modulate.r > 1, "Existing hurt flash preserved")
	visual.set_enabled(false)
	check(not visual.art.visible and visual.motion.transform == Transform2D.IDENTITY, "V restores original procedural fallback")
	visual.set_enabled(true)
	var texture: Texture2D = visual.art.texture
	visual.art.texture = null
	player.update_artwork(0)
	check(not visual.art.visible, "Missing texture still invokes production fallback")
	visual.art.texture = texture
	player.reset_run()
	visual._process(0)
	check(player.cast_flash == 0 and player.visual_clock == 0 and visual.animator.current_animation == "idle", "Reset clears feedback and selects idle")
	paused = true
	var transform: Transform2D = visual.motion.transform
	await process_frame
	await process_frame
	check(visual.motion.transform == transform, "Pause freezes AnimationPlayer")
	paused = false
	check(game.rng.state == rng_state, "Visual animation never consumes gameplay RNG")
	var file := FileAccess.open(output + "/metrics.json", FileAccess.WRITE)
	check(file != null, "Metrics file opens")
	var metrics := {"rendered_sprite_bounds": rendered_bounds, "viewport": str(root.get_visible_rect().size), "canvas_transform": str(player.get_canvas_transform()), "source_size": str(visual.source_image.get_size()), "alpha_bounds": str(visual.used_rect), "prototype_scale": player.artwork_base_scale.x, "prototype_visible_height_logical": 64, "collision_radius": radius, "projectile_origin_distance": 25, "checks": checks, "failures": failures}
	if file: file.store_string(JSON.stringify(metrics, "\t"))
	print("VISUAL A: ", metrics)
	print("VISUAL A TEST: %d checks, %d failures" % [checks, failures])
	if automate or failures > 0:
		game.queue_free()
		await process_frame
		quit(0 if failures == 0 else 1)
		return
	visual.set_process(true)
	player.set_physics_process(true)
	player.controls_enabled = true
	game.set_process(true)
	for enemy in game.enemies.get_children():
		enemy.set_physics_process(true)
		enemy.set_process(true)
	print("ISOLATED VISUAL A: WASD / Mouse / LMB; V toggles procedural fallback; F1 / Escape retained.")
