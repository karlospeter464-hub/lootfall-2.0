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
	"echo_scepter": {"name": "Echo Scepter", "slot": "scepter", "rarity": "magic"},
	"hunter_scepter": {"name": "Hunter's Scepter", "slot": "scepter", "rarity": "rare"},
	"storm_grimoire": {"name": "Storm Grimoire", "slot": "book", "rarity": "magic"},
	"phoenix_grimoire": {"name": "Phoenix Grimoire", "slot": "book", "rarity": "rare"},
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
		"cinder_codex": return "Fireball impacts deal splash damage to other nearby enemies.\nRadius: %.0f  |  Splash: %.0f%% of the fireball's damage.\nThe directly hit enemy takes only its normal hit." % [game.get("explosion_radius"), game.get("explosion_damage_ratio") * (1.35 if game.active_talents.has("power_15") else 1.0) * 100]
		"focus_grimoire": return "Your fireballs deal %.0f%% more direct damage.\nEquipping this book replaces the Codex: splash becomes inactive." % (game.get("focus_damage_bonus") * 100)
		"echo_scepter": return "Every fourth regular attack fires one central echo after %.2f s: %.0f%% normal shot damage.\nEcho can pierce and charge Overcharge; it never repeats itself or consumes a charge. No copied Overcharge bonus." % [game.get("echo_delay"), game.get("echo_damage_ratio") * (1.3 if game.active_talents.has("flow_10") else 1.0) * 100]
		"hunter_scepter": return "Repeated direct hits on each target gain +%.0f%% per additional hit, up to +%.0f%%.\nFirst hit has no bonus. Each target's streak expires after %.1f s without a direct hit. Bonus is direct-only." % [game.get("hunter_step") * 100, game.get("hunter_cap") * 100, game.get("hunter_duration")]
		"storm_grimoire": return "The first direct hit of each attack jumps lightning to the nearest other enemy: %.0f range, %.0f%% shot damage.\nOne attempt per attack, shared by fan, pierce and echo. Lightning is indirect and cannot chain or charge Overcharge." % [game.get("storm_radius") * (1.4 if game.active_talents.has("flow_12") else 1.0), game.get("storm_damage_ratio") * (1.25 if game.active_talents.has("flow_12") else 1.0) * 100]
		"phoenix_grimoire": return "Every 10 direct hits heal %.2f%% maximum HP. Minimum %.1f s between heals.\nHits during cooldown are not stored. Unequipping clears hits but preserves cooldown; restart clears both. Never heals past max HP." % [game.get("phoenix_heal_ratio") * (1.25 if game.active_talents.has("vitality_10") else 1.0) * 100, game.get("phoenix_cooldown")]
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
