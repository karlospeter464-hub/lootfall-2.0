extends SceneTree

var game
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

func champion(number: int = 5):
	game.start_ascent_test(number)
	game.set_process(false)
	game._process(2.1)
	game.player.controls_enabled = false
	for index in game.wave_budget:
		game.spawn_enemy()
	for enemy in game.enemies.get_children():
		enemy.set_physics_process(false)
	game.boss.position = Vector2(400, 420)
	game.player.position = Vector2(650, 420)
	return game.boss

func remove_escorts() -> void:
	for enemy in game.enemies.get_children():
		if enemy != game.boss:
			enemy.take_damage(1000000000)
	await process_frame

func run() -> void:
	game = load("res://scenes/arena.tscn").instantiate()
	root.add_child(game)
	await process_frame
	check(game.burst_radius == 105 and is_equal_approx(game.burst_damage_ratio, 0.7), "New Burst defaults are 105 radius and 70 percent")
	game.restart_run()
	game.set_process(false)
	game.player.controls_enabled = false
	game.state = game.State.FIGHTING
	game.wave = 3
	game.remaining_to_spawn = 1
	game.spawn_enemy("chaser")
	var victim = game.enemies.get_child(0)
	victim.position = Vector2(600, 400)
	victim.health = 100
	game.area_damage(Vector2(500, 400), 10, game.burst_radius, null, true)
	check(victim.health == 90 and victim.flash > 0 and game.effects.any(func(effect): return effect.get("burst", false)), "Burst reaches a target 100 units away with hit flash and a distinct visual flag")
	victim.position.x = 606
	game.area_damage(Vector2(500, 400), 10, game.burst_radius, null, true)
	check(victim.health == 90, "Burst excludes targets beyond 105 units")
	var boss = champion()
	boss._physics_process(0)
	check(boss.charge_state == boss.Charge.WALKING, "Living escorts prevent the charge phase")
	await remove_escorts()
	game.remaining_to_spawn = 1
	boss._physics_process(0)
	check(boss.charge_state == boss.Charge.WALKING, "Pending escorts also prevent the charge phase")
	game.remaining_to_spawn = 0
	boss._physics_process(0)
	check(boss.charge_state == boss.Charge.WARNING and boss.charge_left == 0.7, "Last escort unlocks the announced 0.7-second charge")
	var direction: Vector2 = boss.charge_direction
	var endpoint: Vector2 = boss.charge_end
	game.player.position += Vector2(0, 150)
	boss.frozen = true
	boss._physics_process(0.5)
	check(boss.charge_left == 0.7, "Freeze preserves warning timer")
	boss.frozen = false
	game.pause_run()
	boss._physics_process(1)
	check(boss.charge_left == 0.7, "Esc pause preserves warning")
	game.resume_run()
	game.inventory_panel.open_inventory()
	boss._physics_process(1)
	check(boss.charge_left == 0.7, "Inventory pause preserves warning")
	game.inventory_panel.close_inventory()
	game.dev_console.open_console()
	boss._physics_process(1)
	check(boss.charge_left == 0.7, "F1 pause preserves warning")
	game.dev_console.close_console()
	boss._physics_process(0.7)
	check(boss.charge_state == boss.Charge.RUSHING and boss.charge_direction == direction and boss.charge_end == endpoint, "Rush locks original direction and endpoint")
	var hp: float = game.player.health
	boss._physics_process(0.4)
	check(boss.position == endpoint and game.player.health == hp and boss.charge_state == boss.Charge.RECOVERY, "Sidestep avoids the rush and opens recovery")
	var pos: Vector2 = boss.position
	var boss_hp: float = boss.health
	boss.take_projectile_hit(14)
	boss._physics_process(0.4)
	check(boss.position == pos and is_equal_approx(boss.health, boss_hp - 6), "Recovery is stationary and preserves Guardian armor and damage vulnerability")
	boss._physics_process(0.4)
	check(boss.charge_state == boss.Charge.WALKING and boss.charge_cooldown == 2, "Recovery returns to slow walking with a two-second cooldown")
	boss._physics_process(1.9)
	check(boss.charge_state == boss.Charge.WALKING, "Cooldown prevents immediate repeated rush")
	boss._physics_process(0.2)
	check(boss.charge_state == boss.Charge.WARNING, "Champion can charge again")
	boss = champion(15)
	await remove_escorts()
	boss._physics_process(0)
	check(boss.charge_state == boss.Charge.WARNING, "Later Champion milestones also use the ability")
	boss._physics_process(0.7)
	game.player.position = Vector2(650, 420)
	game.player.protection = 0
	hp = game.player.health
	boss._physics_process(0.4)
	check(is_equal_approx(game.player.health, hp - boss.contact_damage) and boss.charge_hit, "Swept rush hits a player between frame endpoints once")
	game.player.protection = 0
	boss._physics_process(0.2)
	check(is_equal_approx(game.player.health, hp - boss.contact_damage), "Recovery cannot deal repeated contact damage")
	boss = champion()
	await remove_escorts()
	boss.position = Vector2(1200, 680)
	game.player.position = Vector2(1210, 690)
	boss._physics_process(0)
	boss._physics_process(0.7)
	boss._physics_process(0.4)
	check(boss.position.x <= game.BOUNDS.end.x - 24 and boss.position.y <= game.BOUNDS.end.y - 24 and boss.charge_state == boss.Charge.RECOVERY, "Rush respects scaled body margins and ends at arena edge")
	pos = boss.position
	boss.take_damage(1000000000)
	boss._physics_process(1)
	check(boss.dead and boss.position == pos, "Boss death cancels further ability processing")
	await process_frame
	game.restart_run()
	game.set_process(false)
	game.player.controls_enabled = false
	game.wave = 3
	game.state = game.State.FIGHTING
	game.remaining_to_spawn = 1
	game.spawn_enemy("guardian")
	var ordinary = game.enemies.get_child(0)
	ordinary.set_physics_process(false)
	ordinary._physics_process(0.1)
	check(ordinary.boss_name.is_empty() and not ordinary.escorts_cleared.is_valid() and ordinary.charge_state == ordinary.Charge.WALKING, "Ordinary Guardians never acquire the Champion ability")
	game.mechanic_cards.assign([3, 4, 5])
	game.power_upgrades = 2
	game.quick_upgrades = 1
	game.fan_upgrades = 1
	game.equipment = {"scepter": "ember_scepter", "book": "focus_grimoire"}
	game.active_talents = {"power_1": 30, "power_5": 130, "flow_5": 130, "vitality_5": 130}
	game.update_build()
	game.player.haste_remaining = 2.4
	game.player.overcharge_hits = 3
	game.accept_item("cinder_codex")
	var panel = game.inventory_panel
	panel.open_inventory()
	panel.select_bag(0)
	await process_frame
	check(panel.cards_text.text.contains("Ember Power ×2") and panel.cards_text.text.contains("Quick Casting ×1") and panel.cards_text.text.contains("Fire Fan ×1"), "Inventory lists correct stack counts")
	check(panel.cards_text.text.contains("105 radius") and panel.cards_text.text.contains("70%") and panel.cards_text.text.contains("Piercing Flame") and panel.cards_text.text.contains("Overcharge"), "All mechanic cards show current rules")
	check(panel.effect_stats.text.contains("3/4") and panel.effect_stats.text.contains("2.4 s") and panel.effect_stats.text.contains("First Spark") and panel.effect_stats.text.contains("Renewal"), "Trigger states and timed buffs are distinguished from run effects")
	check(panel.equipped_stats.text.contains("%.3f" % game.player.effective_interval()) and panel.equipped_stats.text.contains("%.1f" % game.player.damage), "Displayed attack uses actual effective player values")
	check(panel.comparison.text.contains("OFF → ON") and panel.comparison.text.contains("Gain: Cinder Codex") and panel.comparison.text.contains("Lose: Focus Grimoire") and panel.comparison.text.contains("Run cards and talents stay active"), "Comparison explains gained/lost item effects separately from retained cards")
	check(panel.comparison.text.contains("Ember Burst on kill") and panel.comparison.text.contains("Charged main shot"), "Comparison includes card damage that scales with equipment")
	panel.equip_button.pressed.emit()
	var build: Dictionary = game.build_for(game.equipment.scepter, game.equipment.book)
	check(game.codex_active and panel.equipped_stats.text.contains("%.1f damage / 85" % build.splash_damage), "Equipping updates actual splash damage and radius immediately")
	game.player.overcharge_ready = true
	panel.refresh()
	check(panel.equipped_stats.text.contains("%.1f (Overcharge READY)" % build.charged_damage), "Overview identifies next charged main shot")
	game.player.haste_remaining = 0
	panel.refresh()
	check(panel.effect_stats.text.contains("Temporary buffs: none") and panel.effect_stats.text.contains("currently inactive"), "An available Second Wind talent is not shown as active")
	var footer: Rect2 = panel.destroy_button.get_global_rect()
	check(root.get_visible_rect().encloses(footer), "Inventory action footer stays inside the game viewport")
	var scroll = panel.screen.find_child("BuildScroll", true, false)
	check(scroll is ScrollContainer and scroll.get_v_scroll_bar().max_value > scroll.size.y, "Long card/effect list is vertically scrollable")
	await process_frame
	await process_frame
	scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
	await process_frame
	check(scroll.scroll_vertical > 0 and panel.effect_stats.get_global_rect().end.y <= scroll.get_global_rect().end.y + 2, "Bottom effects can be reached without clipping")
	panel.close_inventory()
	game.restart_run()
	panel.open_inventory()
	check(panel.cards_text.text == "No run cards selected yet." and game.equipment.book.is_empty() and game.player.overcharge_hits == 0, "New run clears overview cards gear and charge")
	game.queue_free()
	await process_frame
	print("COMBAT POLISH TEST: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
