extends SceneTree

func _initialize() -> void:
	if not OS.get_cmdline_user_args().has("--test-mode"):
		push_error("Pass -- --test-mode to isolate preview progress.")
		quit(1)
		return
	call_deferred("capture")

func capture() -> void:
	var game = load("res://scenes/arena.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.restart_run()
	game.set_process(false)
	game.player.controls_enabled = false
	game.rng.seed = 42
	if OS.get_cmdline_user_args().has("--view=ce1") or OS.get_cmdline_user_args().has("--view=ce1_tools"):
		game.wave = 2
	elif OS.get_cmdline_user_args().has("--view=encounter"):
		game.wave = 1
	game.begin_wave()
	for index in 8:
		game.spawn_enemy()
		var enemy = game.enemies.get_child(index)
		enemy.position = Vector2(250 + index * 115, 240 + (index % 3) * 130)
		enemy.set_physics_process(false)
		if enemy.get_script() == game.RANGED_ENEMY:
			enemy.charging = true
			enemy.charge_left = 0.6
			if OS.get_cmdline_user_args().has("--view=ce1"):
				enemy.concentration_hits = 3
			enemy.marked_position = game.player.position + Vector2(80, 70)
			enemy.queue_redraw()
	game._cast(game.player.position + Vector2(80, 0), Vector2.RIGHT, 14)
	game.projectiles.get_child(0).set_physics_process(false)
	game.update_hud()
	var output: String = "res://.godot/arena_preview.png"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			output = argument.trim_prefix("--output=")
		elif argument == "--view=upgrade":
			game.wave = 2
			game.best_wave = 2
			game.complete_wave()
		elif argument == "--view=result":
			game.wave = 6
			game.best_wave = 6
			game.upgrades_chosen = 2
			game.kills = 108
			game.completed_waves = 6
			game.finish_run(true)
		elif argument == "--view=loot":
			game.drop_codex(game.player.position + Vector2(130, 0))
		elif argument == "--view=rarity_loot":
			var positions := [Vector2(-110, -80), Vector2(110, -80), Vector2(-110, 80), Vector2(110, 80)]
			var ids: Array = game.CATALOG.ITEMS.keys()
			for index in ids.size():
				game.drop_item(ids[index], game.player.position + positions[index])
		elif argument == "--view=rarity_metrics":
			game.dev_console.open_console()
		elif argument == "--view=ce1_tools":
			game.dev_console.open_console()
			game.dev_console.tabs.current_tab = 5
		elif argument == "--view=inventory":
			for id in ["ember_scepter", "cinder_codex", "swift_scepter", "focus_grimoire"]:
				game.accept_item(id)
			game.equip_item(0)
			game.equip_item(1)
			game.inventory_panel.open_inventory()
			game.inventory_panel.bag_buttons[3].grab_focus()
		elif argument in ["--view=town", "--view=skilltree"]:
			game.finish_run(false)
			game.return_to_town()
			game.progress.award(500, 3)
			for id in ["power_1", "power_2", "vitality_3", "vitality_4"]:
				game.buy_talent(id)
			game.town_panel.refresh()
			if argument == "--view=skilltree":
				game.town_panel.show_tree()
				game.town_panel.node_buttons["vitality_5"].grab_focus()
		elif argument == "--view=console":
			game.dev_console.open_console()
		elif argument == "--view=tuning":
			game.dev_console.open_console()
			game.dev_console.tabs.current_tab = 4
		elif argument == "--view=tree_tuning":
			game.dev_console.open_console()
			game.dev_console.tabs.current_tab = 6
	if game.state in [game.State.UPGRADE, game.State.FINISHED]:
		for container in [game.enemies, game.projectiles]:
			for child in container.get_children():
				container.remove_child(child)
				child.queue_free()
		game.remaining_to_spawn = 0
	game.update_hud()
	await process_frame
	await RenderingServer.frame_post_draw
	var error: Error = root.get_texture().get_image().save_png(output)
	if error != OK:
		push_error("Could not save arena preview: %s" % error_string(error))
		quit(1)
		return
	print("Preview saved: ", output)
	game.queue_free()
	await process_frame
	quit()
