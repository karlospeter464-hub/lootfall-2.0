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
const COMPANIONS = preload("res://scripts/companion_catalog.gd")
const COMPANION_MAGIC = preload("res://scripts/companion_magic.gd")
const TALENTS = preload("res://scripts/skill_tree.gd")
const TOWN_PANEL = preload("res://scripts/town_panel.gd")
const WORLD = preload("res://scripts/world_regions.gd")
const WORLD_ART = preload("res://scripts/world_art.gd")
const GAME_FEEL = preload("res://scripts/game_feel.gd")
const GAME_SFX = preload("res://scripts/game_sfx.gd")
const UPGRADE_CARD = preload("res://scripts/upgrade_card.gd")
const BOUNDS := Rect2(64, 128, 1152, 592)
const UPGRADE_TITLES := ["Ember Power", "Quick Casting", "Fire Fan", "Ember Burst", "Piercing Flame", "Overcharge"]

enum State { FIGHTING, BETWEEN_WAVES, UPGRADE, PAUSED, FINISHED, TOWN, BOSS_INTRO, RESCUE }

@export_range(1, 50, 1) var first_wave_enemies: int = 8
@export_range(0, 20, 1) var enemies_per_wave: int = 4
@export_range(1, 100, 1) var enemy_limit: int = 12
@export_range(0, 6, 1) var ranged_limit: int = 2
@export_range(0.4, 3, 0.1) var ranged_windup: float = 1.4
@export_range(0.5, 6, 0.1) var ranged_interval: float = 2.0
@export_range(20, 100, 1) var ranged_radius: float = 38.0
@export_range(1, 10, 0.5) var seer_health_multiplier: float = 6.0
@export_range(0, 12, 1) var seer_interrupt_hits: int = 3
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
@export_range(5, 100, 1) var total_waves: int = 100
@export_range(1, 1.35, 0.01) var ascent_health_scale: float = 1.14
@export_range(0, 0.1, 0.01) var ascent_damage_growth: float = 0.04
@export_range(1, 60, 1) var ascent_budget_cap: int = 28
@export_range(0, 0.1, 0.01) var ascent_spawn_decay: float = 0.03
@export_range(1, 15, 0.5) var boss_health_multiplier: float = 6.0
@export_range(0, 10, 1) var boss_escorts: int = 4
@export_range(0, 1000, 1) var echoes_after_six: int = 25
@export_range(0, 100, 1) var echoes_after_six_growth: int = 2
@export_range(0.1, 10, 0.1) var intermission: float = 1.5
@export_range(0, 1, 0.01) var upgrade_damage_bonus: float = 0.35
@export_range(0, 0.8, 0.01) var upgrade_cast_reduction: float = 0.2
@export_range(1, 3, 1) var upgrade_projectiles: int = 1
@export_range(20, 150, 5) var burst_radius: float = 105.0
@export_range(0.05, 2, 0.05) var burst_damage_ratio: float = 0.7
@export_range(0.05, 2, 0.05) var overcharge_bonus: float = 0.75
@export_range(100, 1500, 25) var projectile_speed: float = 650.0
@export_range(0.1, 5, 0.1) var projectile_lifetime: float = 1.8
@export_range(0, 0.6, 0.01) var projectile_spread: float = 0.19
@export_range(0, 1, 0.005) var drop_chance: float = 0.02
@export_range(10, 100, 1) var pickup_radius: float = 36.0
@export_range(20, 250, 5) var explosion_radius: float = 85.0
@export_range(0, 3, 0.05) var explosion_damage_ratio: float = 0.6
@export_range(0, 1000, 1) var echoes_per_wave: int = 10
@export_range(0, 1, 0.01) var equipment_drop_chance: float = 0.05
@export_range(0.05, 0.3, 0.01) var echo_delay: float = 0.15
@export_range(0.1, 1, 0.05) var echo_damage_ratio: float = 0.6
@export_range(0.01, 0.2, 0.01) var hunter_step: float = 0.08
@export_range(0.1, 1, 0.05) var hunter_cap: float = 0.4
@export_range(0.5, 6, 0.5) var hunter_duration: float = 3.0
@export_range(50, 300, 10) var storm_radius: float = 150.0
@export_range(0.1, 1, 0.05) var storm_damage_ratio: float = 0.45
@export_range(0.01, 0.05, 0.01) var phoenix_heal_ratio: float = 0.03
@export_range(2, 10, 0.5) var phoenix_cooldown: float = 4.0
@export_range(0.2, 2, 0.1) var champion_warning: float = 0.7
@export_range(0.1, 1, 0.05) var champion_duration: float = 0.4
@export_range(0.2, 2, 0.1) var champion_recovery: float = 0.8
@export_range(0.5, 8, 0.5) var champion_cooldown: float = 2.0
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
@export_range(0, 2, 0.05) var tree_kindling_bonus: float = 0.25
@export_range(0.5, 10, 0.5) var tree_kindling_duration: float = 5.0
@export_range(0, 0.5, 0.01) var tree_emberguard_heal: float = 0.08
@export_range(0, 1, 0.01) var tree_momentum_bonus: float = 0.12
@export_range(0.5, 10, 0.5) var tree_momentum_duration: float = 3.0
var emberguard_used: bool = false
var run_region: int = 0
var run_id: String = ""
var restoration_due: int = 0
var restoration_pending: bool = false
var restoration_retry_clock: float = 0.0
var restoration_visual: float = 0.0
var newly_restored: int = 0
var restoration_tween: Tween
var sandbox: bool = false
var normal_progress_path: String = ""
var region_session_best: Array[int] = [0, 0, 0]


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
var cards_label: Label
var overlay_shade: ColorRect
var overlay: PanelContainer
var overlay_title: Label
var overlay_text: Label
var buttons: HBoxContainer
var loot: Node2D
var dev_console
var progress = PROGRESS.new()
var completed_waves: int = 0
var debug_echoes_paid: int = 0
var owed_echo_total: int = 0
var wave_echo_start: int = 0
var wave_echo_kills: int = 0
var feel
var sfx
var echo_label: Label
var codex_active: bool:
	get: return equipment.book == "cinder_codex"
var codex_spawned: bool = false
var bag: Array[String] = ["", "", "", "", "", "", "", ""]
var equipment: Dictionary = {"scepter": "", "book": ""}
var inventory_panel
var town_panel
var active_talents: Dictionary = {}
var companion_magic
var last_healed_wave: int = 0
var notice_label: Label
var notice_timer: float = 0.0
var reward_due: int = 0
var reward_saved: bool = false
var result_victory: bool = false
var power_upgrades: int = 0
var quick_upgrades: int = 0
var fan_upgrades: int = 0
var mechanic_cards: Array[int] = []
var offered_cards: Array[int] = []
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
var boss_label: Label
var boss_bar: ProgressBar
var boss
var boss_spawned: bool = false
var wave_budget: int = 0
var wave_seconds: float = 0.0
var wave_damage_start: float = 0.0
var wave_roles: Dictionary = {}
var wave_summaries: Array[Dictionary] = []
var run_started_usec: int = 0
var run_ended_usec: int = 0
var item_clock: float = 0.0
var echo_attacks: int = 0
var pending_echo: Dictionary = {}
var hunter_marks: Dictionary = {}
var phoenix_hits: int = 0
var phoenix_left: float = 0.0
var scepter_epoch: int = 0
var book_epoch: int = 0
var last_scepter: String = ""
var last_book: String = ""
var attack_context: Dictionary = {}

