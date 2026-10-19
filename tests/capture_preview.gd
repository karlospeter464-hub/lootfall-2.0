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
	var feedback_view: bool = OS.get_cmdline_user_args().has("--view=ce1_feedback")
	if feedback_view or OS.get_cmdline_user_args().has("--view=ce1") or OS.get_cmdline_user_args().has("--view=ce1_tools"):
		game.wave = 2
	elif OS.get_cmdline_user_args().has("--view=encounter"):
		game.wave = 1
	game.begin_wave()
	for index in (12 if feedback_view else 8):
		game.spawn_enemy()
		var enemy = game.enemies.get_child(index)
		enemy.position = Vector2(250 + index * 115, 240 + (index % 3) * 130)
		if feedback_view:
			enemy.position = Vector2(240 + (index % 4) * 230, 240 + (index / 4) * 160)
		enemy.set_physics_process(false)
		if enemy.get_script() == game.RANGED_ENEMY:
			enemy.charging = true
			enemy.charge_left = 0.6
			if feedback_view or OS.get_cmdline_user_args().has("--view=ce1"):
				enemy.concentration_hits = 3
			enemy.marked_position = game.player.position + Vector2(80, 70)
			enemy.queue_redraw()
		if feedback_view and enemy.get_script() == game.GUARDIAN_ENEMY:
			enemy.take_projectile_hit(14)
		if feedback_view and index == 7 and enemy.get_script() == game.RANGED_ENEMY:
			enemy.charging = false
			enemy.concentration_hits = 0
			enemy.interrupted_left = 1.0
			enemy.queue_redraw()
	game._cast(game.player.position + Vector2(80, 0), Vector2.RIGHT, 14)
	game.projectiles.get_child(0).set_physics_process(false)
	game.update_hud()
	var output: String = "res://.godot/arena_preview.png"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			output = argument.trim_prefix("--output=")
		elif argument in ["--view=followup_inventory", "--view=followup_inventory_effects"]:
			game.start_card_test(2)
			game.player.controls_enabled = false
			game.mechanic_cards.assign([3, 4, 5])
			game.power_upgrades = 2
			game.quick_upgrades = 1
			game.fan_upgrades = 1
			game.equipment = {"scepter": "ember_scepter", "book": "focus_grimoire"}
			for id in ["cinder_codex", "swift_scepter", "ember_scepter", "focus_grimoire", "cinder_codex", "swift_scepter", "ember_scepter", "focus_grimoire"]:
				game.accept_item(id)
			game.active_talents = {"power_5": 1, "flow_5": 1, "vitality_5": 1}
			game.update_build()
			game.player.health = 73
			game.player.haste_remaining = 2.4
			game.player.overcharge_hits = 3
			game.inventory_panel.open_inventory()
			game.inventory_panel.select_bag(0)
			if argument == "--view=followup_inventory_effects":
				game.inventory_panel.screen.find_child("BuildScroll", true, false).scroll_vertical = 10000
		elif argument == "--view=champion_charge":
			game.start_ascent_test(5)
			game._process(2.1)
			game.spawn_enemy()
			game.remaining_to_spawn = 0
			game.boss.position = Vector2(800, 400)
			game.player.position = Vector2(440, 480)
			game.player.controls_enabled = false
			game.boss._physics_process(0)
			game.boss.set_physics_process(false)
		elif argument == "--view=ce3_cards":
			game.state = game.State.UPGRADE
			game.show_overlay("CHOOSE YOUR UPGRADE", "CE3 mechanics preview — each card can be chosen once per run.")
			game.offered_cards.assign([3, 4, 5])
			game.refresh_upgrade_cards()
			paused = true
		elif argument == "--view=ce3_combat":
			game.start_card_test(2)
			game.set_process(false)
			game.player.controls_enabled = false
			game.mechanic_cards.assign([3, 4, 5])
			game.equipment.book = "cinder_codex"
			game.update_build()
			game.player.overcharge_ready = true
			for enemy in game.enemies.get_children():
				enemy.set_physics_process(false)
			game.player.cooldown = 0
			game.player.attack(Vector2.RIGHT)
			for shot in game.projectiles.get_children():
				shot.position += shot.direction * 90
				shot.set_physics_process(false)
			game.player.overcharge_ready = true
			game.queue_redraw()
		elif argument == "--view=upgrade":
			for enemy in game.enemies.get_children():
				game.enemies.remove_child(enemy)
				enemy.queue_free()
			game.remaining_to_spawn = 0
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
		elif argument in ["--view=ce2_boss5", "--view=ce2_boss10", "--view=ce2_reward", "--view=ce2_intro", "--view=ce2_metrics"]:
			var number: int = 10 if argument in ["--view=ce2_boss10", "--view=ce2_metrics"] else 5
			game.start_ascent_test(number)
			game.player.controls_enabled = false
			if argument == "--view=ce2_intro":
				continue
			game._process(2.1)
			for index in game.wave_budget:
				game.spawn_enemy()
				var enemy = game.enemies.get_child(index)
				enemy.set_physics_process(false)
				enemy.position = Vector2(900, 420) if enemy == game.boss else Vector2(240 + index * 125, 270 + (index % 2) * 280)
			game.player.controls_enabled = false
			if number == 10:
				game.boss.charging = true
				game.boss.protected_cast = true
				game.boss.charge_left = 0.9
				game.boss.marked_position = game.player.position + Vector2(90, 55)
			game.boss.queue_redraw()
			if argument == "--view=ce2_reward":
				for enemy in game.enemies.get_children():
					game.enemies.remove_child(enemy)
					enemy.queue_free()
				game.remaining_to_spawn = 0
				game.boss = null
				game.complete_wave()
			elif argument == "--view=ce2_metrics":
				game.dev_console.open_console()
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
	if OS.get_cmdline_user_args().has("--view=followup_inventory_effects"):
		await process_frame
		game.inventory_panel.screen.find_child("BuildScroll", true, false).scroll_vertical = 10000
		game.inventory_panel.screen.find_child("EquipmentScroll", true, false).scroll_vertical = 10000
		await process_frame
	game.queue_redraw()
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
