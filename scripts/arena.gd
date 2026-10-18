extends Node2D

const ENEMY = preload("res://scenes/enemy.tscn")
const RANGED_ENEMY = preload("res://scripts/ranged_enemy.gd")
const GUARDIAN_ENEMY = preload("res://scripts/guardian_enemy.gd")
const PROJECTILE = preload("res://scenes/projectile.tscn")
const PICKUP = preload("res://scripts/loot_pickup.gd")
const PROGRESS = preload("res://scripts/progress_store.gd")
const DEV_CONSOLE = preload("res://scripts/dev_console.gd")
const CATALOG = preload("res://scripts/item_catalog.gd")
const INVENTORY_PANEL = preload("res://scripts/inventory_panel.gd")
const TALENTS = preload("res://scripts/skill_tree.gd")
const TOWN_PANEL = preload("res://scripts/town_panel.gd")
const BOUNDS := Rect2(64, 128, 1152, 592)
const UPGRADE_TITLES := ["Ember Power", "Quick Casting", "Fire Fan"]

enum State { FIGHTING, BETWEEN_WAVES, UPGRADE, PAUSED, FINISHED, TOWN }

@export_range(1, 50, 1) var first_wave_enemies: int = 8
@export_range(0, 20, 1) var enemies_per_wave: int = 4
@export_range(1, 100, 1) var enemy_limit: int = 12
@export_range(0, 6, 1) var ranged_limit: int = 2
@export_range(0.4, 3, 0.1) var ranged_windup: float = 1.4
@export_range(0.5, 6, 0.1) var ranged_interval: float = 2.0
@export_range(20, 100, 1) var ranged_radius: float = 38.0
@export_range(1, 10, 0.5) var seer_health_multiplier: float = 6.0
@export_range(0, 12, 1) var seer_interrupt_hits: int = 5
@export_range(3, 100, 1) var guardian_first_wave: int = 3
@export_range(1, 30, 1) var guardian_every: int = 6
@export_range(0, 2, 1) var guardian_limit: int = 2
@export_range(1, 10, 0.5) var guardian_health_multiplier: float = 6.0
@export_range(0.1, 1, 0.05) var guardian_speed_ratio: float = 0.55
@export_range(0, 50, 1) var guardian_armor: float = 8.0
@export_range(0.05, 1, 0.05) var guardian_minimum_ratio: float = 0.2
@export_range(0.1, 3.0, 0.05) var spawn_interval: float = 0.65
@export_range(100, 600, 10) var safe_spawn_distance: float = 260.0
@export_range(10, 300, 5) var enemy_speed: float = 85.0
@export_range(1, 500, 1) var enemy_health: float = 28.0
@export_range(1, 100, 1) var enemy_damage: float = 14.0
@export_range(0, 50, 1) var enemy_health_growth: float = 3.0
@export_range(0, 30, 1) var enemy_speed_growth: float = 5.0
@export_range(5, 100, 1) var total_waves: int = 6
@export_range(0.1, 10, 0.1) var intermission: float = 1.5
@export_range(0, 1, 0.01) var upgrade_damage_bonus: float = 0.35
@export_range(0, 0.8, 0.01) var upgrade_cast_reduction: float = 0.2
@export_range(1, 3, 1) var upgrade_projectiles: int = 1
@export_range(100, 1500, 25) var projectile_speed: float = 650.0
@export_range(0.1, 5, 0.1) var projectile_lifetime: float = 1.8
@export_range(0, 0.6, 0.01) var projectile_spread: float = 0.19
@export_range(0, 1, 0.005) var drop_chance: float = 0.02
@export_range(10, 100, 1) var pickup_radius: float = 36.0
@export_range(20, 250, 5) var explosion_radius: float = 85.0
@export_range(0, 3, 0.05) var explosion_damage_ratio: float = 0.6
@export_range(0, 1000, 1) var echoes_per_wave: int = 10
@export_range(0, 1, 0.01) var equipment_drop_chance: float = 0.1
@export_range(0, 1, 0.01) var rare_chance: float = 0.25
@export_range(0, 1, 0.01) var magic_chance: float = 0.5
@export_range(1, 64, 1) var ground_loot_limit: int = 16
@export_range(0, 2, 0.05) var scepter_damage_bonus: float = 0.3
@export_range(0, 0.8, 0.05) var scepter_cast_reduction: float = 0.2
@export_range(0, 2, 0.05) var focus_damage_bonus: float = 0.4
@export_range(1, 10000, 1) var tree_cost_1: int = 30
@export_range(1, 10000, 1) var tree_cost_2: int = 45
@export_range(1, 10000, 1) var tree_cost_3: int = 65
@export_range(1, 10000, 1) var tree_cost_4: int = 90
@export_range(1, 10000, 1) var tree_cost_5: int = 130
@export_range(0, 0.5, 0.01) var tree_power_step: float = 0.04
@export_range(0, 1, 0.01) var tree_power_notable: float = 0.08
@export_range(0, 0.5, 0.01) var tree_health_step: float = 0.05
@export_range(0, 1, 0.01) var tree_health_notable: float = 0.1
@export_range(0, 0.15, 0.01) var tree_flow_step: float = 0.03
@export_range(0, 0.15, 0.01) var tree_flow_notable: float = 0.05
@export_range(0, 2, 0.05) var tree_opening_bonus: float = 0.35
@export_range(0, 0.5, 0.01) var tree_wave_heal: float = 0.06
@export_range(0, 0.8, 0.05) var tree_hurt_haste: float = 0.2
@export_range(0.5, 10, 0.5) var tree_haste_duration: float = 3.0

