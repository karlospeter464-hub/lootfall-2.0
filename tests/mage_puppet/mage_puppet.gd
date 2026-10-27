extends Node2D

const SOURCE = preload("res://assets/art/characters/apprentice/apprentice_v01.png")
var anchors = [Vector2(99,164), Vector2(169,188), Vector2(128,105)]
var arm_region = PackedVector2Array([Vector2(0,35),Vector2(58,35),Vector2(76,89),Vector2(76,143),Vector2(101,150),Vector2(109,169),Vector2(86,207),Vector2(101,288),Vector2(73,300),Vector2(46,226),Vector2(0,180)])
var art_texture: Texture2D = SOURCE
var articulation_gain: float = 1.0
var player: CharacterBody2D
var selected: bool = true
var mesh := Polygon2D.new()
var animator := AnimationPlayer.new()
var joints: Array[Node2D] = []
var points := PackedVector2Array()
var weights: Array[Vector3] = []
var transparent: ImageTexture
var age: float = 10
var move_seen: bool = false
var cast_seen: bool = false

func setup(actor: CharacterBody2D) -> void:
	player = actor
	position = player.artwork.offset
	var image := Image.create(1,1,false,Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	transparent = ImageTexture.create_from_image(image)
	for index in 3:
		var joint := Node2D.new()
		joint.name = ["ScepterArm","BookHand","HatTip"][index]
		joint.position = anchors[index]
		add_child(joint)
		joints.append(joint)
	var triangles: Array[PackedInt32Array] = []
	for y in 41:
		for x in 33:
			var point := Vector2(x*8,y*8)
			points.append(point)
			var weight: Vector3 = joint_weights(point)
			weights.append(weight / maxf(1,weight.x+weight.y+weight.z))
			if x < 32 and y < 40:
				var i: int = y*33+x
				triangles.append(PackedInt32Array([i,i+1,i+34]))
				triangles.append(PackedInt32Array([i,i+34,i+33]))
	# Feather joint weights across cells so sleeve transitions cannot fold the image mesh.
	for pass_index in 3:
		var softened: Array[Vector3] = []
		for y in 41:
			for x in 33:
				var sum := Vector3.ZERO
				for dy in range(-1,2):
					for dx in range(-1,2): sum += weights[clampi(y+dy,0,40)*33+clampi(x+dx,0,32)]
				softened.append(sum/9.0)
		weights = softened
	for index in points.size():
		weights[index] = lock_torso(points[index],weights[index])
	mesh.polygon = points
	mesh.uv = points
	mesh.polygons = triangles
	mesh.texture = art_texture
	mesh.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(mesh)
	add_child(animator)
	animator.root_node = NodePath("..")
	var library := AnimationLibrary.new()
	library.add_animation("idle", animation(2.6,true,[Vector3.ZERO,Vector3(0.025,-0.018,0.018),Vector3.ZERO]))
	library.add_animation("move", animation(0.42,true,[Vector3(-0.045,0.035,-0.02),Vector3(0.045,-0.035,0.02),Vector3(-0.045,0.035,-0.02)]))
	library.add_animation("cast", animation(0.32,false,[Vector3.ZERO,Vector3(-0.18,0.12,-0.035),Vector3(0.07,-0.04,0.02),Vector3.ZERO]))
	animator.add_animation_library("",library)
	player.cast.connect(on_cast)
	select(true)

func animation(duration: float, looping: bool, poses: Array) -> Animation:
	var result := Animation.new()
	result.length = duration
	result.loop_mode = Animation.LOOP_LINEAR if looping else Animation.LOOP_NONE
	for joint in 3:
		var track: int = result.add_track(Animation.TYPE_VALUE)
		result.track_set_path(track,NodePath(str(joints[joint].name)+":rotation"))
		for key in poses.size(): result.track_insert_key(track,duration*key/float(poses.size()-1),poses[key][joint]*articulation_gain)
	return result

func select(value: bool) -> void:
	selected = value
	var visual = player.visuals
	visual.set_mode(1 if value else 2)
	visual.set_process(not value)
	visual.animator.active = not value
	visual.motion.transform = Transform2D.IDENTITY
	player.artwork.texture = transparent if value else SOURCE
	mesh.visible = value
	animator.stop()
	for joint in joints: joint.rotation = 0
	age = 10
	update_skin()
	if value: animator.play("idle")

func on_cast(_origin: Vector2, _direction: Vector2, _damage: float) -> void:
	if not selected or not player.main_shot: return
	age = 0
	animator.stop()
	animator.play("cast")
	animator.advance(0)

func _process(delta: float) -> void:
	if not selected or get_tree().paused: return
	age += delta
	var state: String = "cast" if age < 0.32 else ("move" if player.velocity.length_squared() > 1 else "idle")
	if animator.current_animation != state: animator.play(state)
	move_seen = move_seen or state == "move"
	cast_seen = cast_seen or state == "cast"
	mesh.self_modulate = player.artwork.self_modulate
	update_skin()

func update_skin() -> void:
	var deformed := points.duplicate()
	for index in points.size():
		for joint in 3:
			deformed[index] += (joints[joint].transform * (points[index]-anchors[joint])-points[index]) * weights[index][joint]
	mesh.polygon = deformed

func pose(angles: Vector3) -> void:
	animator.stop()
	for joint in 3: joints[joint].rotation = angles[joint]
	update_skin()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_V:
		select(not selected)

func joint_weights(point: Vector2) -> Vector3:
	var arm: float = smoothstep(0,25,point.distance_to(anchors[0])) if Geometry2D.is_point_in_polygon(point,arm_region) else 0.0
	var book: float = smoothstep(155,188,point.x) * smoothstep(148,174,point.y) * (1.0-smoothstep(207,234,point.y))
	var hat: float = smoothstep(66,98,point.x) * (1.0-smoothstep(62,105,point.y))
	return Vector3(arm,book,hat)

func lock_torso(point: Vector2, weight: Vector3) -> Vector3:
	weight.x *= 1.0-smoothstep(100,128,point.x)
	weight.y *= smoothstep(142,166,point.x)
	return weight