func _ready() -> void:
	if OS.get_cmdline_user_args().has("--test-mode"):
		progress.path = "user://test_progress_%d.json" % OS.get_process_id()
	normal_progress_path = progress.path
	progress.load_progress()
	progress.recover_echoes()
	get_tree().auto_accept_quit = false
	best_wave = progress.best_wave
	rng.randomize()
	player.arena_bounds = BOUNDS
	player.cast.connect(_cast)
	player.health_changed.connect(_health_changed)
	player.survived_hit.connect(emberguard)
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
	sfx = GAME_SFX.new()
	add_child(sfx)
	companion_magic = COMPANION_MAGIC.new()
	companion_magic.game = self
	add_child(companion_magic)
	companion_magic.hud = add_label(health_label.get_parent(), "", Vector2(580, 20), 14, Color("c8c4ff"))
	feel = GAME_FEEL.new()
	feel.game = self
	add_child(feel)
	move_child(feel, 0)
	restart_run()
	_show_town()

func _process(delta: float) -> void:
	if get_tree().paused:
		return
	elapsed += delta
	restoration_retry_clock = maxf(0, restoration_retry_clock - delta)
	if restoration_pending and restoration_retry_clock <= 0:
		restore_completed_waves()
	if state in [State.FIGHTING, State.BETWEEN_WAVES, State.BOSS_INTRO]:
		tick_item_effects(delta)
	notice_timer = maxf(0.0, notice_timer - delta)
	if notice_timer <= 0:
		notice_label.text = ""
	for effect in effects:
		effect.life -= delta
	effects = effects.filter(func(effect: Dictionary) -> bool: return effect.life > 0.0)
	queue_redraw()
	if state == State.FIGHTING:
		wave_seconds += delta
		spawn_clock -= delta
		if remaining_to_spawn > 0 and spawn_clock <= 0 and enemies.get_child_count() < enemy_limit:
			spawn_enemy()
			spawn_clock = wave_settings(wave).spawn_interval
		if remaining_to_spawn == 0 and enemies.get_child_count() == 0:
			complete_wave()
	elif state == State.BETWEEN_WAVES:
		break_clock -= delta
		if break_clock <= 0:
			begin_wave()
	elif state == State.BOSS_INTRO:
		break_clock -= delta
		if break_clock <= 0:
			overlay.hide()
			state = State.FIGHTING
			player.controls_enabled = true
	update_hud()

func _unhandled_input(event: InputEvent) -> void:
	if is_instance_valid(inventory_panel) and inventory_panel.is_open:
		return
	if is_instance_valid(dev_console) and dev_console.is_open:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_Q, KEY_E]:
		companion_magic.cast(0 if event.keycode == KEY_Q else 1, get_global_mouse_position())
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("pause") and not event.is_echo():
		if state == State.PAUSED:
			resume_run()
		elif state in [State.FIGHTING, State.BETWEEN_WAVES, State.BOSS_INTRO]:
			pause_run()
		get_viewport().set_input_as_handled()

func restart_run() -> void:
	if is_instance_valid(feel) and not flush_echoes():
		show_notice("Echoes not saved — retry before leaving this run. " + progress.message)
		return
	if restoration_pending and state != State.FINISHED and not restore_completed_waves():
		return
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
	if is_instance_valid(restoration_tween):
		restoration_tween.kill()
	run_region = WORLD.frontier(progress.world)
	run_id = Crypto.new().generate_random_bytes(16).hex_encode()
	restoration_due = 0
	restoration_pending = false
	restoration_retry_clock = 0.0
	newly_restored = 0
	restoration_visual = WORLD.fraction(progress.world, run_region)
	best_wave = maxi(int(progress.world.best[run_region]), region_session_best[run_region])
	effects.clear()
	wave = 0
	kills = 0
	upgrades_chosen = 0
	completed_waves = 0
	debug_echoes_paid = 0
	owed_echo_total = 0
	feel.reset()
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
	mechanic_cards.clear()
	offered_cards.clear()
	item_clock = 0
	echo_attacks = 0
	pending_echo.clear()
	hunter_marks.clear()
	phoenix_hits = 0
	phoenix_left = 0
	scepter_epoch += 1
	book_epoch += 1
	last_scepter = ""
	last_book = ""
	attack_context = {}
	elapsed = 0.0
	run_started_usec = Time.get_ticks_usec()
	run_ended_usec = 0
	wave_seconds = 0.0
	wave_summaries.clear()
	boss = null
	boss_spawned = false
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
	emberguard_used = false
	active_talents = progress.talents.duplicate() if not progress.companions.enabled else {}
	companion_magic.reset()
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
	if not TALENTS.NODES.has(id):
		return 0
	var tier: int = TALENTS.NODES[id].tier
	return int(get("tree_cost_%d" % tier)) if tier <= 5 else [160, 190, 240, 260, 320, 350, 420, 460, 520, 650][tier - 6]

func buy_talent(id: String) -> bool:
	return state == State.TOWN and progress.buy(id, talent_cost(id))

func refund_talents() -> bool:
	return state == State.TOWN and progress.refund_all()

func begin_wave() -> void:
	if wave >= total_waves:
		finish_run(true)
		return
	wave += 1
	wave_echo_start = echo_earned()
	wave_echo_kills = 0
	emberguard_used = false
	best_wave = maxi(best_wave, wave)
	region_session_best[run_region] = best_wave
	wave_budget = wave_settings(wave).budget
	remaining_to_spawn = wave_budget
	wave_seconds = 0.0
	wave_damage_start = damage_taken
	wave_roles = {"chaser": 0, "seer": 0, "guardian": 0, "boss": 0}
	boss = null
	boss_spawned = false
	spawn_clock = 0.0
	state = State.FIGHTING
	companion_magic.begin_rescue()
	if is_boss_wave(wave):
		state = State.BOSS_INTRO
		break_clock = 2.0
		player.controls_enabled = false
		show_overlay("BOSS APPROACHING", "%s\nWave %d — defeat the boss and its escort." % [boss_title(wave), wave])
	update_hud()

func is_boss_wave(number: int) -> bool:
	return number > 0 and number % 5 == 0

func boss_title(number: int) -> String:
	return "ASH PROPHET" if number % 10 == 0 else "RUNE CHAMPION"

func card_wave(number: int) -> bool:
	return number > 0 and number % 5 in [0, 2, 4]

