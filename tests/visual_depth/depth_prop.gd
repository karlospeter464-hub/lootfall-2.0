extends Node2D

# Test-only painter: one ground pass, one ruined pillar, one natural boulder.
enum Kind { GROUND, RUIN, ROCK }
var kind: Kind = Kind.GROUND
var player: CharacterBody2D
var atmosphere: GradientTexture2D

func _process(_delta: float) -> void:
	if kind == Kind.GROUND: return
	z_index = 3 if player.global_position.y < global_position.y else 1
	# shortcut: only Player occludes; enemies/telegraphs remain above props until visual approval.

func shape(points: Array, color: String) -> void:
	draw_colored_polygon(PackedVector2Array(points), Color(color))

func shadow(at: Vector2, span: Vector2) -> void:
	for ring in range(5, 0, -1):
		draw_set_transform(at + Vector2(ring * 3, ring * 1.8), 0, span * (0.7 + ring * 0.1))
		draw_circle(Vector2.ZERO, 1, Color(0.035, 0.04, 0.07, 0.065), true, -1, true)
	draw_set_transform(at, 0, span * Vector2(0.67, 0.46))
	draw_circle(Vector2.ZERO, 1, Color(0.025, 0.03, 0.05, 0.4), true, -1, true)
	draw_set_transform(Vector2.ZERO)

func _draw() -> void:
	match kind:
		Kind.GROUND:
			var gradient := Gradient.new()
			gradient.colors = PackedColorArray([Color(0.36, 0.45, 0.63, 0.14), Color(0.2, 0.28, 0.45, 0)])
			atmosphere = GradientTexture2D.new()
			atmosphere.gradient = gradient
			atmosphere.fill = GradientTexture2D.FILL_RADIAL
			atmosphere.fill_from = Vector2(0.25, 0.12)
			atmosphere.fill_to = Vector2(0.95, 0.9)
			draw_texture_rect(atmosphere, Rect2(64, 128, 1152, 592), false)
			shadow(Vector2(491, 412), Vector2(77, 22))
			shadow(Vector2(764, 492), Vector2(99, 25))
		Kind.RUIN: ruin()
		Kind.ROCK: rock()

func ruin() -> void:
	# One consistent upper-left light; chipped cap, recessed pointed niche and masonry seams.
	shape([Vector2(-54,-6),Vector2(16,13),Vector2(51,-7),Vector2(-15,-24)], "272b36")
	shape([Vector2(-54,-19),Vector2(16,-1),Vector2(51,-20),Vector2(-15,-37)], "62606a")
	shape([Vector2(-54,-19),Vector2(16,-1),Vector2(16,13),Vector2(-54,-6)], "41424f")
	shape([Vector2(16,-1),Vector2(51,-20),Vector2(51,-7),Vector2(16,13)], "303340")
	shape([Vector2(-43,-21),Vector2(11,-7),Vector2(11,-122),Vector2(-2,-119),Vector2(-13,-137),Vector2(-26,-129),Vector2(-43,-143)], "65616c")
	shape([Vector2(11,-7),Vector2(39,-23),Vector2(39,-134),Vector2(25,-142),Vector2(11,-122)], "393c4b")
	shape([Vector2(-43,-143),Vector2(-26,-129),Vector2(-13,-137),Vector2(-2,-119),Vector2(11,-122),Vector2(25,-142),Vector2(12,-151),Vector2(-4,-145),Vector2(-18,-156)], "99929a")
	shape([Vector2(-34,-35),Vector2(-1,-26),Vector2(-1,-81),Vector2(-17,-111),Vector2(-34,-91)], "33323f")
	shape([Vector2(-30,-37),Vector2(-5,-30),Vector2(-5,-80),Vector2(-17,-100),Vector2(-30,-88)], "474452")
	draw_polyline(PackedVector2Array([Vector2(-34,-35),Vector2(-34,-91),Vector2(-17,-111),Vector2(-1,-81)]),Color("b0a0a0"),2,true)
	for y in [-49,-88,-119]:
		draw_line(Vector2(-43,y),Vector2(-35,y+2),Color("393947"),2,true)
		draw_line(Vector2(0,y+11),Vector2(11,y+14),Color("393947"),2,true)
		draw_line(Vector2(12,y+14),Vector2(39,y-2),Color("292e3c"),2,true)
	draw_polyline(PackedVector2Array([Vector2(-27,-128),Vector2(-21,-116),Vector2(-24,-105)]),Color("343442"),1.6,true)
	draw_polyline(PackedVector2Array([Vector2(23,-99),Vector2(19,-87),Vector2(24,-80),Vector2(20,-65)]),Color("232937"),1.7,true)
	draw_line(Vector2(-43,-140),Vector2(-43,-24),Color("a29495"),2,true)
	shape([Vector2(-49,-17),Vector2(-36,-20),Vector2(-24,-13),Vector2(-32,-8)], "626655")
	shape([Vector2(24,-6),Vector2(39,-13),Vector2(42,-7),Vector2(31,-1)], "4c574c")

func rock() -> void:
	shape([Vector2(-78,-7),Vector2(-62,-47),Vector2(-30,-70),Vector2(7,-84),Vector2(48,-60),Vector2(69,-21),Vector2(48,5),Vector2(2,16),Vector2(-45,9)], "272c38")
	shape([Vector2(-76,-9),Vector2(-60,-46),Vector2(-29,-68),Vector2(-12,-31),Vector2(-36,2)], "666671")
	shape([Vector2(-29,-68),Vector2(7,-82),Vector2(47,-59),Vector2(28,-28),Vector2(-12,-31)], "83808a")
	shape([Vector2(28,-28),Vector2(47,-59),Vector2(67,-21),Vector2(46,3),Vector2(10,11)], "3c414f")
	shape([Vector2(-12,-31),Vector2(28,-28),Vector2(10,11),Vector2(-36,2)], "515563")
	draw_polyline(PackedVector2Array([Vector2(-62,-45),Vector2(-29,-68),Vector2(6,-82),Vector2(46,-59)]),Color("a19aa1"),2,true)
	draw_polyline(PackedVector2Array([Vector2(6,-65),Vector2(-2,-51),Vector2(4,-42),Vector2(-3,-30)]),Color("474956"),1.7,true)
	draw_line(Vector2(39,-20),Vector2(30,-7),Color("292f3c"),2,true)
	shape([Vector2(-62,3),Vector2(-38,-2),Vector2(-17,6),Vector2(-31,11)], "48554d")
	shape([Vector2(41,8),Vector2(55,0),Vector2(64,5),Vector2(55,12)], "4b505a")
