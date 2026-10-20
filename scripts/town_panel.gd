extends CanvasLayer

const WORLD = preload("res://scripts/world_regions.gd")
const WORLD_ART = preload("res://scripts/world_art.gd")
const TREE = preload("res://scripts/skill_tree.gd")
var game
var screen: Control
var city: VBoxContainer
var tree_page: Control
var wallet: Label
var summary: Label
var title: Label
var detail: Label
var condition: Label
var status: Label
var buy_button: Button
var reset_button: Button
var start_button: Button
var skill_button: Button
var retry_button: Button
var node_buttons: Dictionary = {}
var selected: String = "power_1"
var showing_tree: bool = false
var tree_scroll: ScrollContainer
var region_cards: Array[RegionCard] = []
var sandbox_button: Button
var sandbox_tools: HBoxContainer
var map: Connections

class RegionCard extends Control:
	var region: int = 0
	var world: Dictionary
	func _draw() -> void:
		if world.is_empty():
			return
		var unlocked: bool = region <= WORLD.frontier(world)
		draw_set_transform(Vector2(0, 27), 0, Vector2(0.29, 0.13))
		WORLD_ART.floor_scene(self, region, WORLD.fraction(world, region) if unlocked else 0)
		draw_set_transform(Vector2.ZERO)
		if not unlocked:
			draw_rect(Rect2(0, 27, 371, 104), Color(0.03, 0.04, 0.07, 0.75))
		draw_string(ThemeDB.fallback_font, Vector2(10, 19), "%d  /  %s" % [region + 1, WORLD.REGIONS[region].name], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("efd2a2"))
		var text: String = "LOCKED — restore the previous region"
		if unlocked:
			text = "%s  /  %.0f%%  /  Best Wave %d" % ["RESTORED" if WORLD.fraction(world, region) == 1 else "FRONTIER", WORLD.fraction(world, region) * 100, world.best[region]]
		draw_string(ThemeDB.fallback_font, Vector2(10, 151), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("c5d5ce"))
		draw_rect(Rect2(10, 163, 350, 4), Color("263342"))
		draw_rect(Rect2(10, 163, 350 * WORLD.fraction(world, region), 4), Color("92c6a1"))