func wave_settings(number: int) -> Dictionary:
	var level: int = clampi(number, 1, 100)
	var recovery: float = 0.8 if level > 5 and level % 5 == 1 else 1.0
	var health: float = (enemy_health + (mini(level, 6) - 1) * enemy_health_growth) * pow(ascent_health_scale, maxi(0, level - 6)) * recovery
	return {
		"health": clampf(health, 1, 1000000),
		"damage": clampf(enemy_damage * pow(1 + ascent_damage_growth, level - 1) * recovery, 1, 200),
		"speed": clampf(enemy_speed + (level - 1) * enemy_speed_growth, 10, 200),
		"budget": 1 + boss_escorts if is_boss_wave(level) else maxi(1, mini(ascent_budget_cap, ceili((first_wave_enemies + (level - 1) * enemies_per_wave) * recovery))),
		"spawn_interval": maxf(0.18, spawn_interval * pow(1 - ascent_spawn_decay, level - 1) / recovery),
		"seer_every": maxi(2, 4 - (level - 1) / 10) + (2 if recovery < 1 else 0),
		"guardian_every": maxi(3, guardian_every - (level - 1) / 10) + (2 if recovery < 1 else 0),
	}

func run_wall_seconds() -> float:
	if state == State.TOWN or run_started_usec == 0:
		return 0.0
	return ((run_ended_usec if run_ended_usec > 0 else Time.get_ticks_usec()) - run_started_usec) / 1000000.0

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
	var spawned_this_wave: int = wave_budget - remaining_to_spawn
	var settings: Dictionary = wave_settings(wave)
	var spawning_boss: bool = is_boss_wave(wave) and not boss_spawned
	var role: String = forced_role
	if spawning_boss:
		role = "seer" if wave % 10 == 0 else "guardian"
	var ranged_alive: int = 0
	var guardians_alive: int = 0
	for current in enemies.get_children():
		if current.get_script() == RANGED_ENEMY and not current.dead:
			ranged_alive += 1
		if current.get_script() == GUARDIAN_ENEMY and not current.dead:
			guardians_alive += 1
	if (spawning_boss and role == "guardian") or (wave >= guardian_first_wave and guardians_alive < guardian_limit and (role == "guardian" or (role.is_empty() and spawned_this_wave % int(settings.guardian_every) == int(settings.guardian_every) - 1))):
		enemy.set_script(GUARDIAN_ENEMY)
		enemy.armor = guardian_armor
		enemy.minimum_ratio = guardian_minimum_ratio
		enemy.armor_absorbed.connect(show_blocked)
	elif (spawning_boss and role == "seer") or (wave >= 2 and ranged_alive < ranged_limit and (role == "seer" or (role.is_empty() and spawned_this_wave % int(settings.seer_every) == int(settings.seer_every) - 1))):
		enemy.set_script(RANGED_ENEMY)
		enemy.windup = ranged_windup
		enemy.attack_interval = ranged_interval
		enemy.attack_radius = ranged_radius
		enemy.interrupt_hits = seer_interrupt_hits
	enemy.position = spawn_at
	enemy.target = player
	enemy.bounds = BOUNDS
	enemy.max_health = settings.health
	enemy.move_speed = settings.speed
	var role_name: String = "chaser"
	if enemy.get_script() == GUARDIAN_ENEMY:
		role_name = "guardian"
		enemy.max_health *= guardian_health_multiplier
		enemy.move_speed *= guardian_speed_ratio
	elif enemy.get_script() == RANGED_ENEMY:
		role_name = "seer"
		enemy.max_health *= seer_health_multiplier
	enemy.contact_damage = settings.damage
	if spawning_boss:
		boss_spawned = true
		boss = enemy
		enemy.boss_name = boss_title(wave)
		enemy.scale = Vector2.ONE * (1.8 if wave % 10 == 0 else 1.5)
		enemy.max_health *= boss_health_multiplier * (1.5 if wave % 10 == 0 else 1.0)
		enemy.contact_damage = minf(200, enemy.contact_damage * 1.5)
		role_name = "boss"
		if enemy.get_script() == RANGED_ENEMY:
			enemy.attack_radius *= 1.4
		else:
			enemy.escorts_cleared = champion_escorts_cleared.bind(enemy)
			enemy.charge_warning = champion_warning
			enemy.charge_duration = champion_duration
			enemy.charge_recovery = champion_recovery
			enemy.charge_interval = champion_cooldown
	enemy.max_health = minf(1000000, enemy.max_health)
	wave_roles[role_name] = wave_roles.get(role_name, 0) + 1
	enemy.frozen = enemies_frozen
	enemy.hit.connect(show_hit)
	enemy.slain.connect(enemy_slain)
	enemies.add_child(enemy)
	remaining_to_spawn -= 1

func champion_escorts_cleared(champion: Node) -> bool:
	champion.charge_warning = champion_warning
	champion.charge_duration = champion_duration
	champion.charge_recovery = champion_recovery
	champion.charge_interval = champion_cooldown
	return remaining_to_spawn == 0 and enemies.get_children().all(func(other): return other == champion or other.dead)

func start_ascent_test(number: int) -> bool:
	if not OS.is_debug_build() or not OS.get_cmdline_user_args().has("--test-mode") or number < 1 or number > total_waves:
		return false
	restart_run()
	if state == State.FINISHED:
		return false
	wave = number - 1
	rng.seed = 42
	begin_wave()
	return true

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

func start_item_test(id: String, group: bool) -> bool:
	if id not in ["echo_scepter", "hunter_scepter", "storm_grimoire", "phoenix_grimoire"] or not start_counterplay_test(0, 0):
		return false
	equipment = {"scepter": "", "book": ""}
	equipment[CATALOG.ITEMS[id].slot] = id
	quick_upgrades = 1
	fan_upgrades = 1
	mechanic_cards.assign([4, 5])
	upgrades_chosen = 4
	if not group:
		for enemy in enemies.get_children().slice(1):
			enemies.remove_child(enemy)
			enemy.queue_free()
	for enemy in enemies.get_children():
		enemy.max_health = 200 if group else 2000
		enemy.health = enemy.max_health
	if id == "phoenix_grimoire":
		player.health = player.health_limit * 0.6
	update_build()
	show_notice("CE4 isolated item test — %s. Seed 42, Quick / Fan / Pierce / Overcharge." % CATALOG.ITEMS[id].name)
	return true

func start_card_test(profile: int) -> bool:
	if profile < 0 or profile > 2 or not start_counterplay_test(profile, 0):
		return false
	mechanic_cards.assign([[3], [4], [5]][profile])
	power_upgrades = 2 if profile == 0 else 0
	quick_upgrades = 2 if profile == 2 else 0
	fan_upgrades = 2 if profile > 0 else 0
	equipment = {"scepter": "", "book": ""}
	if profile == 0:
		equipment.scepter = "ember_scepter"
	elif profile == 1:
		equipment.book = "cinder_codex"
	update_build()
	upgrades_chosen = power_upgrades + quick_upgrades + fan_upgrades + mechanic_cards.size()
	show_notice("CE3 isolated build test. Seed 42; normal wave flow resumes after this group.")
	update_hud()
	return true

