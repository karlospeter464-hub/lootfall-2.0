extends Control

const CATALOG = preload("res://scripts/companion_catalog.gd")
var game
var friend: String = "gravity"
var selected: String = "gravity.damage0"
var heading: Label
var detail: Label
var message: Label
var buy_button: Button
var nodes: Dictionary = {}
var pickers: Array[OptionButton] = []
var friend_buttons: Dictionary = {}
var map: Control

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color("101b29")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	heading = label("", Vector2(45, 22), Vector2(1150, 45), 26)
	var top := HBoxContainer.new()
	top.position = Vector2(45, 80)
	top.add_theme_constant_override("separation", 20)
	add_child(top)
	for id in CATALOG.SPECIALS:
		friend_buttons[id] = button(top, CATALOG.FRIENDS[id].name, func():
			friend = id
			selected = id + ".damage0"
			rebuild())
	button(top, "Back to Emberhaven [Esc]", close)
	var loadout := HBoxContainer.new()
	loadout.position = Vector2(45, 136)
	add_child(loadout)
	for slot in 2:
		var text := Label.new()
		text.text = "  " + ["Q", "E"][slot] + "  "
		loadout.add_child(text)
		var picker := OptionButton.new()
		picker.custom_minimum_size = Vector2(220, 38)
		loadout.add_child(picker)
		pickers.append(picker)
		picker.item_selected.connect(func(index):
			var next: Array = game.progress.companions.slots.duplicate()
			var id: String = picker.get_item_metadata(index)
			if id != "" and next[1 - slot] == id: next[1 - slot] = next[slot]
			next[slot] = id
			message.text = "Loadout saved for the next run." if game.progress.equip_companions(next) else game.progress.message
			refresh())
	map = Control.new()
	map.position = Vector2(45, 220)
	map.size = Vector2(770, 480)
	map.draw.connect(draw_links)
	add_child(map)
	detail = label("", Vector2(850, 220), Vector2(365, 320), 19)
	var actions := VBoxContainer.new()
	actions.position = Vector2(850, 555)
	actions.size.x = 365
	add_child(actions)
	buy_button = button(actions, "", func():
		message.text = "Talent learned permanently; active when this friend is equipped next run." if game.progress.buy_companion(selected) else game.progress.message
		refresh())
	message = label("", Vector2(45, 730), Vector2(1170, 60), 17)
	hide()
	rebuild()

func open() -> void:
	game.town_panel.city.hide()
	game.town_panel.tree_page.hide()
	show()
	rebuild()
	friend_buttons[friend].grab_focus()

func close() -> void:
	hide()
	game.town_panel.show_city()

func _input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()

func rebuild() -> void:
	for child in map.get_children():
		map.remove_child(child)
		child.queue_free()
	nodes.clear()
	for id in CATALOG.nodes(friend):
		var node: Dictionary = CATALOG.nodes(friend)[id]
		var control := Button.new()
		control.position = Vector2(node.branch * 255, node.tier * 94)
		control.size = Vector2(225, 70)
		control.add_theme_font_size_override("font_size", 16)
		control.pressed.connect(func(): selected = id; refresh())
		control.focus_entered.connect(func(): selected = id; refresh())
		map.add_child(control)
		nodes[id] = control
	refresh()

func refresh() -> void:
	var state: Dictionary = game.progress.companions
	heading.text = "%sFRIENDS  /  %d ECHOES  /  %s — %s" % ["SANDBOX — " if game.sandbox else "", game.progress.echoes, CATALOG.FRIENDS[friend].name, "RESCUED" if friend in state.rescued else "Rescue in Wave %d" % CATALOG.FRIENDS[friend].wave]
	for i in 2:
		var picker: OptionButton = pickers[i]
		picker.clear()
		picker.add_item("Empty")
		picker.set_item_metadata(0, "")
		for id in state.rescued:
			picker.add_item(CATALOG.FRIENDS[id].name)
			picker.set_item_metadata(picker.item_count - 1, id)
		for index in picker.item_count:
			if picker.get_item_metadata(index) == state.slots[i]: picker.select(index)
		picker.disabled = not game.progress.available
	var tree: Dictionary = CATALOG.nodes(friend)
	for id in nodes:
		var owned: bool = state.purchases.has(id)
		var ready: bool = friend in state.rescued and CATALOG.accessible(id, state.purchases)
		nodes[id].text = tree[id].name + "\n" + ("LEARNED" if owned else str(tree[id].cost) + (" Echoes" if ready else " — locked"))
		nodes[id].tooltip_text = tree[id].description
		var style := StyleBoxFlat.new()
		style.bg_color = Color(CATALOG.FRIENDS[friend].color).darkened(0.73) if owned else Color("192737")
		style.border_color = Color("f3d599") if ready and game.progress.echoes >= tree[id].cost else Color(CATALOG.FRIENDS[friend].color).darkened(0.1 if owned else 0.6)
		style.set_border_width_all(2)
		style.set_corner_radius_all(12)
		nodes[id].add_theme_stylebox_override("normal", style)
	var node: Dictionary = tree[selected]
	detail.text = node.name + "\n\n" + node.description + "\n\n" + ("Paid %d Echoes." % state.purchases[selected] if state.purchases.has(selected) else "Cost: %d Echoes." % node.cost)
	detail.text += "\n\nLearn ANY connected predecessor. All 15 nodes can eventually be learned. Only equipped friends grant bonuses."
	buy_button.text = "Learn / %d Echoes" % node.cost
	buy_button.disabled = not game.progress.available or friend not in state.rescued or not CATALOG.accessible(selected, state.purchases) or game.progress.echoes < node.cost
	map.queue_redraw()
	game.town_panel.refresh()

func draw_links() -> void:
	for id in CATALOG.nodes(friend):
		for parent in CATALOG.nodes(friend)[id].parents:
			map.draw_line(nodes[parent].position + nodes[parent].size / 2, nodes[id].position + nodes[id].size / 2, Color("69587e"), 3, true)

func label(text: String, at: Vector2, dimensions: Vector2, font_size: int) -> Label:
	var control := Label.new()
	control.text = text
	control.position = at
	control.size = dimensions
	control.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	control.add_theme_font_size_override("font_size", font_size)
	add_child(control)
	return control

func button(parent: Node, text: String, action: Callable) -> Button:
	var control := Button.new()
	control.text = text
	control.custom_minimum_size.y = 43
	control.pressed.connect(action)
	parent.add_child(control)
	return control
