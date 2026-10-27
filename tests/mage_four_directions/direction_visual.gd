extends Node2D

signal facing_changed(animator: AnimationPlayer)

const PUPPET = preload("res://tests/mage_four_directions/direction_puppet.gd")
const LABELS = ["front","right","back","left"]
const VECTORS = [Vector2.DOWN,Vector2.RIGHT,Vector2.UP,Vector2.LEFT]
# Measured from generated boots, not the asymmetric hat/book silhouette.
const FEET = [Vector2.ZERO,Vector2(610,1255),Vector2(590,1295),Vector2(590,1235)]
const HEIGHTS = [274.0,1162.0,1136.0,1094.0]
var player: CharacterBody2D
var puppets: Array[Node2D] = []
var facing: int = 0
var enabled: bool = true
var seen: Array[int] = []

func setup(actor: CharacterBody2D) -> void:
	player = actor
	player.visuals.set_process_unhandled_key_input(false)
	for direction in 4:
		var texture: Texture2D = PUPPET.SOURCE
		if direction != 0:
			var image := Image.load_from_file("res://tests/mage_four_directions/source/"+LABELS[direction]+".png")
			assert(image != null and image.detect_alpha() == Image.ALPHA_BLEND,"Directional image must have real alpha")
			var ratio: float = 274.0/HEIGHTS[direction]
			var at: Vector2i = Vector2i((Vector2(128,300)-FEET[direction]*ratio).round())
			image.resize(roundi(image.get_width()*ratio),roundi(image.get_height()*ratio),Image.INTERPOLATE_LANCZOS)
			var normalized := Image.create(256,320,false,Image.FORMAT_RGBA8)
			normalized.fill(Color.TRANSPARENT)
			normalized.blit_rect(image,Rect2i(Vector2i.ZERO,image.get_size()),at)
			normalized.generate_mipmaps()
			texture = ImageTexture.create_from_image(normalized)
		var puppet = PUPPET.new()
		puppet.configure(direction,texture)
		player.artwork.add_child(puppet)
		puppet.setup(player)
		puppet.selected = false
		puppet.mesh.visible = false
		puppet.animator.active = false
		puppet.set_process_unhandled_key_input(false)
		puppets.append(puppet)
	puppets[0].select(true)
	puppets[0].animator.active = true
	update_facing()

func update_facing() -> void:
	var aim: Vector2 = player.aim
	var next: int = (1 if aim.x > 0 else 3) if absf(aim.x) > absf(aim.y) else (0 if aim.y > 0 else 2)
	# A small angular dead band avoids flickering at the four diagonal boundaries.
	if next != facing and VECTORS[next].dot(aim) > VECTORS[facing].dot(aim)+0.12:
		var age: float = puppets[facing].age
		puppets[facing].selected = false
		puppets[facing].mesh.visible = false
		puppets[facing].animator.active = false
		facing = next
		puppets[facing].age = age
		puppets[facing].selected = enabled
		puppets[facing].mesh.visible = enabled
		puppets[facing].animator.active = enabled
		facing_changed.emit(puppets[facing].animator)
	if not seen.has(facing): seen.append(facing)

func select(value: bool) -> void:
	enabled = value
	puppets[facing].select(value)
	puppets[facing].animator.active = value

func _process(_delta: float) -> void:
	if enabled and not get_tree().paused: update_facing()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_V:
		select(not enabled)
