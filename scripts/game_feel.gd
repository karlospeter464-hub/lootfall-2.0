extends Node2D

const ORB_CAP: int = 48
var game
var orbs: Array[Dictionary] = []
var sparks: Array[Dictionary] = []
var vacuuming: bool = false
var redraw_clock: float = 0
var clock: float = 0
var retry: float = 0
var celebration: float = 0
var growth_pulse: float = 0
var pickup_flash: float = 0
var save_pending: bool = false
var card_confirm: float = 0
var chosen_title: String = ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func add_orb(at: Vector2, amount: int) -> void:
	if amount <= 0: return
	if orbs.size() >= ORB_CAP:
		var nearest: int = 0
		for index in orbs.size():
			if orbs[index].at.distance_squared_to(at) < orbs[nearest].at.distance_squared_to(at): nearest = index
		orbs[nearest].value += amount
	else:
		orbs.append({"at": at, "value": amount, "speed": 70.0, "age": 0.0, "moving": false})
	queue_redraw()

func confirm_card(index: int) -> void:
	card_confirm = 1.4
	chosen_title = game.UPGRADE_TITLES[index]

func vacuum() -> void:
	vacuuming = not orbs.is_empty()
	if vacuuming: game.sfx.cue("vacuum")

func reset() -> void:
	orbs.clear()
	sparks.clear()
	vacuuming = false
	save_pending = false

func grow(completed: bool) -> void:
	growth_pulse = 2.4
	if completed: celebration = 4.0
	game.sfx.cue("restored" if completed else "growth")

func _process(delta: float) -> void:
	clock += delta
	card_confirm = maxf(0, card_confirm - delta)
	celebration = maxf(0, celebration - delta)
	growth_pulse = maxf(0, growth_pulse - delta)
	pickup_flash = maxf(0, pickup_flash - delta * 3)
	redraw_clock += delta
	if redraw_clock >= 1.0 / 30:
		redraw_clock = 0
		game.queue_redraw()
		if is_instance_valid(game.town_panel): game.town_panel.animate_world(clock)
	if get_tree().paused and not vacuuming and not save_pending:
		queue_redraw()
		return
	retry = maxf(0, retry - delta)
	if retry == 0 and game.owed_echo_total > game.echo_earned():
		game.secure_echo_total(game.owed_echo_total, game.player.position)
	var arrived: Array[Dictionary] = []
	var amount: int = 0
	for orb in orbs:
		orb.age += delta
		var distance: float = orb.at.distance_to(game.player.position)
		orb.moving = orb.moving or vacuuming or distance < 145
		if orb.moving:
			orb.speed = minf(1400 if vacuuming else 850, orb.speed + delta * (2600 if vacuuming else 1350))
			orb.at = orb.at.move_toward(game.player.position, orb.speed * delta)
			if distance < 19:
				arrived.append(orb)
				amount += int(orb.value)
	if amount > 0 and retry == 0:
		if game.progress.claim_echoes(game.echo_paid() + amount, game.run_id):
			for orb in arrived: orbs.erase(orb)
			pickup_flash = 1
			save_pending = false
			game.sfx.cue("orb", 1 + minf(float(amount) / 100, 0.35))
			for index in 5:
				sparks.append({"at": game.player.position, "life": 0.4, "direction": Vector2.from_angle(index * TAU / 5)})
			game.update_hud()
		else:
			save_pending = true
			retry = 1.0
	for spark in sparks: spark.life -= delta
	sparks = sparks.filter(func(spark): return spark.life > 0)
	if sparks.size() > 60: sparks = sparks.slice(sparks.size() - 60)
	if orbs.is_empty(): vacuuming = false
	queue_redraw()

func _draw() -> void:
	for orb in orbs:
		var at: Vector2 = orb.at + Vector2(0, sin(clock * 3 + orb.age) * 3)
		var radius: float = 4.0 + minf(sqrt(float(orb.value)), 4)
		draw_circle(at + Vector2(0, 5), radius * 1.4, Color(0.04, 0.06, 0.09, 0.3))
		draw_circle(at, radius * 2.3, Color(0.85, 0.65, 0.24, 0.10))
		draw_colored_polygon(PackedVector2Array([at + Vector2(0, -radius), at + Vector2(radius * 0.65, 0), at + Vector2(0, radius), at - Vector2(radius * 0.65, 0)]), Color("f2c876"))
		draw_line(at + Vector2(-2, 0), at + Vector2(0, -radius + 2), Color("fff1c8"), 2, true)
		if orb.moving: draw_line(at, at.move_toward(game.player.position, -16), Color(0.95, 0.76, 0.4, 0.4), 2, true)
	for spark in sparks:
		var travel: float = (0.4 - float(spark.life)) * 85
		draw_circle(spark.at + spark.direction * travel, 2, Color(1, 0.86, 0.54, spark.life * 2))
	if pickup_flash > 0:
		draw_arc(game.player.position, 21 + (1 - pickup_flash) * 12, 0, TAU, 24, Color(0.95, 0.78, 0.4, pickup_flash * 0.65), 2, true)
	if growth_pulse > 0:
		for index in 14:
			var at := Vector2(130 + game.WORLD_ART.noise(index * 11) * 1000, 190 + game.WORLD_ART.noise(index * 17) * 460)
			at.y -= (2.4 - growth_pulse) * 16
			draw_line(at, at + Vector2(2, -5), Color(0.6, 0.9, 0.65, growth_pulse * 0.2), 2, true)
	if card_confirm > 0:
		draw_string(ThemeDB.fallback_font, Vector2(430, 158), chosen_title + " — AWAKENED", HORIZONTAL_ALIGNMENT_LEFT, -1, 23, Color(0.95, 0.82, 0.63, minf(1, card_confirm)))
	if celebration > 0:
		var alpha: float = minf(1, minf((4 - celebration) * 3, celebration))
		var banner := Rect2(390, 111, 500, 68)
		draw_rect(banner, Color(0.05, 0.14, 0.12, alpha * 0.92))
		draw_rect(banner, Color(0.56, 0.8, 0.58, alpha), false, 2)
		draw_string(ThemeDB.fallback_font, Vector2(510, 140), "LIFE RETURNS", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color(0.86, 1, 0.84, alpha))
		draw_string(ThemeDB.fallback_font, Vector2(448, 166), game.WORLD.REGIONS[game.run_region].mood, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(0.75, 0.87, 0.72, alpha))
