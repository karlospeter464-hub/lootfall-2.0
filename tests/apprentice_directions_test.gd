extends "res://tests/mage_four_directions/direction_slice.gd"

func create_arena():
	return load("res://scenes/arena.tscn").instantiate()

func character_visual(player):
	return player.directions

func setup_character(player: CharacterBody2D) -> void:
	check(player.directions.enabled,"Four-direction mage enabled by normal player scene")
	check(FileAccess.get_sha256("res://assets/art/characters/apprentice/directions/source/back_approved_v2.png") == "528b6ea7f47c38a6c7ef41e14810955eacb149d4528551c2d3e833ff1a9c1537","Approved V2 rear image preserved exactly")
	for texture in player.directions.TEXTURES:
		check(texture is CompressedTexture2D,"Direction uses an imported exportable texture")
	depth.visible = false
	super.setup_character(player)
	player.cast.emit(Vector2.ZERO,Vector2.UP,14)
	player.reset_run()
	check(player.directions.puppets.all(func(puppet): return puppet.age == 10),"Run reset clears all directional cast poses")
	var fallback = load("res://scenes/player.tscn").instantiate()
	fallback.use_artwork = false
	root.add_child(fallback)
	check(not fallback.directions.enabled and fallback.visuals.mode == 0 and not fallback.artwork.visible,"Use Artwork=false retains procedural player")
	fallback.queue_free()
