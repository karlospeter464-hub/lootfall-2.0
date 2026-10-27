extends "res://tests/visual_depth/depth_slice.gd"

var mage_switch: MageSwitch

class MageSwitch extends Node2D:
	var player: CharacterBody2D
	var candidate: ImageTexture
	var selected: bool = true
	const FOOT = Vector2(320,750)

	func select(value: bool) -> void:
		selected = value
		var visual = player.visuals
		visual.set_mode(1 if value else 2)
		visual.art.texture = candidate if value else visual.ART_TEXTURE
		visual.source_image = visual.art.texture.get_image()
		visual.used_rect = visual.source_image.get_used_rect()
		visual.art.offset = -FOOT if value else Vector2(-128,-300)
		player.artwork_base_scale = Vector2.ONE * (64.0 / visual.used_rect.size.y)
		player.update_artwork(0)
		visual.animator.play("idle")
		visual.animator.seek(0,true)
		# shortcut: one facing with existing whole-image impulses; no independent limb cycle.

	func _unhandled_key_input(event: InputEvent) -> void:
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_V:
			select(not selected)

func setup_character(player: CharacterBody2D) -> void:
	var image := Image.new()
	check(image.load_svg_from_string(FileAccess.get_file_as_string("res://tests/faceted_mage/mage_faceted.svg"),2.0) == OK,"Code-native mage SVG loads")
	check(image.detect_alpha() == Image.ALPHA_BLEND,"Mage has antialiased transparent edges")
	if DisplayServer.get_name() != "headless": check(image.save_png(output+"/mage_faceted.png") == OK,"Save rendered source preview")
	image.generate_mipmaps()
	mage_switch = MageSwitch.new()
	mage_switch.player = player
	mage_switch.candidate = ImageTexture.create_from_image(image)
	player.add_child(mage_switch)
	player.visuals.set_process_unhandled_key_input(false)
	mage_switch.select(true)
	check(is_equal_approx(player.visuals.used_rect.size.y * player.artwork_base_scale.y,64),"New mage keeps 64 logical pixel height")
	check(player.artwork.to_global(MageSwitch.FOOT+player.artwork.offset).is_equal_approx(player.global_position),"Mage foot point stays on original body anchor")
	var key := InputEventKey.new()
	key.keycode=KEY_V
	key.pressed=true
	mage_switch._unhandled_key_input(key)
	check(not mage_switch.selected and player.visuals.mode == 2 and player.artwork.texture == player.visuals.ART_TEXTURE,"V restores complete original v01/A+ fallback")
	mage_switch._unhandled_key_input(key)
	check(mage_switch.selected and player.artwork.material == null,"V selects faceted mage without original fire-mask shader")

func pair(game) -> void:
	paused = true
	var state: String = snapshot(game)
	mage_switch.select(false)
	await capture("before")
	mage_switch.select(true)
	await capture("after")
	check(snapshot(game) == state,"Mage comparison keeps original actor, enemies, projectiles, health, RNG, aim and camera")
	pair_verified = snapshot(game) == state
	paused = false
