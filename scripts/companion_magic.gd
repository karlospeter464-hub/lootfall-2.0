extends Node2D

const CATALOG = preload("res://scripts/companion_catalog.gd")
var game
var slots: Array = ["", ""]
var talents: Dictionary = {}
var cooldowns: Array[float] = [0.0, 0.0]
var field: Dictionary = {}
var beam: Dictionary = {}
var rays: Array = []
var clock: float = 0.0
var ash_charge: float = 0.0
var rescue: String = ""
var hud: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	z_index = 4

func reset() -> void:
	slots = game.progress.companions.slots.duplicate() if game.progress.companions.enabled else ["", ""]
	talents = CATALOG.snapshot(game.progress.companions)
	cooldowns = [0.0, 0.0]
	field.clear()
	beam.clear()
	rays.clear()
	ash_charge = 0
	rescue = ""
	clock = 0

func has(id: String) -> bool:
	return talents.has(id)

func cast(slot: int, at: Vector2) -> bool:
	if slot not in [0, 1] or game.get_tree().paused or game.state != game.State.FIGHTING or game.player.health <= 0 or cooldowns[slot] > 0: return false
	var id: String = slots[slot]
	var stats: Dictionary = ability_stats(id)
	if id == "gravity":
		if not field.is_empty(): return false
		var target: Vector2 = game.player.position + (at - game.player.position).limit_length(480)
		field = {"at": target.clamp(game.BOUNDS.position + Vector2.ONE * 24, game.BOUNDS.end - Vector2.ONE * 24), "left": stats.duration, "radius": stats.radius, "kills": 0, "damage": stats.damage}
		cooldowns[slot] = stats.cooldown
		game.sfx.cue("gravity")
	elif id == "prism":
		if not beam.is_empty(): return false
		var direction: Vector2 = game.player.position.direction_to(at)
		if direction.is_zero_approx(): direction = game.player.aim
		beam = {"at": game.player.position, "direction": direction, "left": stats.charge, "fired": false, "width": stats.width, "damage": stats.damage}
		ash_charge = 0
		cooldowns[slot] = stats.cooldown
		game.sfx.cue("charge")
	else: return false
	game.player.cast_flash = 0.16
	refresh_hud()
	return true

func base_damage() -> float:
	return game.player.base_damage * (1.0 + CATALOG.bonuses(talents).damage)

func inside(at: Vector2) -> bool:
	return not field.is_empty() and at.distance_squared_to(field.at) <= field.radius * field.radius

func fireball_damage(target: Object, amount: float) -> float:
	if has("gravity.slow"): target.companion_slow = 1.5
	if has("prism.mark"): target.set_meta("prism_until", clock + 4)
	return amount * (1.25 if has("gravity.captured") and inside(target.position) else 1.0)

func fireball_hit(target: Object) -> void:
	if is_instance_valid(target) and target.dead and has("prism.kindle"):
		if not beam.is_empty() and not beam.fired:
			beam.left = maxf(0.15, beam.left - 0.1)
		else:
			ash_charge = minf(0.3, ash_charge + 0.1)

func slain(at: Vector2) -> void:
	if inside(at): field.kills = mini(10, int(field.kills) + 1)

func _physics_process(delta: float) -> void:
	clock += delta
	if game.state not in [game.State.FIGHTING, game.State.BETWEEN_WAVES]:
		if game.state in [game.State.FINISHED, game.State.TOWN]: clear_combat()
		refresh_hud()
		return
	for i in 2: cooldowns[i] = maxf(0, cooldowns[i] - delta)
	for enemy in game.enemies.get_children(): enemy.gravity_pull = Vector2.ZERO
	if game.state == game.State.FIGHTING:
		# The first rescue is a shared fight: the friend weakly gathers nearby pursuers.
		if rescue != "" and CATALOG.FRIENDS[rescue].rescue == "shared_battle":
			for enemy in game.enemies.get_children():
				if not enemy.dead and enemy.position.distance_to(Vector2(640, 300)) < 160:
					enemy.gravity_pull = enemy.position.direction_to(Vector2(640, 300)) * 100
		if not field.is_empty():
			for enemy in game.enemies.get_children():
				if not enemy.dead and not enemy.frozen and inside(enemy.position):
					enemy.gravity_pull = enemy.position.direction_to(field.at) * minf(330, enemy.position.distance_to(field.at) * 5) * (0.3 if not enemy.boss_name.is_empty() else 1.0)
			field.left -= delta
			if field.left <= 0: collapse()
		if not beam.is_empty():
			beam.left -= delta
			if beam.left <= 0:
				if not beam.fired: fire_beam()
				else: beam.clear(); rays.clear()
	for enemy in game.enemies.get_children():
		if enemy.get_meta("prism_until", 0.0) > clock:
			enemy.queue_redraw()
	refresh_hud()
	queue_redraw()

func clear_combat() -> void:
	field.clear()
	beam.clear()
	rays.clear()
	for enemy in game.enemies.get_children(): enemy.gravity_pull = Vector2.ZERO
	queue_redraw()

