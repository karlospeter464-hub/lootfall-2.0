extends SceneTree

var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	if not OS.get_cmdline_user_args().has("--test-mode"):
		quit(1)
		return
	call_deferred("run")

func check(ok: bool, text: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(text)

func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://.godot/menu_review")
	root.get_texture().get_image().save_png("res://.godot/menu_review/" + name + ".png")

func run() -> void:
	var game = load("res://scenes/arena.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	var magic = game.companion_magic
	check(game.town_panel.screen.theme.has_stylebox("hover", "Button"), "Town uses shared menu theme")
	check(game.inventory_panel.screen.theme.has_stylebox("focus", "Button"), "Inventory has visible keyboard focus")
	check(game.dev_console.screen.theme.has_stylebox("tab_selected", "TabContainer"), "Developer tabs share navigation styles")
	check(magic.ability_stats("gravity").damage == 0, "Untalented Black Hole explicitly has zero damage")
	check(magic.ability_description("gravity").contains("crowd control"), "Black Hole explains its control purpose")
	check(is_equal_approx(magic.ability_stats("prism").damage, game.player.base_damage * 4), "Displayed baseline beam damage matches its formula")
	check(magic.ability_description("prism").contains("Pierces every enemy"), "Beam explains piercing")
	await capture("town")
	game.progress.rescue_companion("gravity")
	game.progress.rescue_companion("prism")
	game.progress.debug_set_echoes(5000)
	for friend in game.COMPANIONS.SPECIALS:
		for id in game.COMPANIONS.nodes(friend): check(game.progress.buy_companion(id), "Talent purchase for full ability preview")
	game.town_panel.show_tree()
	check(game.town_panel.friends.ability.text.contains("damage"), "Friends preview shows damage")
	check(game.town_panel.friends.ability.tooltip_text.contains("Collapse"), "Friends hover explains ability and talents")
	await capture("friends")
	game.town_panel.friends.friend_buttons.prism.pressed.emit()
	check(game.town_panel.friends.ability.text.contains("Light Beam"), "Changing friend changes its ability preview")
	await capture("prism_tree")
	game.town_panel.friends.close()
	game.restart_run()
	game.begin_wave()
	game.player.controls_enabled = false
	magic.refresh_hud()
	check(magic.hud.tooltip_text.contains("before enemy armor"), "HUD tooltip explains damage limits")
	var expected: float = game.player.base_damage * 1.48
	check(is_equal_approx(magic.ability_stats("prism").damage, expected * 4), "Equipped talent damage appears in beam stats")
	check(magic.cast(0, Vector2(650, 400)), "Gravity cast succeeds")
	check(is_equal_approx(magic.field.damage, magic.ability_stats("gravity").damage), "Inspection matches actual collapse damage")
	check(magic.cast(1, Vector2(900, 400)), "Prism cast succeeds")
	check(is_equal_approx(magic.beam.damage, magic.ability_stats("prism").damage), "Inspection matches actual beam damage")
	check(magic.ability_description("prism").contains("Marked targets") and magic.ability_description("prism").contains("split rays"), "Conditional talent damage is explained separately")
	game.inventory_panel.open_inventory()
	check(game.inventory_panel.ability_text.text.contains("Black Hole") and game.inventory_panel.ability_text.text.contains("Light Beam"), "I overview lists both equipped abilities")
	check(game.inventory_panel.ability_text.text.contains("cooldown"), "I overview includes cooldowns")
	await capture("inventory")
	game.inventory_panel.close_inventory()
	game.pause_run()
	await capture("pause")
	game.dev_console.open_console()
	game.dev_console.tabs.current_tab = 7
	await capture("developer")
	game.dev_console.close_console()
	game.resume_run()
	game.state = game.State.UPGRADE
	game.offered_cards.assign([0, 1, 2])
	game.show_overlay("CHOOSE YOUR UPGRADE", "Choose one improvement for this run.")
	game.refresh_upgrade_cards()
	await capture("cards")
	game.choose_upgrade(0)
	game.finish_run(false)
	await capture("result")
	game.queue_free()
	await process_frame
	print("MENUS / ABILITY INFO: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