func complete_wave() -> void:
	if state != State.FIGHTING or wave <= completed_waves or remaining_to_spawn > 0 or enemies.get_child_count() > 0:
		return
	completed_waves = maxi(completed_waves, wave)
	secure_echo_total(maxi(owed_echo_total, reward_for_waves(completed_waves) - debug_echoes_paid), player.position + Vector2(70, 0))
	feel.vacuum()
	restore_completed_waves()
	wave_summaries.append({"wave": wave, "boss": boss_title(wave) if is_boss_wave(wave) else "", "seconds": wave_seconds, "damage_taken": maxf(0, damage_taken - wave_damage_start), "roles": wave_roles.duplicate()})
	if last_healed_wave < wave:
		last_healed_wave = wave
		var perks: Dictionary = permanent_bonuses()
		if perks.healing > 0:
			player.health = minf(player.health_limit, player.health + player.health_limit * perks.healing * perks.heal_multiplier)
			player.health_changed.emit(player.health, player.health_limit)
	if companion_magic.offer_rescue(): return
	finish_wave_rewards()

func finish_wave_rewards() -> void:
	if card_wave(wave):
		state = State.UPGRADE
		roll_upgrade_cards()
		if offered_cards.is_empty():
			after_wave()
			return
		get_tree().paused = true
		show_overlay("BOSS REWARD — CHOOSE YOUR UPGRADE" if is_boss_wave(wave) else "CHOOSE YOUR UPGRADE", "Wave %d cleared. Pick one change for this run.\nCasting is capped at 0.08 s and fans at 9 projectiles." % wave)
		refresh_upgrade_cards()
		if feel.celebration > 3.5:
			overlay.hide()
			reveal_restoration_cards(run_id, wave)
	else:
		after_wave()

func reveal_restoration_cards(id: String, cleared_wave: int) -> void:
	# Give the actual growing landscape a moment before covering it with the choice.
	await get_tree().create_timer(1.8, true).timeout
	if state == State.UPGRADE and run_id == id and wave == cleared_wave:
		overlay.show()
		if buttons.get_child_count() > 0: buttons.get_child(0).grab_focus()

func roll_upgrade_cards() -> void:
	offered_cards.clear()
	var pool: Array[int] = []
	for index in UPGRADE_TITLES.size():
		if not upgrade_capped(index):
			pool.append(index)
	while not pool.is_empty() and offered_cards.size() < 3:
		var slot: int = rng.randi_range(0, pool.size() - 1)
		offered_cards.append(pool[slot])
		pool.remove_at(slot)

func card_description(index: int) -> String:
	return ["+%.0f%% of base fireball damage per stack" % (upgrade_damage_bonus * 100), "%.0f%% shorter casting interval per stack" % (upgrade_cast_reduction * 100), "+%d projectile(s) per cast per stack" % upgrade_projectiles, "On direct kill: %.0f radius explosion, %.0f%% shot damage. No chain reactions." % [burst_radius, burst_damage_ratio * 100], "Each fireball directly hits up to two different enemies.", "After 4 direct hits: next main shot +%.0f%% damage. Side shots stay normal." % (overcharge_bonus * 100)][index]

func refresh_upgrade_cards() -> void:
	if state != State.UPGRADE:
		return
	for child in buttons.get_children():
		buttons.remove_child(child)
		child.queue_free()
	var details: Array[String] = ["+%.0f%% of base fireball damage" % (upgrade_damage_bonus * 100), "%.0f%% shorter casting interval" % (upgrade_cast_reduction * 100), "+%d projectile(s) per cast" % upgrade_projectiles, "Kills explode\n%.0f radius / %.0f%% damage\nOnce per run" % [burst_radius, burst_damage_ratio * 100], "Fireballs hit up to two enemies\nOnce per run", "Every fourth direct hit:\nnext main shot +%.0f%%\nOnce per run" % (overcharge_bonus * 100)]
	for index in offered_cards:
		if not upgrade_capped(index):
			var card := UPGRADE_CARD.new()
			card.game = self
			card.kind = index
			card.description = details[index]
			card.text = UPGRADE_TITLES[index] + "\n" + details[index]
			card.pressed.connect(choose_upgrade.bind(index))
			buttons.add_child(card)
	if buttons.get_child_count() > 0:
		buttons.get_child(0).grab_focus()
	else:
		add_button("Continue — no valid upgrades", func():
			overlay.hide()
			get_tree().paused = false
			after_wave())

func upgrade_capped(index: int) -> bool:
	return (index == 0 and upgrade_damage_bonus <= 0) or (index == 1 and (player.cast_interval <= player.MIN_CAST_INTERVAL or upgrade_cast_reduction <= 0)) or (index == 2 and player.projectile_count >= player.MAX_PROJECTILES_PER_CAST) or mechanic_cards.has(index)

func after_wave() -> void:
	if wave >= total_waves:
		finish_run(true)
	else:
		state = State.BETWEEN_WAVES
		break_clock = intermission * (2.0 if is_boss_wave(wave) else 1.0)

func choose_upgrade(index: int) -> void:
	if state != State.UPGRADE or not offered_cards.has(index) or upgrade_capped(index):
		return
	sfx.cue("card")
	feel.confirm_card(index)
	match index:
		0: power_upgrades += 1
		1: quick_upgrades += 1
		2: fan_upgrades += 1
		_: mechanic_cards.append(index)
	offered_cards.clear()
	update_build()
	upgrades_chosen += 1
	overlay.hide()
	get_tree().paused = false
	after_wave()
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
	if state == State.BOSS_INTRO:
		show_overlay("BOSS APPROACHING", "%s\nWave %d — defeat the boss and its escort." % [boss_title(wave), wave])

func finish_run(victory: bool) -> void:
	if state in [State.FINISHED, State.TOWN]:
		return
	if is_instance_valid(dev_console):
		dev_console.close_console()
	inventory_panel.close_inventory()
	state = State.FINISHED
	companion_magic.clear_combat()
	pending_echo.clear()
	run_ended_usec = Time.get_ticks_usec()
	result_victory = victory
	reward_due = predicted_reward()
	restoration_due = WORLD.reward(completed_waves, elapsed, kills, shots_hit) if victory or player.health <= 0 or OS.get_cmdline_user_args().has("--test-mode") else 0
	get_tree().paused = true
	settle_reward()

func predicted_reward() -> int:
	return maxi(0, maxi(reward_for_waves(completed_waves) - debug_echoes_paid, owed_echo_total) - echo_paid())

func reward_for_waves(cleared: int) -> int:
	var early: int = clampi(cleared, 0, 6)
	var late: int = maxi(0, mini(cleared, 100) - 6)
	return echoes_per_wave * early * (early + 1) / 2 + late * echoes_after_six + late * (late - 1) / 2 * echoes_after_six_growth

func debug_jump_wave(number: int) -> bool:
	if not OS.is_debug_build() or number < 1 or number > total_waves or state == State.FINISHED:
		return false
	if state == State.TOWN:
		restart_run()
	if number <= wave or number - 1 < completed_waves:
		return false
	if not flush_echoes(): return false
	var prepaid: int = maxi(debug_echoes_paid, reward_for_waves(number - 1) - echo_paid())
	var before: int = WORLD.restored(progress.world)
	if not progress.debug_advance(prepaid - debug_echoes_paid, number - 1, run_region, WORLD.reward(number - 1, 0, 0, 0), run_id):
		return false
	newly_restored += WORLD.restored(progress.world) - before
	debug_echoes_paid = prepaid
	completed_waves = number - 1
	restoration_pending = false
	if is_instance_valid(dev_console):
		dev_console.close_console()
	inventory_panel.close_inventory()
	get_tree().paused = false
	overlay.hide()
	for container in [enemies, projectiles, loot]:
		for child in container.get_children():
			container.remove_child(child)
			child.queue_free()
	pending_echo.clear()
	hunter_marks.clear()
	effects.clear()
	if is_instance_valid(restoration_tween):
		restoration_tween.kill()
	restoration_visual = WORLD.fraction(progress.world, run_region)
	wave = number - 1
	player.controls_enabled = true
	begin_wave()
	show_notice("DEV jump: waves 1–%d credited. Build kept; skipped cards/items are not generated." % completed_waves)
	return true