@onready var player = $Player
@onready var enemies: Node2D = $Enemies
@onready var projectiles: Node2D = $Projectiles

var state: State = State.BETWEEN_WAVES
var wave: int = 0
var best_wave: int = 0
var remaining_to_spawn: int = 0
var spawn_clock: float = 0.0
var break_clock: float = 1.2
var kills: int = 0
var upgrades_chosen: int = 0
var effects: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()
var hud: Label
var health_label: Label
var health_bar: ProgressBar
var build_label: Label
var overlay: PanelContainer
var overlay_title: Label
var overlay_text: Label
var buttons: HBoxContainer
var loot: Node2D
var dev_console
var progress = PROGRESS.new()
var completed_waves: int = 0
var codex_active: bool:
	get: return equipment.book == "cinder_codex"
var codex_spawned: bool = false
var bag: Array[String] = ["", "", "", "", "", "", "", ""]
var equipment: Dictionary = {"scepter": "", "book": ""}
var inventory_panel
var town_panel
var active_talents: Dictionary = {}
var last_healed_wave: int = 0
var notice_label: Label
var notice_timer: float = 0.0
var reward_due: int = 0
var reward_saved: bool = false
var result_victory: bool = false
var power_upgrades: int = 0
var quick_upgrades: int = 0
var fan_upgrades: int = 0
var elapsed: float = 0.0
var damage_dealt: float = 0.0
var damage_taken: float = 0.0
var last_health: float = 0.0
var shots_fired: int = 0
var shots_hit: int = 0
var drops_created: int = 0
var enemies_frozen: bool = false
var loot_label: Label
var wallet_label: Label

func _ready() -> void:
	if OS.get_cmdline_user_args().has("--test-mode"):
		progress.path = "user://test_progress_%d.json" % OS.get_process_id()
	progress.load_progress()
	best_wave = progress.best_wave
	rng.randomize()
	player.arena_bounds = BOUNDS
	player.cast.connect(_cast)
	player.health_changed.connect(_health_changed)
	player.defeated.connect(func(): finish_run(false))
	loot = Node2D.new()
	loot.name = "Loot"
	loot.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(loot)
	create_interface()
	inventory_panel = INVENTORY_PANEL.new()
	inventory_panel.game = self
	add_child(inventory_panel)
	town_panel = TOWN_PANEL.new()
	town_panel.game = self
	add_child(town_panel)
	if OS.is_debug_build():
		dev_console = DEV_CONSOLE.new()
		dev_console.game = self
		add_child(dev_console)
	restart_run()
	_show_town()

func _process(delta: float) -> void:
	if get_tree().paused:
		return
	elapsed += delta
	notice_timer = maxf(0.0, notice_timer - delta)
	if notice_timer <= 0:
		notice_label.text = ""
	for effect in effects:
		effect.life -= delta
	effects = effects.filter(func(effect: Dictionary) -> bool: return effect.life > 0.0)
	queue_redraw()
	if state == State.FIGHTING:
		spawn_clock -= delta
		if remaining_to_spawn > 0 and spawn_clock <= 0 and enemies.get_child_count() < enemy_limit:
			spawn_enemy()
			spawn_clock = spawn_interval
		if remaining_to_spawn == 0 and enemies.get_child_count() == 0:
			complete_wave()
	elif state == State.BETWEEN_WAVES:
		break_clock -= delta
		if break_clock <= 0:
			begin_wave()
	update_hud()