class Connections extends Control:
	var buttons: Dictionary
	var owned: Dictionary
	func _draw() -> void:
		for column in 3:
			var tint := Color(TREE.COLORS[["Power", "Vitality", "Flow"][column]])
			draw_circle(Vector2(column * 265 + 128, 290), 118, Color(tint, 0.025))
		for id in TREE.NODES:
			for parent in TREE.NODES[id].parents:
				var lit: bool = owned.has(parent) and owned.has(id)
				var tint := Color(TREE.COLORS[TREE.NODES[id].branch])
				var from: Vector2 = buttons[parent].position + buttons[parent].size / 2
				var to: Vector2 = buttons[id].position + buttons[id].size / 2
				var middle: float = (from.y + to.y) / 2
				draw_polyline(PackedVector2Array([from, Vector2(from.x, middle), Vector2(to.x, middle), to]), tint if lit else tint.darkened(0.6), 4 if lit else 2, true)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 15
	screen = Control.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(screen)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color("101b29")
	screen.add_child(shade)
	label(screen, "L O O T F A L L  /  EMBERHAVEN", Vector2(55, 30), Vector2(950, 40), 30, Color("efd2a2"))
	wallet = label(screen, "", Vector2(55, 80), Vector2(1160, 32), 18)
	city = VBoxContainer.new()
	city.position = Vector2(55, 135)
	city.size = Vector2(1160, 560)
	city.add_theme_constant_override("separation", 10)
	screen.add_child(city)
	var welcome := Label.new()
	welcome.text = "EVERY RUN BRINGS THE WORLD BACK TO LIFE"
	welcome.add_theme_font_size_override("font_size", 26)
	welcome.add_theme_color_override("font_color", Color("efd2a2"))
	city.add_child(welcome)
	var hint := Label.new()
	hint.text = "Return from the trial. Invest in what comes next.\nYour cards and equipment belong to each run.\nEchoes and the paths you awaken endure."
	hint.add_theme_font_size_override("font_size", 20)
	city.add_child(hint)
	hint.hide()
	summary = Label.new()
	summary.add_theme_font_size_override("font_size", 18)
	city.add_child(summary)
	var regions := HBoxContainer.new()
	regions.add_theme_constant_override("separation", 15)
	city.add_child(regions)
	for index in 3:
		var card := RegionCard.new()
		card.region = index
		card.clip_contents = true
		card.custom_minimum_size = Vector2(371, 175)
		regions.add_child(card)
		region_cards.append(card)
	sandbox_button = button(city, "", game.enter_world_sandbox)
	sandbox_button.visible = OS.is_debug_build()
	sandbox_tools = HBoxContainer.new()
	city.add_child(sandbox_tools)
	for stage in [0, 1, 2, 3]:
		button(sandbox_tools, "%d%% preview" % (stage * 25), game.sandbox_preview.bind(stage))
	button(sandbox_tools, "Heal + overflow / +3000 test Echoes", game.sandbox_complete)
	skill_button = button(city, "Awaken the Skill Tree", show_tree)
	start_button = button(city, "Start Run", game.restart_run)
	retry_button = button(city, "Retry loading progress", func(): game.progress.load_progress(); refresh())
	tree_page = Control.new()
	tree_page.position = Vector2(45, 135)
	screen.add_child(tree_page)
	tree_scroll = ScrollContainer.new()
	tree_scroll.size = Vector2(795, 580)
	tree_page.add_child(tree_scroll)
	map = Connections.new()
	map.custom_minimum_size = Vector2(790, 1780)
	map.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tree_scroll.add_child(map)
	for branch in ["Power", "Vitality", "Flow"]:
		var column: int = ["Power", "Vitality", "Flow"].find(branch)
		label(map, branch.to_upper(), Vector2(column * 265 + 10, 0), Vector2(240, 30), 19, Color(TREE.COLORS[branch]))
	for id in TREE.NODES:
		var node: Dictionary = TREE.NODES[id]
		var column: int = ["Power", "Vitality", "Flow"].find(node.branch)
		var control := Button.new()
		var special: bool = node.tier in [1, 5] or node.get("special", false)
		control.size = Vector2(204, 78) if special else (Vector2(158, 64) if node.tier == 4 else Vector2(86, 74))
		var offsets := [-10, 20, -18, 12, 0]
		control.position = Vector2(column * 265 + 128 + offsets[(node.tier - 1) % 5] * (1 if column != 1 else -1), 84 + (node.tier - 1) * 112) - control.size / 2
		control.add_theme_font_size_override("font_size", 16)
		control.pressed.connect(select_node.bind(id))
		control.focus_entered.connect(select_node.bind(id))
		map.add_child(control)
		node_buttons[id] = control
	map.buttons = node_buttons
	for column in 3:
		var prefix: String = ["power", "vitality", "flow"][column]
		for tier in range(1, 16):
			var control: Button = node_buttons["%s_%d" % [prefix, tier]]
			for direction in ["top", "bottom", "left", "right"]:
				var next_column: int = clampi(column + (-1 if direction == "left" else (1 if direction == "right" else 0)), 0, 2)
				var next_tier: int = clampi(tier + (-1 if direction == "top" else (1 if direction == "bottom" else 0)), 1, 15)
				var neighbor: Button = node_buttons["%s_%d" % [["power", "vitality", "flow"][next_column], next_tier]]
				control.set("focus_neighbor_" + direction, control.get_path_to(neighbor))
	label(map, "FILLED: awakened    /    GOLD: affordable    /    COLOR: save Echoes    /    DIM: locked", Vector2(0, 1750), Vector2(795, 28), 14, Color("aab6c7"))
	title = label(tree_page, "", Vector2(810, 10), Vector2(360, 80), 26, Color("efd2a2"))
	detail = label(tree_page, "", Vector2(810, 90), Vector2(345, 210), 17)
	condition = label(tree_page, "", Vector2(810, 310), Vector2(345, 105), 15)
	var actions := VBoxContainer.new()
	actions.position = Vector2(810, 420)
	actions.size.x = 345
	actions.add_theme_constant_override("separation", 10)
	tree_page.add_child(actions)
	buy_button = button(actions, "", buy_selected)
	reset_button = button(actions, "", refund_all)
	button(actions, "Back to Town  [Esc]", show_city)
	status = label(screen, "", Vector2(55, 720), Vector2(1165, 55), 16, Color("e3bf86"))
	screen.hide()

