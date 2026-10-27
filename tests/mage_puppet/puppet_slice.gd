extends "res://tests/visual_depth/depth_slice.gd"

const PUPPET = preload("res://tests/mage_puppet/mage_puppet.gd")
var puppet

func setup_character(player: CharacterBody2D) -> void:
	check(FileAccess.get_sha256("res://assets/art/characters/apprentice/apprentice_v01.png") == "831023c026176d2949e3e8a085148ea1cb79d72d1684a0b7977fbbead3053128","Original v01 PNG is byte-identical")
	puppet = PUPPET.new()
	player.artwork.add_child(puppet)
	puppet.setup(player)
	motion_animator = puppet.animator
	player.visuals.set_process_unhandled_key_input(false)
	check(puppet.points.size() == 1353 and puppet.mesh.polygons.size() == 2560,"Continuous textured mesh covers original image")
	puppet.pose(Vector3(-0.18,0.12,-0.035))
	var torso: int = 25*33+16
	var foot: int = 38*33+16
	check(puppet.mesh.polygon[torso].is_equal_approx(puppet.points[torso]) and puppet.mesh.polygon[foot].is_equal_approx(puppet.points[foot]),"Torso and foot vertices stay fixed while joints move")
	check(not puppet.mesh.polygon[15*33+6].is_equal_approx(puppet.points[15*33+6]),"Staff/flame vertices move independently")
	check(not puppet.mesh.polygon[23*33+25].is_equal_approx(puppet.points[23*33+25]),"Book vertices move independently")
	check(not puppet.mesh.polygon[5*33+16].is_equal_approx(puppet.points[5*33+16]),"Hat-tip vertices move independently")
	var minimum_area: float = INF
	for triangle in puppet.mesh.polygons:
		var a: Vector2 = puppet.mesh.polygon[triangle[0]]
		var b: Vector2 = puppet.mesh.polygon[triangle[1]]
		var c: Vector2 = puppet.mesh.polygon[triangle[2]]
		minimum_area = minf(minimum_area,(b-a).cross(c-a))
	check(minimum_area > 0,"Extreme cast pose has no inverted mesh triangles")
	puppet.pose(Vector3.ZERO)
	check(puppet.mesh.polygon == puppet.points,"Neutral pose reconstructs original mesh without cuts or missing body pixels")
	var key := InputEventKey.new()
	key.keycode=KEY_V
	key.pressed=true
	puppet._unhandled_key_input(key)
	check(not puppet.selected and player.artwork.texture == puppet.SOURCE and player.visuals.mode == 2,"V restores untouched original v01/A+")
	puppet._unhandled_key_input(key)
	check(puppet.selected and puppet.mesh.visible and not player.visuals.animator.active,"V selects articulated mesh, body animation stops")

func pair(game) -> void:
	paused = true
	var state: String = snapshot(game)
	puppet.select(false)
	await capture("before")
	puppet.select(true)
	puppet.pose(Vector3(-0.18,0.12,-0.035))
	await capture("after")
	check(snapshot(game) == state,"Part articulation does not alter gameplay/camera state")
	pair_verified = snapshot(game) == state
	var parent: Node = puppet.get_parent()
	var original_position: Vector2 = puppet.position
	var viewport := SubViewport.new()
	viewport.size = Vector2i(256,320)
	viewport.transparent_bg=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	puppet.reparent(viewport,false)
	puppet.position=Vector2.ZERO
	puppet.pose(Vector3.ZERO)
	await process_frame
	await RenderingServer.frame_post_draw
	check(viewport.get_texture().get_image().save_png(output+"/rig_neutral.png") == OK,"Save original-image neutral rig")
	puppet.mesh.visible=false
	var reference := Sprite2D.new()
	reference.texture=puppet.SOURCE
	reference.centered=false
	reference.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	viewport.add_child(reference)
	await process_frame
	await RenderingServer.frame_post_draw
	check(viewport.get_texture().get_image().save_png(output+"/reference_render.png") == OK,"Save same-GPU original reference")
	reference.visible=false
	reference.queue_free()
	puppet.mesh.visible=true
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output+"/rig_frames"))
	for frame in 36:
		var phase: float = float(frame%12)/11.0
		var pulse: float = sin(phase*PI)
		puppet.pose(Vector3(-0.18,0.12,-0.035)*pulse)
		await process_frame
		await RenderingServer.frame_post_draw
		check(viewport.get_texture().get_image().save_png(output+"/rig_frames/%03d.png" % frame) == OK,"Save actual articulated-mesh preview frame")
	puppet.reparent(parent,false)
	puppet.position=original_position
	viewport.queue_free()
	puppet.pose(Vector3.ZERO)
	puppet.animator.play("idle")
	paused=false
