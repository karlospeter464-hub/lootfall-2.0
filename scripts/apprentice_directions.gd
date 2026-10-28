extends Node2D

signal facing_changed(animator: AnimationPlayer)

const PUPPET = preload("res://scripts/apprentice_direction_puppet.gd")
const LABELS = ["front","right","back","left"]
const VECTORS = [Vector2.DOWN,Vector2.RIGHT,Vector2.UP,Vector2.LEFT]
const TEXTURES = [
	preload("res://assets/art/characters/apprentice/apprentice_v01.png"),
	preload("res://assets/art/characters/apprentice/directions/right.png"),
	preload("res://assets/art/characters/apprentice/directions/back.png"),
	preload("res://assets/art/characters/apprentice/directions/left.png")
]
var player: CharacterBody2D
var puppets: Array[Node2D] = []
var facing: int = 0
var enabled: bool = true
var seen: Array[int] = []

func setup(actor: CharacterBody2D) -> void:
	var wants_artwork: bool = actor.use_artwork
	player = actor
	player.visuals.set_process_unhandled_key_input(false)
	for direction in 4:
		var texture: Texture2D = TEXTURES[direction]
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
	player.health_changed.connect(on_health_changed)
	if not wants_artwork:
		select(false)
		player.visuals.set_mode(0)
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

func on_health_changed(_health: float, _maximum: float) -> void:
	if player.visual_clock != 0 or player.cooldown != 0 or player.cast_flash != 0: return
	for puppet in puppets:
		puppet.age = 10
		puppet.pose(Vector3.ZERO)
	if enabled: puppets[facing].animator.play("idle")