func _unhandled_input(event: InputEvent) -> void:
	if is_instance_valid(inventory_panel) and inventory_panel.is_open:
		return
	if is_instance_valid(dev_console) and dev_console.is_open:
		return
	if event.is_action_pressed("pause") and not event.is_echo():
		if state == State.PAUSED:
			resume_run()
		elif state in [State.FIGHTING, State.BETWEEN_WAVES]:
			pause_run()
		get_viewport().set_input_as_handled()

func restart_run() -> void:
	# Do not silently discard a reward whose write failed.
	if state == State.FINISHED and not reward_saved:
		settle_reward()
		if not reward_saved:
			return
	if is_instance_valid(dev_console):
		dev_console.close_console()
	if is_instance_valid(inventory_panel):
		inventory_panel.close_inventory()
	get_tree().paused = false
	for container in [enemies, projectiles, loot]:
		for child in container.get_children():
			container.remove_child(child)
			child.queue_free()
	effects.clear()
	wave = 0
	kills = 0
	upgrades_chosen = 0
	completed_waves = 0
	codex_spawned = false
	bag.fill("")
	equipment = {"scepter": "", "book": ""}
	notice_timer = 0.0
	notice_label.text = ""
	reward_due = 0
	reward_saved = false
	power_upgrades = 0
	quick_upgrades = 0
	fan_upgrades = 0
	elapsed = 0.0
	damage_dealt = 0.0
	damage_taken = 0.0
	shots_fired = 0
	shots_hit = 0
	drops_created = 0
	enemies_frozen = false
	remaining_to_spawn = 0
	spawn_clock = 0.0
	break_clock = 1.2
	state = State.BETWEEN_WAVES
	last_healed_wave = 0
	active_talents = progress.talents.duplicate()
	if is_instance_valid(town_panel):
		town_panel.close_town()
	player.position = BOUNDS.get_center()
	player.reset_run()
	update_build()
	player.health = player.health_limit
	player.health_changed.emit(player.health, player.health_limit)
	player.controls_enabled = true
	overlay.hide()
	update_hud()

func return_to_town() -> bool:
	if state != State.FINISHED or not reward_saved:
		return false
	restart_run()
	_show_town()
	return true

func _show_town() -> void:
	state = State.TOWN
	get_tree().paused = true
	player.controls_enabled = false
	town_panel.open_town()

func talent_cost(id: String) -> int:
	return int(get("tree_cost_%d" % TALENTS.NODES[id].tier)) if TALENTS.NODES.has(id) else 0

func buy_talent(id: String) -> bool:
	return state == State.TOWN and progress.buy(id, talent_cost(id))

func refund_talents() -> bool:
	return state == State.TOWN and progress.refund_all()

func begin_wave() -> void:
	wave += 1
	best_wave = maxi(best_wave, wave)
	remaining_to_spawn = first_wave_enemies + (wave - 1) * enemies_per_wave
	spawn_clock = 0.0
	state = State.FIGHTING

