extends RefCounted

const RARITIES := {
	"legendary": {"name": "Legendary", "color": "efa75c"},
	"rare": {"name": "Rare", "color": "d8bf69"},
	"magic": {"name": "Magic", "color": "79a9ec"},
	"normal": {"name": "Normal", "color": "cbd0d6"},
}
const ITEMS := {
	"ember_scepter": {"name": "Ember Scepter", "slot": "scepter", "rarity": "normal"},
	"swift_scepter": {"name": "Swift Scepter", "slot": "scepter", "rarity": "magic"},
	"cinder_codex": {"name": "Cinder Codex", "slot": "book", "rarity": "legendary"},
	"focus_grimoire": {"name": "Focus Grimoire", "slot": "book", "rarity": "rare"},
}
static var icons: Dictionary = {}

static func color(id: String) -> Color:
	return Color(RARITIES[ITEMS[id].rarity].color)

static func label(id: String) -> String:
	return RARITIES[ITEMS[id].rarity].name

static func roll_item(random, legendary: float, rare: float, magic: float, codex_available: bool) -> String:
	var chances := {"legendary": legendary, "rare": rare, "magic": magic, "normal": 1.0}
	for rarity in RARITIES:
		if rarity != "normal" and random.randf() >= chances[rarity] and chances[rarity] < 1.0:
			continue
		var pool: Array[String] = []
		for id in ITEMS:
			if ITEMS[id].rarity == rarity and (id != "cinder_codex" or codex_available):
				pool.append(id)
		if not pool.is_empty():
			return pool[random.randi_range(0, pool.size() - 1)]
	return ""

static func description(id: String, game: Object) -> String:
	match id:
		"ember_scepter": return "Your fireballs deal %.0f%% more direct damage.\nA heavier hit for each cast." % (game.get("scepter_damage_bonus") * 100)
		"swift_scepter": return "Your casting interval is %.0f%% shorter.\nMore frequent shots, with unchanged damage per shot." % (game.get("scepter_cast_reduction") * 100)
		"cinder_codex": return "Fireball impacts deal splash damage to other nearby enemies.\nRadius: %.0f  |  Splash: %.0f%% of the fireball's damage.\nThe directly hit enemy takes only its normal hit." % [game.get("explosion_radius"), game.get("explosion_damage_ratio") * 100]
		"focus_grimoire": return "Your fireballs deal %.0f%% more direct damage.\nEquipping this book replaces the Codex: splash becomes inactive." % (game.get("focus_damage_bonus") * 100)
	return ""

static func icon(id: String) -> Texture2D:
	if not ITEMS.has(id):
		return null
	if not icons.has(id):
		var color: String = RARITIES[ITEMS[id].rarity].color
		var shape: String
		if ITEMS[id].slot == "scepter":
			shape = '<path d="M12 28 L22 11" stroke="#b7a084" stroke-width="4"/><path d="M23 3 L29 10 L23 17 L17 10 Z" fill="#%s"/><path d="M23 6 L26 10 L23 12 L20 10 Z" fill="#fff2cc"/>' % color
		else:
			shape = '<rect x="6" y="4" width="22" height="26" rx="2" fill="#%s"/><path d="M10 5 V29" stroke="#ffe4b3" stroke-width="2"/><rect x="13" y="9" width="11" height="15" fill="#453b4b"/><path d="M16 14 H21 M16 18 H21" stroke="#%s" stroke-width="2"/>' % [color, color]
		var image := Image.new()
		var error: Error = image.load_svg_from_string('<svg xmlns="http://www.w3.org/2000/svg" width="36" height="36">%s</svg>' % shape)
		assert(error == OK, "Built-in item icon must be valid SVG")
		icons[id] = ImageTexture.create_from_image(image)
	return icons[id]