func settle_reward() -> void:
	if state != State.FINISHED or reward_saved:
		return
	if not progress.available:
		progress.load_progress()
	if not flush_echoes():
		show_overlay("SAVE PENDING", progress.message)
		add_button("Retry saving reward", settle_reward)
		return
	reward_due = predicted_reward()
	var before: int = WORLD.restored(progress.world)
	reward_saved = progress.settle_expedition(reward_due, wave, run_region, restoration_due, run_id)
	if reward_saved:
		restoration_pending = false
		if WORLD.restored(progress.world) > before: feel.grow(true)
		newly_restored += WORLD.restored(progress.world) - before
		if is_instance_valid(restoration_tween):
			restoration_tween.kill()
		restoration_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		restoration_tween.tween_method(func(value: float): restoration_visual = value; queue_redraw(), restoration_visual, WORLD.fraction(progress.world, run_region), 1.5)
	show_overlay("PROTOTYPE LIMIT REACHED" if result_victory else "THE FLAME FADES", "Technical safety stop. This is not a victory." if result_victory else "Every attempt teaches you something.")
	overlay_text.text += "\nWave %d / %d   |   %d cleared   |   %d defeats   |   Best %d\nEchoes earned: %d   |   Total: %d\n%s" % [wave, total_waves, completed_waves, kills, best_wave, echo_paid() + debug_echoes_paid + reward_due, progress.echoes, "Reward saved. Run items reset on your next attempt." if reward_saved else progress.message]
	overlay_text.text += "\nRun time (including choices / pauses): %.1fs   |   Active: %.1fs" % [run_wall_seconds(), elapsed]
	overlay_text.text += "\n%s  /  %d Restoration earned this run (includes live credits)  /  %.0f%% healed" % [WORLD.REGIONS[run_region].name, restoration_due, WORLD.fraction(progress.world, run_region) * 100]
	if newly_restored > 0:
		overlay_title.text = "LIFE RETURNS"
		overlay_title.add_theme_color_override("font_color", Color("afe0b9"))
		overlay_text.text = "%s is restored. %s\n%d Restoration earned this run  /  +%d Echoes  /  %d regions restored\n%s" % [WORLD.REGIONS[run_region].name, WORLD.REGIONS[run_region].mood, restoration_due, echo_paid() + debug_echoes_paid + reward_due, WORLD.restored(progress.world), "Discover " + WORLD.REGIONS[WORLD.frontier(progress.world)].name + " — your next expedition begins at local Wave 1. Overflow was carried forward." if WORLD.restored(progress.world) < 3 else "All three regions healed. Your ascent continues; surplus Restoration is preserved."]
		overlay.position.y = 140
		overlay.size.y = 270
		overlay_shade.color.a = 0.12
	if debug_echoes_paid > 0:
		overlay_text.text += "\nDEV: %d Echoes already paid by jumps; %d remaining payout." % [debug_echoes_paid, reward_due]
	overlay_text.text += "\nEchoes secured during run: %d  /  final difference: %d" % [echo_paid() + debug_echoes_paid, reward_due]
	if reward_saved:
		add_button("Return to Town", return_to_town)
	else:
		add_button("Retry saving reward", settle_reward)

func _cast(origin: Vector2, direction: Vector2, damage: float) -> void:
	if state != State.FIGHTING or projectiles.get_child_count() >= 256:
		return
	if player.main_shot:
		attack_context = {"storm_used": false, "scepter_epoch": scepter_epoch, "book_epoch": book_epoch}
		if equipment.scepter == "echo_scepter":
			echo_attacks += 1
			if echo_attacks >= 4:
				echo_attacks = 0
				pending_echo = {"left": echo_delay, "direction": direction, "damage": damage * echo_damage_ratio, "context": attack_context}
	spawn_projectile(origin, direction, damage, attack_context, player.main_shot)

func spawn_projectile(origin: Vector2, direction: Vector2, damage: float, context: Dictionary, main: bool, echo: bool = false) -> void:
	if state != State.FIGHTING or projectiles.get_child_count() >= 256:
		return
	var projectile = PROJECTILE.instantiate()
	projectile.position = origin
	projectile.direction = direction
	var perks: Dictionary = permanent_bonuses()
	projectile.damage = damage * (1.3 if echo and active_talents.has("flow_10") else 1.0)
	projectile.max_hits = 2 if mechanic_cards.has(4) else 1
	projectile.echoed = echo
	if main and not echo and player.kindling_remaining > 0 and active_talents.has("power_1"):
		projectile.kindling_bonus = tree_kindling_bonus + (0.25 if active_talents.has("power_8") else 0.0)
		player.kindling_remaining = 0
	if main and player.overcharge_ready and mechanic_cards.has(5):
		projectile.damage = charged_damage(projectile.damage)
		projectile.charged = true
		player.overcharge_ready = false
		player.queue_redraw()
	projectile.opening_bonus = perks.opening
	projectile.speed = projectile_speed
	projectile.lifetime = projectile_lifetime
	projectile.direct_modifier = talent_direct_damage.bind(context)
	projectile.impact.connect(func(at, amount, primary): projectile_impact(at, amount, primary, context))
	projectiles.add_child(projectile)
	shots_fired += 1

func update_build() -> void:
	if is_instance_valid(boss) and not boss.dead and boss.get_script() == GUARDIAN_ENEMY:
		boss.charge_interval = champion_cooldown
		boss.charge_cooldown = minf(boss.charge_cooldown, champion_cooldown)
	if equipment.scepter != last_scepter:
		scepter_epoch += 1
		echo_attacks = 0
		pending_echo.clear()
		hunter_marks.clear()
		last_scepter = equipment.scepter
	if equipment.book != last_book:
		book_epoch += 1
		phoenix_hits = 0
		last_book = equipment.book
	var build: Dictionary = build_for(equipment.scepter, equipment.book)
	player.damage = build.damage
	player.cast_interval = build.interval
	player.projectile_count = build.projectiles
	player.spread_angle = projectile_spread
	player.overcharge_enabled = mechanic_cards.has(5)
	var perks: Dictionary = permanent_bonuses()
	player.health_limit = player.max_health * (1.0 + perks.health)
	player.hurt_haste_ratio = perks.haste
	player.hurt_haste_duration = tree_haste_duration
	player.momentum_bonus = tree_momentum_bonus if active_talents.has("flow_1") else 0.0
	player.momentum_duration = tree_momentum_duration + (2.0 if active_talents.has("flow_8") else 0.0)
	player.momentum_haste = 0.12 if active_talents.has("flow_15") else 0.0
	player.extra_protection = 0.2 if active_talents.has("vitality_8") else 0.0
	player.damage_reduction = 0.12 if active_talents.has("vitality_12") else 0.0
	player.last_light = active_talents.has("vitality_15")
	player.health = minf(player.health, player.health_limit)
	player.health_changed.emit(player.health, player.health_limit)
	if is_instance_valid(inventory_panel) and inventory_panel.is_open:
		inventory_panel.refresh()
	refresh_upgrade_cards()

