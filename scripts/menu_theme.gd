extends RefCounted

static func panel(fill: String, border: String, radius: int = 12) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(fill)
	box.border_color = Color(border)
	box.set_border_width_all(1)
	box.set_corner_radius_all(radius)
	box.set_content_margin_all(12)
	return box

static func create() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 16
	theme.set_color("font_color", "Label", Color("e6e4df"))
	theme.set_color("default_color", "RichTextLabel", Color("d6deea"))
	for type in ["Button", "OptionButton"]:
		for state in ["normal", "hover", "pressed", "disabled", "focus"]:
			var fill: String = {"normal": "202d40", "hover": "30435a", "pressed": "38546a", "disabled": "17212f", "focus": "202d40"}[state]
			var border: String = {"normal": "4d657e", "hover": "c8ad7f", "pressed": "88d9e3", "disabled": "344253", "focus": "ffe4b3"}[state]
			var style: StyleBoxFlat = panel(fill, border)
			if state == "focus":
				style.bg_color = Color.TRANSPARENT
				style.set_border_width_all(2)
			theme.set_stylebox(state, type, style)
		for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			theme.set_color(key, type, Color("f2e7d4"))
		theme.set_color("font_disabled_color", type, Color("8593a5"))
	theme.set_stylebox("panel", "PanelContainer", panel("152233", "61758b", 16))
	theme.set_stylebox("panel", "PopupMenu", panel("152233", "61758b"))
	theme.set_stylebox("panel", "TooltipPanel", panel("101d2c", "8cd9df"))
	theme.set_color("font_color", "TooltipLabel", Color("f2e7d4"))
	theme.set_font_size("font_size", "TooltipLabel", 16)
	for type in ["TabContainer", "TabBar"]:
		theme.set_stylebox("tab_selected", type, panel("30445a", "c8ad7f", 8))
		theme.set_stylebox("tab_unselected", type, panel("172537", "34485f", 8))
		theme.set_stylebox("tab_hovered", type, panel("263c52", "88d9e3", 8))
		theme.set_color("font_selected_color", type, Color("ffe4b3"))
		theme.set_color("font_unselected_color", type, Color("afbed0"))
	return theme