func _input(event: InputEvent) -> void:
	if not screen.visible or (is_instance_valid(game.dev_console) and game.dev_console.is_open):
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if showing_tree:
			show_city()
		get_viewport().set_input_as_handled()

func open_town() -> void:
	screen.show()
	status.text = ""
	show_city()

func close_town() -> void:
	screen.hide()

func show_city() -> void:
	showing_tree = false
	city.show()
	tree_page.hide()
	refresh()
	skill_button.grab_focus()

func show_tree() -> void:
	showing_tree = true
	city.hide()
	tree_page.show()
	refresh()
	node_buttons[selected].grab_focus()

func restore_focus() -> void:
	if showing_tree:
		node_buttons[selected].grab_focus()
	else:
		skill_button.grab_focus()

func select_node(id: String) -> void:
	selected = id
	refresh()
	tree_scroll.ensure_control_visible.call_deferred(node_buttons[id])

func refresh() -> void:
	var progress = game.progress
	wallet.text = "%sECHOES %d  /  TALENTS %d / 45  /  HIGHEST UNLOCKED REGION %d  /  REGIONS RESTORED %d" % ["SANDBOX — " if game.sandbox else "", progress.echoes, progress.talents.size(), mini(3, WORLD.restored(progress.world) + 1), WORLD.restored(progress.world)]
	for card in region_cards:
		card.world = progress.world
		card.queue_redraw()
	sandbox_button.text = "Leave sandbox — return to normal save" if game.sandbox else "Restoration sandbox — separate test save"
	sandbox_tools.visible = game.sandbox
	start_button.text = "Explore " + WORLD.REGIONS[WORLD.frontier(progress.world)].name + "  /  local Wave 1"
	var bonuses: Dictionary = TREE.bonuses(progress.talents, game)
	summary.text = "NEXT RUN  /  +%.0f%% damage  /  +%.0f%% health  /  %.0f%% shorter interval" % [bonuses.damage * 100, bonuses.health * 100, minf(0.6, bonuses.interval) * 100]
	summary.text += "\nPower → First Spark   /   Vitality → Renewal   /   Flow → Second Wind"
	var affordable: int = 0
	for id in TREE.NODES:
		if progress.available and TREE.accessible(id, progress.talents) and progress.echoes >= game.talent_cost(id):
			affordable += 1
	skill_button.text = "Awaken the Skill Tree" + ("  /  %d affordable" % affordable if affordable > 0 else "  /  earn Echoes in the trial")
	if progress.talents.size() == TREE.NODES.size():
		skill_button.text = "Skill Tree  /  all paths awakened"
	var roots: PackedStringArray = []
	for id in ["power_1", "vitality_1", "flow_1"]:
		if progress.talents.has(id):
			roots.append(TREE.NODES[id].name)
	summary.text += "\nEntry talents: " + (", ".join(roots) if not roots.is_empty() else "Kindling, Emberguard or Arcane Momentum — 30 Echoes each")
	start_button.disabled = not progress.available
	retry_button.visible = not progress.available
	map.owned = progress.talents
	map.queue_redraw()
	for id in node_buttons:
		var node: Dictionary = TREE.NODES[id]
		var owned: bool = progress.talents.has(id)
		var reachable: bool = TREE.accessible(id, progress.talents)
		var can_afford: bool = reachable and progress.available and progress.echoes >= game.talent_cost(id)
		var state_text: String = "AWAKENED" if owned else ("%d / READY" % game.talent_cost(id) if can_afford else ("%d Echoes" % game.talent_cost(id) if reachable else "LOCKED"))
		var caption: String = node.name if node.tier not in [2, 3] else ["", "", "II", "III"][node.tier]
		if node.tier > 5 and not node.get("special", false):
			caption = str(node.tier)
		if node.tier in [2, 3]:
			state_text = "OWNED" if owned else ("%d\nREADY" % game.talent_cost(id) if can_afford else ("%d Echoes" % game.talent_cost(id) if reachable else "LOCKED"))
		node_buttons[id].text = caption + "\n" + state_text
		node_buttons[id].add_theme_font_size_override("font_size", 13 if node.tier in [2, 3] else 16)
		node_buttons[id].tooltip_text = node.name + "\n" + TREE.description(id, game)
		var style := StyleBoxFlat.new()
		style.bg_color = Color(TREE.COLORS[node.branch]).darkened(0.66) if owned else Color("172332")
		style.border_color = Color("f3d599") if can_afford else (Color(TREE.COLORS[node.branch]) if owned or reachable else Color("354052"))
		style.set_border_width_all(3 if owned or can_afford else 2)
		style.set_corner_radius_all(38 if node.tier in [2, 3] else (8 if node.tier == 4 else 27))
		style.set_content_margin_all(2)
		node_buttons[id].add_theme_stylebox_override("normal", style)
		var hover: StyleBoxFlat = style.duplicate()
		hover.bg_color = style.bg_color.lightened(0.15)
		node_buttons[id].add_theme_stylebox_override("hover", hover)
		node_buttons[id].add_theme_stylebox_override("pressed", hover)
		var focus: StyleBoxFlat = style.duplicate()
		focus.bg_color = Color.TRANSPARENT
		focus.border_color = Color("fff0d0")
		focus.set_border_width_all(2)
		focus.expand_margin_left = 4
		focus.expand_margin_right = 4
		focus.expand_margin_top = 4
		focus.expand_margin_bottom = 4
		node_buttons[id].add_theme_stylebox_override("focus", focus)
		node_buttons[id].add_theme_color_override("font_color", Color("f4e5cf") if owned or reachable else Color("7f8da1"))
	var node: Dictionary = TREE.NODES[selected]
	title.text = node.name
	detail.text = TREE.description(selected, game) + "\n\nApplies from the next run."
	var parents: Array[String] = []
	for parent in node.parents:
		parents.append(TREE.NODES[parent].name)
	condition.text = "Connect from: " + ("Town — no prerequisite" if parents.is_empty() else " OR ".join(parents))
	condition.text += "\n" + ("Owned. Paid %d Echoes." % progress.talents[selected] if progress.talents.has(selected) else "Cost: %d Echoes." % game.talent_cost(selected))
	if not progress.talents.has(selected):
		condition.text += "\n" + ("Locked — connect a prerequisite." if not TREE.accessible(selected, progress.talents) else ("Ready to awaken." if progress.echoes >= game.talent_cost(selected) else "Need %d more Echoes." % (game.talent_cost(selected) - progress.echoes)))
	buy_button.text = "Awaken  /  %d Echoes" % game.talent_cost(selected)
	buy_button.disabled = not progress.available or not TREE.accessible(selected, progress.talents) or progress.echoes < game.talent_cost(selected)
	reset_button.text = "Reset all  /  Refund %d Echoes" % progress.invested()
	reset_button.disabled = not progress.available or progress.talents.is_empty()
	if not progress.available:
		status.text = progress.message

func buy_selected() -> void:
	status.text = "Awakened. Your next run will use this path." if game.buy_talent(selected) else game.progress.message
	refresh()

func refund_all() -> void:
	status.text = "All paths reset. The exact Echoes paid were returned." if game.refund_talents() else game.progress.message
	refresh()

func label(parent: Node, text: String, at: Vector2, size: Vector2, font_size: int, color: Color = Color("d5dce5")) -> Label:
	var control := Label.new()
	control.text = text
	control.position = at
	control.size = size
	control.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	control.add_theme_font_size_override("font_size", font_size)
	control.add_theme_color_override("font_color", color)
	parent.add_child(control)
	return control

func button(parent: Node, text: String, action: Callable) -> Button:
	var control := Button.new()
	control.text = text
	control.custom_minimum_size.y = 43
	control.pressed.connect(action)
	parent.add_child(control)
	return control