func collapse() -> void:
	var ended: Dictionary = field.duplicate()
	field.clear() # Kills caused by collapse cannot amplify the same explosion.
	if has("gravity.collapse"):
		game.area_damage(ended.at, ended.damage * (1.0 + ended.kills * 0.15 if has("gravity.harvest") else 1.0), ended.radius, null)
		game.sfx.cue("collapse")

func targets_on_ray(from: Vector2, direction: Vector2, length: float, width: float, excluded: Array = []) -> Array:
	var hits := []
	for enemy in game.enemies.get_children():
		if enemy.dead or enemy in excluded: continue
		var along: float = (enemy.position - from).dot(direction)
		if along < 0 or along > length: continue
		var nearest: Vector2 = from + direction * along
		if nearest.distance_to(enemy.position) <= width / 2 + 16 * enemy.scale.x: hits.append(enemy)
	hits.sort_custom(func(a, b): return from.distance_squared_to(a.position) < from.distance_squared_to(b.position))
	return hits

func fire_beam() -> void:
	beam.fired = true
	beam.left = 0.28
	var hits: Array = targets_on_ray(beam.at, beam.direction, 1100, beam.width)
	rays = [{"from": beam.at, "to": beam.at + beam.direction * 1100, "width": beam.width}]
	var split_at: Vector2 = hits[0].position if not hits.is_empty() else Vector2.ZERO
	for enemy in hits: beam_hit(enemy, beam.damage)
	if has("prism.split") and not hits.is_empty():
		var split_hits: Array = hits.duplicate()
		for angle in [-0.38, 0.38]:
			var direction: Vector2 = beam.direction.rotated(angle)
			rays.append({"from": split_at, "to": split_at + direction * 340, "width": beam.width * 0.6})
			for enemy in targets_on_ray(split_at, direction, 340, beam.width * 0.6, split_hits):
				split_hits.append(enemy)
				beam_hit(enemy, beam.damage * 0.5)
	game.sfx.cue("beam")

func beam_hit(enemy: Object, amount: float) -> void:
	var marked: bool = enemy.get_meta("prism_until", 0.0) > clock
	enemy.take_damage(amount * (1.4 if has("prism.marked") and marked else 1.0))

func begin_rescue() -> void:
	rescue = ""
	if not game.progress.companions.enabled: return
	for id in CATALOG.SPECIALS:
		if id not in game.progress.companions.rescued and CATALOG.FRIENDS[id].wave == game.wave:
			rescue = id
			game.show_notice("Gravitation: I held them back. Help me break the circle!" if id == "gravity" else "Prisma: Clear this blighted place. Let me see if I can trust you again.")
	queue_redraw()

func offer_rescue() -> bool:
	if rescue.is_empty(): return false
	game.state = game.State.RESCUE
	game.get_tree().paused = true
	game.player.controls_enabled = false
	game.show_overlay("A FRIEND RETURNS — " + CATALOG.FRIENDS[rescue].name, "Gravitation: I tried to hold everything together. This time, I won't stand alone.\nBlack Hole and a personal talent tree await in Emberhaven." if rescue == "gravity" else "Prisma: I chose to leave. Clearing this place won't erase that — but I can help now.\nLight Beam and a personal talent tree await in Emberhaven.")
	game.add_button("Rescue / unlock ability + tree", accept_rescue)
	return true

func accept_rescue() -> void:
	if rescue.is_empty(): return
	if not game.progress.rescue_companion(rescue):
		game.overlay_text.text = "SAVE PENDING — " + game.progress.message + "\nRetry Rescue. Your wave progress is preserved."
		return
	for i in 2:
		if slots[i] == "" and game.progress.companions.slots[i] == rescue: slots[i] = rescue
	game.show_notice(CATALOG.FRIENDS[rescue].name + " rescued! Q/E: aim with mouse. Visit Friends in Emberhaven for talents.")
	game.sfx.cue("restored")
	rescue = ""
	game.get_tree().paused = false
	game.player.controls_enabled = true
	game.overlay.hide()
	game.finish_wave_rewards()

func refresh_hud() -> void:
	if not is_instance_valid(hud): return
	var lines := PackedStringArray()
	for i in 2:
		var id: String = slots[i]
		lines.append(["Q", "E"][i] + "  " + ("Rescue a friend" if id == "" else CATALOG.FRIENDS[id].ability + ("  READY" if cooldowns[i] <= 0 else "  %.1fs" % cooldowns[i])))
	hud.text = "    /    ".join(lines) + "  /  I: ability details"
	hud.mouse_filter = Control.MOUSE_FILTER_PASS
	var descriptions := PackedStringArray()
	for id in slots:
		if id != "": descriptions.append(ability_description(id))
	hud.tooltip_text = "\n\n".join(descriptions)
	if not beam.is_empty() and not beam.fired: hud.text += "  /  CHARGING"