func spawn_enemy(forced_role: String = "") -> void:
	if state != State.FIGHTING or remaining_to_spawn <= 0 or enemies.get_child_count() >= enemy_limit:
		return
	var spawn_at: Vector2 = Vector2.ZERO
	# Opposite corners always provide a safe fallback, even with a large Inspector radius.
	var candidates: Array[Vector2] = []
	for attempt in 12:
		var point := Vector2(rng.randf_range(92, 1188), rng.randf_range(156, 692))
		if attempt % 2 == 0:
			point.x = 92 if rng.randf() < 0.5 else 1188
		else:
			point.y = 156 if rng.randf() < 0.5 else 692
		candidates.append(point)
	for corner in [BOUNDS.position + Vector2(28, 28), BOUNDS.end - Vector2(28, 28), Vector2(92, 692), Vector2(1188, 156)]:
		candidates.append(corner)
	var farthest: float = -1.0
	for candidate in candidates:
		var distance: float = candidate.distance_to(player.position)
		if distance > farthest:
			farthest = distance
			spawn_at = candidate
		if distance >= safe_spawn_distance:
			spawn_at = candidate
			break
	var enemy = ENEMY.instantiate()
	var spawned_this_wave: int = first_wave_enemies + (wave - 1) * enemies_per_wave - remaining_to_spawn
	var ranged_alive: int = 0
	var guardians_alive: int = 0
	for current in enemies.get_children():
		if current.get_script() == RANGED_ENEMY and not current.dead:
			ranged_alive += 1
		if current.get_script() == GUARDIAN_ENEMY and not current.dead:
			guardians_alive += 1
	if wave >= guardian_first_wave and guardians_alive < guardian_limit and (forced_role == "guardian" or (forced_role.is_empty() and spawned_this_wave % guardian_every == guardian_every - 1)):
		enemy.set_script(GUARDIAN_ENEMY)
		enemy.armor = guardian_armor
		enemy.minimum_ratio = guardian_minimum_ratio
		enemy.armor_absorbed.connect(show_blocked)
	elif wave >= 2 and ranged_alive < ranged_limit and (forced_role == "seer" or (forced_role.is_empty() and spawned_this_wave % 4 == 3)):
		enemy.set_script(RANGED_ENEMY)
		enemy.windup = ranged_windup
		enemy.attack_interval = ranged_interval
		enemy.attack_radius = ranged_radius
		enemy.interrupt_hits = seer_interrupt_hits
	enemy.position = spawn_at
	enemy.target = player
	enemy.bounds = BOUNDS
	enemy.max_health = enemy_health + (wave - 1) * enemy_health_growth
	enemy.move_speed = enemy_speed + (wave - 1) * enemy_speed_growth
	if enemy.get_script() == GUARDIAN_ENEMY:
		enemy.max_health *= guardian_health_multiplier
		enemy.move_speed *= guardian_speed_ratio
	elif enemy.get_script() == RANGED_ENEMY:
		enemy.max_health *= seer_health_multiplier
	enemy.contact_damage = enemy_damage
	enemy.frozen = enemies_frozen
	enemy.hit.connect(show_hit)
	enemy.slain.connect(enemy_slain)
	enemies.add_child(enemy)
	remaining_to_spawn -= 1

func start_counterplay_test(build_index: int, role_index: int) -> bool:
	# Isolated saves only: these arrangements deliberately replace the active test run.
	if not OS.is_debug_build() or not OS.get_cmdline_user_args().has("--test-mode") or build_index not in [0, 1, 2] or role_index not in [0, 1, 2]:
		return false
	restart_run()
	if state == State.FINISHED:
		return false
	active_talents.clear()
	rng.seed = 42
	quick_upgrades = 2 if build_index == 0 else 0
	power_upgrades = 2 if build_index == 1 else 0
	fan_upgrades = 2 if build_index == 2 else 0
	upgrades_chosen = 2
	for id in (["swift_scepter"] if build_index == 0 else (["ember_scepter", "focus_grimoire"] if build_index == 1 else ["ember_scepter", "cinder_codex"])):
		accept_item(id)
		equip_item(bag.find(id))
	update_build()
	wave = maxi(3, guardian_first_wave) - 1
	begin_wave()
	player.position = Vector2(440, 420)
	for index in (6 if role_index == 0 else 1):
		var count: int = enemies.get_child_count()
		spawn_enemy(["chaser", "seer", "guardian"][role_index])
		if enemies.get_child_count() > count:
			var enemy = enemies.get_child(count)
			enemy.position = Vector2(660 + (index % 2) * 35, 420 + (index / 2) * 35)
			if enemy.get_script() == RANGED_ENEMY:
				enemy.cooldown = 0
	remaining_to_spawn = 0
	show_notice("CE1 isolated test: %s vs %s. Normal wave flow resumes after this encounter." % [["Rapid", "Heavy", "Area"][build_index], ["Chasers", "Seer", "Guardian"][role_index]])
	return true

