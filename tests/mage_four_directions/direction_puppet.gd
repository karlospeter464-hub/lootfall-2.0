extends "res://tests/mage_puppet/mage_puppet.gd"

# 0 front/down, 1 right, 2 back/up, 3 left. Three real additional images, never mirrored.
var facing: int = 0

func configure(direction: int, texture: Texture2D) -> void:
	facing = direction
	art_texture = texture
	if facing == 0: return
	articulation_gain = 0.55
	if facing == 2:
		anchors = [Vector2(157,171),Vector2(102,184),Vector2(128,106)]
		arm_region = PackedVector2Array([Vector2(180,55),Vector2(256,55),Vector2(256,299),Vector2(175,291),Vector2(170,224),Vector2(153,202),Vector2(153,172),Vector2(180,145)])
	else:
		anchors = [Vector2(123,180),Vector2(165,205),Vector2(131,114)] if facing == 1 else [Vector2(111,170),Vector2(150,198),Vector2(151,113)]
		arm_region = PackedVector2Array([Vector2(0,40),Vector2(100,40),Vector2(108,145),Vector2(127,169),Vector2(112,235),Vector2(126,296),Vector2(78,310),Vector2(45,245),Vector2(0,200)])

func joint_weights(point: Vector2) -> Vector3:
	if facing == 0: return super.joint_weights(point)
	var arm: float = smoothstep(0,25,point.distance_to(anchors[0])) if Geometry2D.is_point_in_polygon(point,arm_region) else 0.0
	var book: float = (1.0-smoothstep(83,116,point.x)) if facing == 2 else smoothstep(136 if facing == 3 else 154,164 if facing == 3 else 183,point.x)
	book *= smoothstep(150,177,point.y) * (1.0-smoothstep(216,245,point.y))
	var hat: float = smoothstep(66,98,point.x) * (1.0-smoothstep(70,114,point.y))
	return Vector3(arm,book,hat)

func lock_torso(point: Vector2, weight: Vector3) -> Vector3:
	if facing == 0: return super.lock_torso(point,weight)
	weight.x *= smoothstep(128,157,point.x) if facing == 2 else 1.0-smoothstep(110,128,point.x)
	weight.y *= 1.0-smoothstep(100,128,point.x) if facing == 2 else smoothstep(142,166,point.x)
	return weight