func _draw() -> void:
	if not rescue.is_empty():
		var at := Vector2(640, 300)
		var color := Color(CATALOG.FRIENDS[rescue].color)
		draw_arc(at, 45, clock, clock + TAU * 0.85, 40, color, 3, true)
		draw_colored_polygon(PackedVector2Array([at + Vector2(0, -28), at + Vector2(16, 12), at + Vector2(-16, 12)]), color.darkened(0.35))
		draw_circle(at + Vector2(0, -26), 8, color)
		draw_string(ThemeDB.fallback_font, at + Vector2(-80, 65), CATALOG.FRIENDS[rescue].name + " — clear the wave", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, color)
	if not field.is_empty():
		var at: Vector2 = field.at
		var radius: float = field.radius
		draw_circle(at, radius, Color(0.25, 0.12, 0.45, 0.13))
		draw_arc(at, radius, 0, TAU, 64, Color("b497ff"), 2, true)
		for i in 4:
			var angle: float = clock * 2 + i * TAU / 4
			draw_arc(at, radius * (0.24 + i * 0.16), angle, angle + PI * 1.3, 32, Color(0.7, 0.5, 1, 0.6), 3, true)
		for i in 12:
			var phase: float = fposmod(clock * 0.65 + i / 12.0, 1)
			var direction := Vector2.from_angle(i * TAU / 12 + clock * 0.5)
			draw_line(at + direction * radius * phase, at + direction.rotated(0.09) * radius * minf(1, phase + 0.1), Color("d4c4ff"), 2, true)
		draw_circle(at, 21, Color("100f23"))
		draw_arc(at, 25, -clock * 3, -clock * 3 + TAU * 0.8, 32, Color("eedcff"), 3, true)
	if not beam.is_empty() and not beam.fired:
		draw_line(beam.at, beam.at + beam.direction * 1100, Color(0.6, 0.95, 1, 0.3), beam.width, true)
		draw_line(beam.at, beam.at + beam.direction * 1100, Color("8ce9f7"), 1, true)
	for ray in rays:
		var fade: float = clampf(beam.get("left", 0.0) / 0.28, 0, 1)
		draw_line(ray.from, ray.to, Color(0.5, 0.45, 1, 0.3 * fade), ray.width + 20, true)
		draw_line(ray.from, ray.to, Color(0.4, 0.9, 1, fade * 0.65), ray.width, true)
		draw_line(ray.from, ray.to, Color(1, 1, 1, fade * 0.85), ray.width * 0.16, true)
	for enemy in game.enemies.get_children():
		if not enemy.dead and enemy.get_meta("prism_until", 0.0) > clock:
			draw_arc(enemy.position, 25, 0, TAU, 20, Color("8ce9f7"), 2, true)

func ability_stats(id: String, learned: Variant = null) -> Dictionary:
	var owned: Dictionary = talents if learned == null else learned
	var damage: float = game.player.base_damage * (1.0 + CATALOG.bonuses(owned).damage)
	if id == "gravity":
		return {"damage": damage * 3 if owned.has("gravity.collapse") else 0.0, "cooldown": 9.0, "radius": 200.0 if owned.has("gravity.radius") else 150.0, "duration": 5.0 if owned.has("gravity.duration") else 3.5}
	if id == "prism":
		return {"damage": damage * 4, "cooldown": 7.0, "width": 54.0 if owned.has("prism.width") else 30.0, "charge": maxf(0.15, (0.3 if owned.has("prism.charge") else 0.65) - (ash_charge if learned == null else 0.0))}
	return {}

func ability_description(id: String, learned: Variant = null) -> String:
	var owned: Dictionary = talents if learned == null else learned
	var stats: Dictionary = ability_stats(id, learned)
	if stats.is_empty(): return "Empty ability slot."
	var text: String = CATALOG.FRIENDS[id].name + " — " + CATALOG.FRIENDS[id].ability
	if id == "gravity":
		text += "\nPulls enemies toward the aimed point for %.1f s. Radius %.0f; cooldown %.0f s." % [stats.duration, stats.radius, stats.cooldown]
		text += "\nCollapse: %.1f damage per target." % stats.damage if owned.has("gravity.collapse") else "\nDamage: 0 — crowd control. Learn Gravitational Collapse to add an explosion."
		if owned.has("gravity.harvest") and owned.has("gravity.collapse"): text += " Kills in the field add 15%% each, up to %.1f damage (+150%%)." % (stats.damage * 2.5)
	else:
		text += "\n%.1f damage per target. Pierces every enemy in the aimed line.\nCharge %.2f s; width %.0f; cooldown %.0f s. Aim locks when E/Q is pressed." % [stats.damage, stats.charge, stats.width, stats.cooldown]
		if owned.has("prism.marked"): text += "\nMarked targets: %.1f damage (requires a fireball mark)." % (stats.damage * 1.4)
		if owned.has("prism.split"): text += "\nTwo short split rays: %.1f damage each; no repeated main-ray hits." % (stats.damage * 0.5)
	if id == "gravity":
		if owned.has("gravity.slow"): text += "\nFireball hits: slow 30% for 1.5 s."
		if owned.has("gravity.captured"): text += " Fireballs in the field: +25% damage."
	else:
		if owned.has("prism.mark"): text += "\nFireballs mark targets for 4 s."
		if owned.has("prism.kindle"): text += " Kills shorten charge by 0.1 s (0.15 s minimum)."
	return text + "\nDamage before enemy armor; companion talents only."