func complete_wave() -> void:
	if state != State.FIGHTING:
		return
	completed_waves = maxi(completed_waves, wave)
	if last_healed_wave < wave:
		last_healed_wave = wave
		var perks: Dictionary = TALENTS.bonuses(active_talents, self)
		if perks.healing > 0:
			player.health = minf(player.health_limit, player.health + player.health_limit * perks.healing)
			player.health_changed.emit(player.health, player.health_limit)
	if wave >= total_waves:
		finish_run(true)
	elif wave in [2, 4]:
		state = State.UPGRADE
		get_tree().paused = true
		show_overlay("CHOOSE YOUR UPGRADE", "Wave %d cleared. Pick one change for this run." % wave)
		for index in 3:
			var details: Array[String] = ["+%.0f%% of base fireball damage" % (upgrade_damage_bonus * 100), "%.0f%% shorter casting interval" % (upgrade_cast_reduction * 100), "+%d projectile(s) per cast" % upgrade_projectiles]
			add_button(UPGRADE_TITLES[index] + "\n" + details[index], choose_upgrade.bind(index))
	else:
		state = State.BETWEEN_WAVES
		break_clock = intermission

func choose_upgrade(index: int) -> void:
	if state != State.UPGRADE or index < 0 or index >= 3:
		return
	match index:
		0: power_upgrades += 1
		1: quick_upgrades += 1
		2: fan_upgrades += 1
	update_build()
	upgrades_chosen += 1
	state = State.BETWEEN_WAVES
	break_clock = intermission
	overlay.hide()
	get_tree().paused = false
	update_hud()

func pause_run() -> void:
	# Preserve the intermission as well as an active wave when resuming.
	set_meta("resume_state", state)
	state = State.PAUSED
	get_tree().paused = true
	show_overlay("TAKE A BREATH", "The arena can wait.")
	add_button("Resume  [Esc]", resume_run)
	add_button("Equipment  [I]", inventory_panel.open_inventory)

func resume_run() -> void:
	if state != State.PAUSED:
		return
	state = get_meta("resume_state", State.FIGHTING)
	get_tree().paused = false
	overlay.hide()

func finish_run(victory: bool) -> void:
	if state in [State.FINISHED, State.TOWN]:
		return
	if is_instance_valid(dev_console):
		dev_console.close_console()
	inventory_panel.close_inventory()
	state = State.FINISHED
	result_victory = victory
	reward_due = predicted_reward()
	get_tree().paused = true
	settle_reward()

func predicted_reward() -> int:
	return echoes_per_wave * completed_waves * (completed_waves + 1) / 2

func settle_reward() -> void:
	if state != State.FINISHED or reward_saved:
		return
	if not progress.available:
		progress.load_progress()
	reward_saved = progress.award(reward_due, best_wave)
	show_overlay("THE EMBER ENDURES" if result_victory else "THE FLAME FADES", "Arena cleared!" if result_victory else "Every attempt teaches you something.")
	overlay_text.text += "\nWave %d / %d   |   %d cleared   |   %d defeats   |   Best %d\nEchoes earned: %d   |   Total: %d\n%s" % [wave, total_waves, completed_waves, kills, best_wave, reward_due, progress.echoes, "Reward saved. Run items reset on your next attempt." if reward_saved else progress.message]
	if reward_saved:
		add_button("Return to Town", return_to_town)
	else:
		add_button("Retry saving reward", settle_reward)

func _cast(origin: Vector2, direction: Vector2, damage: float) -> void:
	if state != State.FIGHTING:
		return
	var projectile = PROJECTILE.instantiate()
	projectile.position = origin
	projectile.direction = direction
	projectile.damage = damage
	projectile.opening_bonus = TALENTS.bonuses(active_talents, self).opening
	projectile.speed = projectile_speed
	projectile.lifetime = projectile_lifetime
	projectile.impact.connect(projectile_impact)
	projectiles.add_child(projectile)
	shots_fired += 1

func update_build() -> void:
	var build: Dictionary = build_for(equipment.scepter, equipment.book)
	player.damage = build.damage
	player.cast_interval = build.interval
	player.projectile_count = build.projectiles
	player.spread_angle = projectile_spread
	var perks: Dictionary = TALENTS.bonuses(active_talents, self)
	player.health_limit = player.max_health * (1.0 + perks.health)
	player.hurt_haste_ratio = perks.haste
	player.hurt_haste_duration = tree_haste_duration
	player.health = minf(player.health, player.health_limit)
	player.health_changed.emit(player.health, player.health_limit)
	if is_instance_valid(inventory_panel) and inventory_panel.is_open:
		inventory_panel.refresh()