func build_for(scepter: String, book: String) -> Dictionary:
	var perks: Dictionary = permanent_bonuses()
	var gear_damage: float = (scepter_damage_bonus if scepter == "ember_scepter" else 0.0) + (focus_damage_bonus if book == "focus_grimoire" else 0.0)
	var interval: float = player.base_cast_interval * pow(1.0 - upgrade_cast_reduction, quick_upgrades)
	if scepter == "swift_scepter":
		interval *= 1.0 - scepter_cast_reduction
	interval *= 1.0 - minf(0.6, perks.interval)
	if active_talents.has("power_12"):
		perks.damage += mechanic_cards.size() * 0.06
	var damage: float = player.base_damage * (1.0 + power_upgrades * upgrade_damage_bonus) * (1.0 + gear_damage) * (1.0 + perks.damage)
	return {"damage": damage, "interval": maxf(player.MIN_CAST_INTERVAL, interval), "projectiles": mini(player.MAX_PROJECTILES_PER_CAST, 1 + fan_upgrades * upgrade_projectiles), "splash": book == "cinder_codex", "splash_damage": damage * explosion_damage_ratio * perks.area_multiplier if book == "cinder_codex" else 0.0, "burst_damage": burst_damage(damage), "charged_damage": charged_damage(damage)}

func burst_damage(amount: float) -> float:
	return amount * burst_damage_ratio * permanent_bonuses().area_multiplier

func charged_damage(amount: float) -> float:
	return amount * (1.0 + overcharge_bonus)

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
	companion_magic.slain(at)
	kills += 1
	if state == State.FIGHTING and wave > 0:
		wave_echo_kills += 1
		var budget: int = reward_for_waves(wave) - reward_for_waves(wave - 1)
		var earned: int = wave_echo_start + budget * mini(wave_echo_kills, wave_budget) / maxi(1, wave_budget)
		secure_echo_total(maxi(owed_echo_total, earned), at)
	if state == State.FIGHTING and player.health > 0 and active_talents.has("power_1"):
		player.kindling_remaining = tree_kindling_duration
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

func tick_item_effects(delta: float) -> void:
	if get_tree().paused or state not in [State.FIGHTING, State.BETWEEN_WAVES, State.BOSS_INTRO]:
		return
	item_clock += delta
	phoenix_left = maxf(0, phoenix_left - delta)
	for id in hunter_marks.keys():
		var target = hunter_marks[id].target.get_ref()
		if target == null or target.dead or hunter_marks[id].until <= item_clock:
			hunter_marks.erase(id)
	if not pending_echo.is_empty():
		pending_echo.left -= delta
		if pending_echo.left <= 0:
			var echo: Dictionary = pending_echo
			pending_echo = {}
			if equipment.scepter == "echo_scepter" and echo.context.scepter_epoch == scepter_epoch:
				spawn_projectile(player.global_position + echo.direction * 25, echo.direction, echo.damage, echo.context, false, true)

func hunter_damage(target: Object, amount: float, context: Dictionary) -> float:
	if state != State.FIGHTING or equipment.scepter != "hunter_scepter" or context.get("scepter_epoch", -1) != scepter_epoch:
		return amount
	var id: int = target.get_instance_id()
	var mark: Dictionary = hunter_marks.get(id, {"hits": 0, "until": 0.0, "target": weakref(target)})
	if mark.until <= item_clock:
		mark.hits = 0
	var bonus: float = minf(hunter_cap, mark.hits * hunter_step)
	mark.hits = mini(ceili(hunter_cap / hunter_step), mark.hits + 1)
	mark.until = item_clock + hunter_duration
	hunter_marks[id] = mark
	return amount * (1.0 + bonus)

func item_direct_hit(primary: Object, amount: float, context: Dictionary) -> void:
	if state != State.FIGHTING or player.health <= 0 or context.get("book_epoch", -1) != book_epoch:
		return
	if equipment.book == "phoenix_grimoire" and phoenix_left <= 0:
		phoenix_hits += 1
		if phoenix_hits >= 10:
			phoenix_hits = 0
			phoenix_left = phoenix_cooldown
			var healing: float = minf(player.health_limit - player.health, player.health_limit * phoenix_heal_ratio * permanent_bonuses().heal_multiplier)
			if healing > 0:
				player.health += healing
				player.health_changed.emit(player.health, player.health_limit)
				if effects.size() < 512:
					effects.append({"at": player.global_position, "amount": healing, "killed": false, "life": 0.5, "heal": true})
	if equipment.book != "storm_grimoire" or context.get("storm_used", true):
		return
	# Consume the first-hit attempt even if no second target is in range.
	context.storm_used = true
	var nearest = null
	var distance: float = pow(storm_radius * (1.4 if active_talents.has("flow_12") else 1.0), 2)
	for enemy in enemies.get_children():
		if enemy == primary or enemy.dead:
			continue
		var candidate: float = primary.global_position.distance_squared_to(enemy.global_position)
		if candidate <= distance:
			distance = candidate
			nearest = enemy
	if nearest != null:
		var from: Vector2 = primary.global_position
		var to: Vector2 = nearest.global_position
		nearest.take_damage(amount * storm_damage_ratio * (1.25 if active_talents.has("flow_12") else 1.0), from.direction_to(to))
		if effects.size() < 512:
			effects.append({"at": from, "to": to, "amount": 0, "killed": false, "life": 0.25, "duration": 0.25, "lightning": true})

func projectile_impact(at: Vector2, hit_damage: float, primary: Object, context: Dictionary = {}) -> void:
	shots_hit += 1
	companion_magic.fireball_hit(primary)
	player.record_direct_hit()
	item_direct_hit(primary, hit_damage, context)
	# Snapshot the direct kill before Codex splash can kill other enemies.
	if mechanic_cards.has(3) and is_instance_valid(primary) and primary.dead and not primary.has_meta("ember_burst_triggered"):
		primary.set_meta("ember_burst_triggered", true)
		area_damage(primary.global_position, burst_damage(hit_damage), burst_radius, primary, true)
	if codex_active:
		area_damage(at, hit_damage * explosion_damage_ratio * permanent_bonuses().area_multiplier, explosion_radius, primary)

func area_damage(at: Vector2, amount: float, radius: float, primary: Object, burst: bool = false) -> void:
	if amount <= 0:
		return
	# Bound transient visuals as well as projectiles; damage is never dropped.
	if effects.size() < 512:
		effects.append({"at": at, "amount": 0, "killed": false, "life": 0.5, "explosion": radius, "burst": burst})
	for enemy in enemies.get_children():
		if enemy != primary and not enemy.dead and enemy.global_position.distance_squared_to(at) <= radius * radius:
			enemy.take_damage(amount, at.direction_to(enemy.global_position))

