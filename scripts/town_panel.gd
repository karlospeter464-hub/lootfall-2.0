extends CanvasLayer

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
var map: Connections

class Connections extends Control:
	var buttons: Dictionary
	var owned: Dictionary
	func _draw() -> void:
		for id in TREE.NODES:
			for parent in TREE.NODES[id].parents:
				var lit: bool = owned.has(parent) and owned.has(id)
				draw_line(buttons[parent].position + buttons[parent].size / 2, buttons[id].position + buttons[id].size / 2, Color("bda477") if lit else Color("3a4c60"), 3 if lit else 2, true)

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
	city.position = Vector2(240, 190)
	city.size = Vector2(800, 440)
	city.add_theme_constant_override("separation", 24)
	screen.add_child(city)
	var welcome := Label.new()
	welcome.text = "A MOMENT BY THE EMBERS"
	welcome.add_theme_font_size_override("font_size", 29)
	welcome.add_theme_color_override("font_color", Color("efd2a2"))
	city.add_child(welcome)
	var hint := Label.new()
	hint.text = "Return from the trial. Invest in what comes next.\nYour cards and equipment belong to each run.\nEchoes and the paths you awaken endure."
	hint.add_theme_font_size_override("font_size", 20)
	city.add_child(hint)
	summary = Label.new()
	summary.add_theme_font_size_override("font_size", 18)
	city.add_child(summary)
	skill_button = button(city, "Awaken the Skill Tree", show_tree)
	start_button = button(city, "Start Run", game.restart_run)
	retry_button = button(city, "Retry loading progress", func(): game.progress.load_progress(); refresh())
	tree_page = Control.new()
	tree_page.position = Vector2(45, 135)
	screen.add_child(tree_page)
	map = Connections.new()
	map.size = Vector2(790, 500)
	map.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tree_page.add_child(map)
	for branch in ["Power", "Vitality", "Flow"]:
		var column: int = ["Power", "Vitality", "Flow"].find(branch)
		label(map, branch.to_upper(), Vector2(column * 265 + 10, 0), Vector2(240, 30), 19, Color(TREE.COLORS[branch]))
	for id in TREE.NODES:
		var node: Dictionary = TREE.NODES[id]
		var column: int = ["Power", "Vitality", "Flow"].find(node.branch)
		var control := Button.new()
		control.position = Vector2(column * 265 + 8, 45 + (node.tier - 1) * 90)
		control.size = Vector2(220, 66)
		control.add_theme_font_size_override("font_size", 16)
		control.pressed.connect(select_node.bind(id))
		control.focus_entered.connect(select_node.bind(id))
		map.add_child(control)
		node_buttons[id] = control
	map.buttons = node_buttons
	title = label(tree_page, "", Vector2(810, 10), Vector2(360, 80), 26, Color("efd2a2"))
	detail = label(tree_page, "", Vector2(810, 100), Vector2(345, 170), 18)
	condition = label(tree_page, "", Vector2(810, 280), Vector2(345, 130), 16)
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

func refresh() -> void:
	var progress = game.progress
	wallet.text = "ECHOES  %d     /     BEST WAVE  %d     /     PATHS AWAKENED  %d / 15" % [progress.echoes, progress.best_wave, progress.talents.size()]
	var bonuses: Dictionary = TREE.bonuses(progress.talents, game)
	summary.text = "NEXT RUN  /  +%.0f%% damage  /  +%.0f%% health  /  %.0f%% shorter interval" % [bonuses.damage * 100, bonuses.health * 100, minf(0.6, bonuses.interval) * 100]
	start_button.disabled = not progress.available
	retry_button.visible = not progress.available
	map.owned = progress.talents
	map.queue_redraw()
	for id in node_buttons:
		var node: Dictionary = TREE.NODES[id]
		var owned: bool = progress.talents.has(id)
		var reachable: bool = TREE.accessible(id, progress.talents)
		node_buttons[id].text = node.name + "\n" + ("AWAKENED" if owned else ("%d Echoes" % game.talent_cost(id) if reachable else "LOCKED"))
		node_buttons[id].tooltip_text = TREE.description(id, game)
		var style := StyleBoxFlat.new()
		style.bg_color = Color("293a43") if owned else Color("1c2939")
		style.border_color = Color("f3d599") if selected == id else (Color(TREE.COLORS[node.branch]) if owned or reachable else Color("425064"))
		style.set_border_width_all(3 if selected == id else 1)
		style.set_corner_radius_all(10 if node.tier < 5 else 24)
		node_buttons[id].add_theme_stylebox_override("normal", style)
	var node: Dictionary = TREE.NODES[selected]
	title.text = node.name
	detail.text = TREE.description(selected, game) + "\n\nPermanent. Applies from your next run."
	var parents: Array[String] = []
	for parent in node.parents:
		parents.append(TREE.NODES[parent].name)
	condition.text = "Connect from: " + ("Town — no prerequisite" if parents.is_empty() else " OR ".join(parents))
	condition.text += "\n\n" + ("Owned. Paid %d Echoes." % progress.talents[selected] if progress.talents.has(selected) else "Cost: %d Echoes. All 15 nodes can be active together." % game.talent_cost(selected))
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