func build_for(scepter: String, book: String) -> Dictionary:
	var perks: Dictionary = TALENTS.bonuses(active_talents, self)
	var gear_damage: float = (scepter_damage_bonus if scepter == "ember_scepter" else 0.0) + (focus_damage_bonus if book == "focus_grimoire" else 0.0)
	var interval: float = player.base_cast_interval * pow(1.0 - upgrade_cast_reduction, quick_upgrades)
	if scepter == "swift_scepter":
		interval *= 1.0 - scepter_cast_reduction
	interval *= 1.0 - minf(0.6, perks.interval)
	return {"damage": player.base_damage * (1.0 + power_upgrades * upgrade_damage_bonus) * (1.0 + gear_damage) * (1.0 + perks.damage), "interval": interval, "projectiles": 1 + fan_upgrades * upgrade_projectiles, "splash": book == "cinder_codex"}

func bag_used() -> int:
	return 8 - bag.count("")

func accept_item(id: String) -> bool:
	if state in [State.FINISHED, State.TOWN] or not CATALOG.ITEMS.has(id):
		return false
	var empty: int = bag.find("")
	if empty < 0:
		return false
	bag[empty] = id
	show_notice("Found %s %s — in your bag, inactive. Press I to inspect and equip." % [CATALOG.label(id), CATALOG.ITEMS[id].name])
	update_hud()
	return true

func equip_item(index: int) -> bool:
	if state in [State.FINISHED, State.TOWN] or index < 0 or index >= bag.size() or not CATALOG.ITEMS.has(bag[index]):
		return false
	var id: String = bag[index]
	var slot: String = CATALOG.ITEMS[id].slot
	bag[index] = equipment[slot]
	equipment[slot] = id
	update_build()
	update_hud()
	return true

func unequip_item(slot: String) -> bool:
	if state in [State.FINISHED, State.TOWN] or not equipment.has(slot) or equipment[slot].is_empty():
		return false
	var empty: int = bag.find("")
	if empty < 0:
		return false
	bag[empty] = equipment[slot]
	equipment[slot] = ""
	update_build()
	update_hud()
	return true

func drop_owned_item(index: int, slot: String) -> bool:
	if state in [State.FINISHED, State.TOWN]:
		return false
	var id: String = ""
	if index >= 0 and index < bag.size():
		id = bag[index]
	elif index == -1 and equipment.has(slot):
		id = equipment[slot]
	var offset := Vector2(maxf(95, pickup_radius + 35), 0)
	if player.position.x > BOUNDS.get_center().x:
		offset.x = -offset.x
	if not drop_item(id, player.position + offset):
		return false
	if index >= 0:
		bag[index] = ""
	else:
		equipment[slot] = ""
	update_build()
	update_hud()
	return true

func show_notice(text: String) -> void:
	notice_label.text = text
	notice_timer = 6.0

func destroy_bag_item(index: int) -> bool:
	if state in [State.TOWN, State.FINISHED] or index < 0 or index >= bag.size() or bag[index].is_empty():
		return false
	bag[index] = ""
	update_hud()
	return true

func enemy_slain(at: Vector2) -> void:
	kills += 1
	if loot.get_child_count() >= ground_loot_limit or state != State.FIGHTING or (rng.randf() >= equipment_drop_chance and equipment_drop_chance < 1.0):
		return
	var id: String = CATALOG.roll_item(rng, drop_chance, rare_chance, magic_chance, not codex_spawned)
	drop_item(id, at)

func rarity_rates() -> Dictionary:
	# shortcut: Codex is the only Legendary; derive eligibility from pools when adding another.
	var legendary: float = drop_chance if not codex_spawned else 0.0
	return {"legendary": legendary, "rare": (1.0 - legendary) * rare_chance, "magic": (1.0 - legendary) * (1.0 - rare_chance) * magic_chance, "normal": (1.0 - legendary) * (1.0 - rare_chance) * (1.0 - magic_chance)}

func drop_codex(at: Vector2) -> void:
	drop_item("cinder_codex", at)

