extends SceneTree

func _initialize() -> void:
	if not OS.get_cmdline_user_args().has("--test-mode"):
		quit(1)
		return
	call_deferred("capture")

func capture() -> void:
	var region: int = 0
	var stage: int = 0
	var view: String = "arena"
	var output: String = "res://.godot/world_preview.png"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--region="): region = clampi(argument.trim_prefix("--region=").to_int(), 0, 2)
		if argument.begins_with("--stage="): stage = clampi(argument.trim_prefix("--stage=").to_int(), 0, 100)
		if argument.begins_with("--view="): view = argument.trim_prefix("--view=")
		if argument.begins_with("--output="): output = argument.trim_prefix("--output=")
	var game = load("res://scenes/arena.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	var world: Dictionary = game.WORLD.fresh()
	for index in region:
		world.points[index] = game.WORLD.REGIONS[index].cost
	world.points[region] = game.WORLD.REGIONS[region].cost * stage / 100
	if view in ["live", "live_before"]:
		world.points[region] = game.WORLD.REGIONS[region].cost / 4 - 4
	game.progress._save(20000 if view == "tree" else 120, 0, {}, world)
	game.restart_run()
	game.run_region = region
	game.restoration_visual = game.WORLD.fraction(world, region)
	game.player.controls_enabled = false
	game.rng.seed = 42
	game.wave = 2
	game.begin_wave()
	for index in 8:
		game.spawn_enemy()
		var enemy = game.enemies.get_child(index)
		enemy.position = Vector2(240 + (index % 4) * 230, 250 + (index / 4) * 270)
		enemy.set_physics_process(false)
	game.remaining_to_spawn = 0
	if view == "live":
		for enemy in game.enemies.get_children():
			game.enemies.remove_child(enemy)
			enemy.queue_free()
		game.wave = 1
		game.completed_waves = 0
		game.complete_wave()
		if game.player.health <= 0 or game.progress.restoration_run.credited != 4:
			push_error("Live capture requires saved wave Restoration before death")
			quit(1)
			return
		await create_timer(1.4, true).timeout
	elif view == "complete":
		var near: Dictionary = game.WORLD.fresh()
		near.points[0] = 590
		game.progress._save(120, 0, {}, near)
		game.run_region = 0
		game.restoration_visual = 590.0 / 600
		game.completed_waves = 2
		game.player.take_damage(10000)
		if not game.reward_saved or game.progress.world.points != [600, 2, 0]:
			push_error("Completion capture requires successful atomic unlock and overflow")
			quit(1)
			return
		await create_timer(1.8, true).timeout
	elif view == "devtools":
		game.debug_jump_wave(10)
		game.dev_console.open_console()
		game.dev_console.tabs.current_tab = game.dev_console.tabs.get_child_count() - 1
	elif view in ["town", "tree", "sandbox"]:
		game._show_town()
		if view == "sandbox":
			game.enter_world_sandbox()
			game.progress._save(3000, 0, {}, game.WORLD.fresh())
			game.town_panel.refresh()
		if view == "tree":
			for id in game.TALENTS.NODES:
				if game.TALENTS.NODES[id].tier <= 9:
					game.buy_talent(id)
			game.town_panel.show_tree()
			game.town_panel.select_node("power_12")
			game.town_panel.node_buttons.power_12.grab_focus()
			await process_frame
			await process_frame
	game.update_hud()
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var error: Error = root.get_texture().get_image().save_png(output)
	if error != OK:
		quit(1)
		return
	print("WORLD CAPTURE: region ", region + 1, " / stage ", stage, " / ", view, " -> ", output)
	game.queue_free()
	await process_frame
	quit()