func show_hit(at: Vector2, amount: float, killed: bool) -> void:
	damage_dealt += amount
	if effects.size() < 512:
		effects.append({"at": at, "amount": amount, "killed": killed, "life": 0.5})

func show_blocked(at: Vector2, amount: float) -> void:
	# Absorbed damage is feedback only, never dealt damage or another hit.
	if effects.size() < 512:
		effects.append({"at": at + Vector2(-18, -24), "amount": amount, "killed": false, "blocked": true, "life": 0.85, "duration": 0.85})

func emberguard() -> void:
	if state != State.FIGHTING or emberguard_used or not active_talents.has("vitality_1"):
		return
	emberguard_used = true
	var healing: float = minf(player.health_limit - player.health, player.health_limit * tree_emberguard_heal * permanent_bonuses().heal_multiplier)
	player.health += healing
	player.health_changed.emit(player.health, player.health_limit)
	if healing > 0 and effects.size() < 512:
		effects.append({"at": player.global_position, "amount": healing, "killed": false, "life": 0.5, "heal": true})

func _health_changed(current: float, maximum: float) -> void:
	damage_taken += maxf(0.0, last_health - current)
	last_health = current
	if health_bar == null:
		return
	health_bar.max_value = maximum
	health_bar.value = current
	health_label.text = "VITALITY   %d / %d" % [ceili(current), ceili(maximum)]

func update_hud() -> void:
	var status: String = "WAVE %02d%s" % [wave, " / BOSS" if is_boss_wave(wave) else ""]
	if state == State.BETWEEN_WAVES:
		status = "WAVE %02d IN %.1fs" % [wave + 1, maxf(break_clock, 0.0)]
	hud.text = "%s     /     %d REMAINING     /     BEST %02d" % [status, remaining_to_spawn + enemies.get_child_count(), best_wave]
	build_label.text = "FIREBALL   %.1f damage   /   %.2fs cast   /   %d projectile%s%s" % [player.damage, player.effective_interval(), player.projectile_count, "s" if player.projectile_count != 1 else "", "   /   SECOND WIND" if player.haste_remaining > 0 else ""]
	var names: PackedStringArray = []
	for card in mechanic_cards:
		names.append(UPGRADE_TITLES[card])
	cards_label.text = " / ".join(names)
	if player.overcharge_enabled:
		cards_label.text += "   [READY]" if player.overcharge_ready else "   [%d/4 hits]" % player.overcharge_hits
	if is_instance_valid(echo_label):
		echo_label.text = "RUN ECHOES  +%d%s" % [echo_paid(), " / SAVE PENDING" if is_instance_valid(feel) and feel.save_pending else ""]
	wallet_label.text = "%s  /  %.1f%% healed  /  ECHOES %d (+%d)%s" % [WORLD.REGIONS[run_region].name, WORLD.fraction(progress.world, run_region) * 100, progress.echoes, predicted_reward(), "  /  SAVE PENDING" if restoration_pending else ""]
	var scepter_name: String = "Empty" if equipment.scepter.is_empty() else CATALOG.ITEMS[equipment.scepter].name
	var book_name: String = "Empty" if equipment.book.is_empty() else CATALOG.ITEMS[equipment.book].name
	loot_label.text = "SCEPTER: %s   /   BOOK: %s   /   BAG: %d/8   /   I: inspect & equip" % [scepter_name, book_name, bag_used()]
	var boss_alive: bool = is_instance_valid(boss) and not boss.dead
	boss_label.visible = boss_alive
	boss_bar.visible = boss_alive
	if boss_alive:
		boss_label.text = "%s   /   %.0f / %.0f" % [boss.boss_name, boss.health, boss.max_health]
		boss_bar.max_value = boss.max_health
		boss_bar.value = boss.health

func create_interface() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var ui := Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(ui)
	var theme := preload("res://scripts/menu_theme.gd").create()
	theme.default_font_size = 18
	theme.set_color("font_color", "Label", Color("e9ddc7"))
	ui.theme = theme
	boss_label = add_label(ui, "", Vector2(360, 138), 15, Color("f0c88e"))
	boss_bar = ProgressBar.new()
	boss_bar.position = Vector2(360, 162)
	boss_bar.size = Vector2(560, 12)
	boss_bar.show_percentage = false
	var boss_background := StyleBoxFlat.new()
	boss_background.bg_color = Color("302a32")
	var boss_fill := StyleBoxFlat.new()
	boss_fill.bg_color = Color("c1975c")
	boss_bar.add_theme_stylebox_override("background", boss_background)
	boss_bar.add_theme_stylebox_override("fill", boss_fill)
	ui.add_child(boss_bar)
	add_label(ui, "L O O T F A L L", Vector2(64, 25), 30, Color("edcca0"))
	add_label(ui, "RECLAIM LIFE   /   THE RESTORATION EXPEDITION", Vector2(65, 66), 13, Color("9da6b3"))
	hud = add_label(ui, "", Vector2(580, 53), 17, Color("e9ddc7"))
	wallet_label = add_label(ui, "", Vector2(580, 80), 14, Color("ccac7b"))
	echo_label = add_label(ui, "", Vector2(920, 99), 14, Color("f2cf86"))
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
	cards_label = add_label(ui, "", Vector2(365, 722), 13, Color("baf7ff"))
	add_label(ui, "WASD Move / MOUSE Aim / LMB Cast / Q + E Friends / I Equipment / ESC Pause" + (" / F1 Dev" if OS.is_debug_build() else ""), Vector2(365, 770), 13, Color("8995a5"))
	var shade := ColorRect.new()
	overlay_shade = shade
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
	panel.set_corner_radius_all(16)
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
	overlay_shade.color.a = 0.25 if state in [State.FINISHED, State.UPGRADE] else 0.88
	overlay.position.y = 175 if state == State.FINISHED else (190 if state == State.UPGRADE else 255)
	overlay.size.y = 450 if state == State.FINISHED else (430 if state == State.UPGRADE else 290)
	overlay_title.text = title
	overlay_title.add_theme_color_override("font_color", Color("ffc38f") if state == State.BOSS_INTRO else Color("e9ddc7"))
	overlay_title.add_theme_font_size_override("font_size", 34 if state == State.BOSS_INTRO else 28)
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
	draw_floor()
	for effect in effects:
		var alpha: float = effect.life / effect.get("duration", 0.5)
		var color := Color("ffd291") if effect.killed else Color("f8e5c2")
		color.a = alpha
		var point: Vector2 = effect.at
		if effect.get("heal", false):
			draw_arc(point, 24 + (1 - alpha) * 22, 0, TAU, 24, Color(0.4, 1, 0.65, alpha), 3)
			draw_string(ThemeDB.fallback_font, point + Vector2(20, -25), "+%.1f HP" % effect.amount, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.4, 1, 0.65, alpha))
			continue
		if effect.get("lightning", false):
			var route: Vector2 = effect.to - point
			var side: Vector2 = route.normalized().orthogonal()
			var bolt := PackedVector2Array([point, point + route * 0.3 + side * 12, point + route * 0.44 - side * 8, point + route * 0.7 + side * 6, effect.to])
			draw_polyline(bolt, Color(0.25, 0.48, 0.8, alpha), 7, true)
			draw_polyline(bolt, Color(0.78, 0.94, 1, alpha), 2, true)
			draw_arc(effect.to, 7 + (1 - alpha) * 12, 0, TAU, 12, Color(0.65, 0.86, 1, alpha), 2)
			continue
		if effect.get("blocked", false):
			draw_polyline(PackedVector2Array([point + Vector2(-16, -18), point + Vector2(0, -9), point + Vector2(16, -18)]), Color(0.55, 0.84, 1.0, alpha), 3, true)
			draw_string(ThemeDB.fallback_font, point + Vector2(-9, -25 - (1 - alpha) * 25), "%s BLOCKED" % str(snappedf(effect.amount, 0.1)), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.55, 0.84, 1.0, alpha))
			continue
		if effect.has("explosion"):
			if effect.get("burst", false):
				draw_circle(point, effect.explosion, Color(1, 0.35, 0.08, alpha * 0.09))
				var ring: float = effect.explosion * (0.65 + (1 - alpha) * 0.35)
				draw_arc(point, ring, 0, TAU, 24, Color(1, 0.7, 0.25, alpha), 3)
				for index in 8:
					var ray: Vector2 = Vector2.from_angle(index * TAU / 8 + 0.2)
					draw_line(point + ray * ring * 0.4, point + ray * ring, Color(1, 0.84, 0.58, alpha), 3)
			draw_circle(point, effect.explosion * (1.0 - alpha), Color(1.0, 0.55, 0.2, alpha * 0.12))
			draw_arc(point, effect.explosion * (1.0 - alpha), 0, TAU, 40, color, 2)
			continue
		draw_arc(point, 8 + (1 - alpha) * (30 if effect.killed else 12), 0, TAU, 16, color, 2)
		for index in 4:
			var ray: Vector2 = Vector2.from_angle(index * PI / 2 + PI / 4)
			draw_line(point + ray * 4, point + ray * (10 + (1 - alpha) * 10), color, 2)
		draw_string(ThemeDB.fallback_font, point + Vector2(24, -25 - (1 - alpha) * 25), str(snappedf(effect.amount, 0.1)), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, color)