func drop_item(id: String, at: Vector2) -> bool:
	if not CATALOG.ITEMS.has(id) or loot.get_child_count() >= ground_loot_limit or state in [State.FINISHED, State.TOWN]:
		return false
	var pickup = PICKUP.new()
	pickup.item_id = id
	pickup.position = at.clamp(BOUNDS.position + Vector2.ONE * 25, BOUNDS.end - Vector2.ONE * 25)
	pickup.player = player
	pickup.pickup_radius = pickup_radius
	pickup.collect = accept_item
	loot.add_child(pickup)
	drops_created += 1
	if id == "cinder_codex":
		codex_spawned = true
	return true

func projectile_impact(at: Vector2, hit_damage: float, primary: Object) -> void:
	shots_hit += 1
	if not codex_active:
		return
	effects.append({"at": at, "amount": 0, "killed": false, "life": 0.5, "explosion": explosion_radius})
	for enemy in enemies.get_children():
		if enemy != primary and not enemy.dead and enemy.global_position.distance_to(at) <= explosion_radius:
			enemy.take_damage(hit_damage * explosion_damage_ratio, at.direction_to(enemy.global_position))

func show_hit(at: Vector2, amount: float, killed: bool) -> void:
	damage_dealt += amount
	effects.append({"at": at, "amount": amount, "killed": killed, "life": 0.5})

func show_blocked(at: Vector2, amount: float) -> void:
	# Absorbed damage is feedback only, never dealt damage or another hit.
	effects.append({"at": at + Vector2(-18, -24), "amount": amount, "killed": false, "blocked": true, "life": 0.85, "duration": 0.85})

func _health_changed(current: float, maximum: float) -> void:
	damage_taken += maxf(0.0, last_health - current)
	last_health = current
	if health_bar == null:
		return
	health_bar.max_value = maximum
	health_bar.value = current
	health_label.text = "VITALITY   %d / %d" % [ceili(current), ceili(maximum)]

func update_hud() -> void:
	var status: String = "WAVE %02d / %02d" % [wave, total_waves]
	if state == State.BETWEEN_WAVES:
		status = "WAVE %02d IN %.1fs" % [wave + 1, maxf(break_clock, 0.0)]
	hud.text = "%s     /     %d REMAINING     /     BEST %02d" % [status, remaining_to_spawn + enemies.get_child_count(), best_wave]
	build_label.text = "FIREBALL   %.1f damage   /   %.2fs cast   /   %d projectile%s%s" % [player.damage, player.effective_interval(), player.projectile_count, "s" if player.projectile_count != 1 else "", "   /   SECOND WIND" if player.haste_remaining > 0 else ""]
	wallet_label.text = "ECHOES  %d   /   RUN REWARD  %d" % [progress.echoes, predicted_reward()]
	var scepter_name: String = "Empty" if equipment.scepter.is_empty() else CATALOG.ITEMS[equipment.scepter].name
	var book_name: String = "Empty" if equipment.book.is_empty() else CATALOG.ITEMS[equipment.book].name
	loot_label.text = "SCEPTER: %s   /   BOOK: %s   /   BAG: %d/8   /   I: inspect & equip" % [scepter_name, book_name, bag_used()]

func create_interface() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var ui := Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(ui)
	var theme := Theme.new()
	theme.default_font_size = 18
	theme.set_color("font_color", "Label", Color("e9ddc7"))
	ui.theme = theme
	add_label(ui, "L O O T F A L L", Vector2(64, 25), 30, Color("edcca0"))
	add_label(ui, "THE EMBER TRIAL   /   ARENA PROTOTYPE", Vector2(65, 66), 13, Color("9da6b3"))
	hud = add_label(ui, "", Vector2(580, 53), 17, Color("e9ddc7"))
	wallet_label = add_label(ui, "", Vector2(580, 80), 14, Color("ccac7b"))
	loot_label = add_label(ui, "", Vector2(65, 99), 13, Color("d6b67b"))
	notice_label = add_label(ui, "", Vector2(80, 685), 15, Color("f0d39f"))
	health_label = add_label(ui, "", Vector2(65, 742), 15, Color("e9ddc7"))
	health_bar = ProgressBar.new()
	health_bar.position = Vector2(65, 768)
	health_bar.size = Vector2(260, 9)
	health_bar.show_percentage = false
	var background := StyleBoxFlat.new()
	background.bg_color = Color("302a32")
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("bf7475")
	health_bar.add_theme_stylebox_override("background", background)
	health_bar.add_theme_stylebox_override("fill", fill)
	ui.add_child(health_bar)
	build_label = add_label(ui, "", Vector2(365, 744), 15, Color("d4c6ad"))
	add_label(ui, "WASD Move / MOUSE Aim / LMB Cast / I Equipment / ESC Pause" + (" / F1 Dev" if OS.is_debug_build() else ""), Vector2(365, 770), 13, Color("8995a5"))
	var shade := ColorRect.new()
	shade.color = Color(0.025, 0.035, 0.06, 0.88)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	shade.process_mode = Node.PROCESS_MODE_ALWAYS
	ui.add_child(shade)
	overlay = PanelContainer.new()
	overlay.position = Vector2(155, 255)
	overlay.size = Vector2(970, 290)
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color("1a2330")
	panel.border_color = Color("927755")
	panel.set_border_width_all(1)
	panel.content_margin_left = 30
	panel.content_margin_right = 30
	panel.content_margin_top = 26
	panel.content_margin_bottom = 26
	overlay.add_theme_stylebox_override("panel", panel)
	ui.add_child(overlay)
	overlay.visibility_changed.connect(func(): shade.visible = overlay.visible)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 20)
	overlay.add_child(column)
	overlay_title = Label.new()
	overlay_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_title.add_theme_font_size_override("font_size", 28)
	column.add_child(overlay_title)
	overlay_text = Label.new()
	overlay_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	overlay_text.custom_minimum_size.x = 900
	overlay_text.add_theme_font_size_override("font_size", 17)
	column.add_child(overlay_text)
	buttons = HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 14)
	column.add_child(buttons)

