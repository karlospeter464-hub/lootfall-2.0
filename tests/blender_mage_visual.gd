extends "res://scripts/apprentice_visual.gd"

const RENDER_TEXTURE = preload("res://tests/fixtures/blender_mage/mage_idle.png")
const FOOT = Vector2(256, 560.55891)
var render_selected: bool = true

func setup(actor: CharacterBody2D) -> void:
	if not OS.get_cmdline_user_args().has("--test-mode"):
		push_error("Blender comparison requires -- --test-mode")
		get_tree().quit(1)
		return
	super.setup(actor)
	select_render(true)

func select_render(value: bool) -> void:
	render_selected = value
	set_mode(1 if value else 2)
	source_image = (RENDER_TEXTURE if value else ART_TEXTURE).get_image()
	used_rect = source_image.get_used_rect()
	art.texture = RENDER_TEXTURE if value else ART_TEXTURE
	art.offset = -FOOT if value else Vector2(-128, -300)
	player.artwork_base_scale = Vector2.ONE * (64.0 / used_rect.size.y)
	player.update_artwork(0)
	# shortcut: whole-image impulses only; independent limbs require authored frames or a rig.

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_V:
		select_render(not render_selected)