func draw_floor() -> void:
	WORLD_ART.floor_scene(self, run_region, restoration_visual, feel.clock if is_instance_valid(feel) else 0.0)

func talent_direct_damage(target: Object, amount: float, context: Dictionary) -> float:
	var value: float = hunter_damage(target, amount, context)
	if not target.boss_name.is_empty() and active_talents.has("power_10"):
		value *= 1.25
	return companion_magic.fireball_damage(target, value)

func permanent_bonuses() -> Dictionary:
	var result: Dictionary = TALENTS.bonuses(active_talents, self)
	if is_instance_valid(companion_magic):
		var extra: Dictionary = COMPANIONS.bonuses(companion_magic.talents)
		for stat in extra: result[stat] += extra[stat]
	return result

func enter_world_sandbox() -> bool:
	if not OS.is_debug_build() or state != State.TOWN:
		return false
	sandbox = not sandbox
	progress = PROGRESS.new()
	progress.path = "user://restoration_sandbox.json" if sandbox else normal_progress_path
	progress.load_progress()
	for index in 3:
		region_session_best[index] = int(progress.world.best[index])
	restart_run()
	_show_town()
	return true

func sandbox_preview(stage: int) -> bool:
	if not sandbox or not OS.is_debug_build() or state != State.TOWN or stage not in [0, 1, 2, 3]:
		return false
	var next: Dictionary = progress.world.duplicate(true)
	var region: int = WORLD.frontier(next)
	next.points[region] = WORLD.REGIONS[region].cost * stage / 4
	var ok: bool = progress._save(progress.echoes, progress.best_wave, progress.talents, next)
	town_panel.refresh()
	return ok

func sandbox_complete() -> bool:
	if not sandbox or not OS.is_debug_build() or state != State.TOWN:
		return false
	var region: int = WORLD.frontier(progress.world)
	var points: int = WORLD.REGIONS[region].cost - int(progress.world.points[region]) + 120
	var ok: bool = progress.settle_expedition(3000, 1, region, points, Crypto.new().generate_random_bytes(16).hex_encode())
	town_panel.status.text = "SANDBOX: region healed, 120 overflow points and 3000 test Echoes. Normal save untouched." if ok else progress.message
	town_panel.refresh()
	return ok

func restore_completed_waves() -> bool:
	var before: int = WORLD.restored(progress.world)
	var total: int = WORLD.reward(completed_waves, 0, 0, 0)
	if not progress.restore_during_run(total, wave, run_region, run_id):
		restoration_pending = true
		restoration_retry_clock = 2.0
		show_notice("Restoration not saved — retry pending. " + progress.message)
		return false
	restoration_pending = false
	if is_instance_valid(restoration_tween):
		restoration_tween.kill()
	restoration_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	restoration_tween.tween_method(func(value: float): restoration_visual = value; queue_redraw(), restoration_visual, WORLD.fraction(progress.world, run_region), 1.2)
	var completed: int = WORLD.restored(progress.world) - before
	if is_instance_valid(feel): feel.grow(completed > 0)
	newly_restored += completed
	var message: String = "+%d Restoration — %.1f%% of %s healed" % [4 * completed_waves, WORLD.fraction(progress.world, run_region) * 100, WORLD.REGIONS[run_region].name]
	if completed > 0:
		message = "LIFE RETURNS — %s restored! %s" % [WORLD.REGIONS[run_region].name, "Next expedition: " + WORLD.REGIONS[WORLD.frontier(progress.world)].name if WORLD.restored(progress.world) < 3 else "All regions restored."]
	show_notice(message)
	update_hud()
	return true

func echo_earned() -> int:
	return int(progress.echo_run.earned) if progress.echo_run.id == run_id else 0

func echo_paid() -> int:
	return int(progress.echo_run.paid) if progress.echo_run.id == run_id else 0

func secure_echo_total(total: int, at: Vector2) -> bool:
	owed_echo_total = maxi(owed_echo_total, total)
	var old: int = echo_earned()
	if total <= old: return true
	if not progress.record_echoes(total, run_id):
		feel.save_pending = true
		feel.retry = 1.0
		show_notice("ECHO SAVE PENDING — rewards retained for retry. " + progress.message)
		return false
	feel.save_pending = false
	feel.add_orb(at, total - old)
	return true

func flush_echoes() -> bool:
	if owed_echo_total > echo_earned() and not secure_echo_total(owed_echo_total, player.position): return false
	if not progress.recover_echoes(): return false
	if is_instance_valid(feel): feel.reset()
	return true

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and is_instance_valid(feel):
		if not flush_echoes() or (restoration_pending and not restore_completed_waves()):
			show_notice("SAVE PENDING — could not close safely. Retry when storage is available.")
			return
		if state == State.FINISHED and not reward_saved:
			settle_reward()
			if not reward_saved: return
		get_tree().quit()