func add_label(parent: Node, text: String, at: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.position = at
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func show_overlay(title: String, text: String) -> void:
	for child in buttons.get_children():
		buttons.remove_child(child)
		child.queue_free()
	overlay_title.text = title
	overlay_text.text = text
	overlay.show()

func add_button(text: String, action: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(275, 70)
	button.add_theme_font_size_override("font_size", 16)
	button.pressed.connect(action)
	buttons.add_child(button)
	if buttons.get_child_count() == 1:
		button.grab_focus()

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 800), Color("0e1520"))
	draw_rect(BOUNDS.grow(10), Color("3c3c45"))
	draw_rect(BOUNDS.grow(6), Color("746047"), false, 1)
	draw_rect(BOUNDS, Color("202b37"))
	for x in range(64, 1216, 64):
		for y in range(128, 720, 48):
			var offset: int = 32 if ((y - 128) / 48) % 2 == 0 else 0
			draw_rect(Rect2(x + offset, y, 63, 47).intersection(BOUNDS), Color("293440"), false, 1)
	var center: Vector2 = BOUNDS.get_center()
	for radius in [86.0, 96.0, 205.0]:
		draw_arc(center, radius, 0, TAU, 96, Color("3d464c"), 1.5)
	for index in 12:
		var point: Vector2 = center + Vector2.from_angle(index * TAU / 12) * 96
		draw_line(point, center + (point - center) * 1.12, Color("73694f"), 2)
	for corner in [Vector2(79, 143), Vector2(1201, 143), Vector2(79, 705), Vector2(1201, 705)]:
		draw_circle(corner, 17, Color(0.85, 0.42, 0.18, 0.08))
		draw_circle(corner, 8, Color("b37c49"))
		draw_circle(corner, 3, Color("ffe0a0"))
	for effect in effects:
		var alpha: float = effect.life / effect.get("duration", 0.5)
		var color := Color("ffd291") if effect.killed else Color("f8e5c2")
		color.a = alpha
		var point: Vector2 = effect.at
		if effect.get("blocked", false):
			draw_string(ThemeDB.fallback_font, point + Vector2(-9, -25 - (1 - alpha) * 25), "%s BLOCKED" % str(snappedf(effect.amount, 0.1)), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.55, 0.84, 1.0, alpha))
			continue
		if effect.has("explosion"):
			draw_circle(point, effect.explosion * (1.0 - alpha), Color(1.0, 0.55, 0.2, alpha * 0.12))
			draw_arc(point, effect.explosion * (1.0 - alpha), 0, TAU, 40, color, 2)
			continue
		draw_arc(point, 8 + (1 - alpha) * (30 if effect.killed else 12), 0, TAU, 16, color, 2)
		draw_string(ThemeDB.fallback_font, point + Vector2(24, -25 - (1 - alpha) * 25), str(snappedf(effect.amount, 0.1)), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, color)
