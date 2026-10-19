extends RefCounted

# Cross-links join the third small node to the previous tier of a neighboring path.
const NODES := {
	"power_1": {"name": "Kindling", "branch": "Power", "tier": 1, "parents": []},
	"power_2": {"name": "Kindle II", "branch": "Power", "tier": 2, "parents": ["power_1"]},
	"power_3": {"name": "Kindle III", "branch": "Power", "tier": 3, "parents": ["power_2", "flow_2"]},
	"power_4": {"name": "Burning Purpose", "branch": "Power", "tier": 4, "parents": ["power_3"]},
	"power_5": {"name": "First Spark", "branch": "Power", "tier": 5, "parents": ["power_4"]},
	"vitality_1": {"name": "Emberguard", "branch": "Vitality", "tier": 1, "parents": []},
	"vitality_2": {"name": "Endure II", "branch": "Vitality", "tier": 2, "parents": ["vitality_1"]},
	"vitality_3": {"name": "Endure III", "branch": "Vitality", "tier": 3, "parents": ["vitality_2", "power_2"]},
	"vitality_4": {"name": "Deep Roots", "branch": "Vitality", "tier": 4, "parents": ["vitality_3"]},
	"vitality_5": {"name": "Renewal", "branch": "Vitality", "tier": 5, "parents": ["vitality_4"]},
	"flow_1": {"name": "Arcane Momentum", "branch": "Flow", "tier": 1, "parents": []},
	"flow_2": {"name": "Rhythm II", "branch": "Flow", "tier": 2, "parents": ["flow_1"]},
	"flow_3": {"name": "Rhythm III", "branch": "Flow", "tier": 3, "parents": ["flow_2", "vitality_2"]},
	"flow_4": {"name": "Unbroken Rhythm", "branch": "Flow", "tier": 4, "parents": ["flow_3"]},
	"flow_5": {"name": "Second Wind", "branch": "Flow", "tier": 5, "parents": ["flow_4"]},
}
const COLORS := {"Power": "df9b68", "Vitality": "86bb94", "Flow": "84b8db"}

static func accessible(id: String, owned: Dictionary) -> bool:
	if not NODES.has(id) or owned.has(id):
		return false
	var parents: Array = NODES[id].parents
	if parents.is_empty():
		return true
	for parent in parents:
		if owned.has(parent):
			return true
	return false

static func bonuses(owned: Dictionary, game: Object) -> Dictionary:
	var result := {"damage": 0.0, "health": 0.0, "interval": 0.0, "opening": 0.0, "healing": 0.0, "haste": 0.0}
	for id in owned:
		var node: Dictionary = NODES[id]
		if node.tier == 1 or node.tier == 5:
			continue
		var notable: bool = node.tier == 4
		match node.branch:
			"Power": result.damage += game.get("tree_power_notable" if notable else "tree_power_step")
			"Vitality": result.health += game.get("tree_health_notable" if notable else "tree_health_step")
			"Flow": result.interval += game.get("tree_flow_notable" if notable else "tree_flow_step")
	if owned.has("power_5"):
		result.opening = game.get("tree_opening_bonus")
	if owned.has("vitality_5"):
		result.healing = game.get("tree_wave_heal")
	if owned.has("flow_5"):
		result.haste = game.get("tree_hurt_haste")
	return result

static func description(id: String, game: Object) -> String:
	var node: Dictionary = NODES[id]
	match id:
		"power_1": return "After a kill, your next central fireball within %.1fs deals +%.0f%% direct damage. One shot; kills refresh readiness. No bonus to fan side shots, Echo or splash." % [game.get("tree_kindling_duration"), game.get("tree_kindling_bonus") * 100]
		"vitality_1": return "Your first nonlethal enemy hit each wave restores %.0f%% maximum health. Once per wave, capped at full HP. Cannot revive you." % (game.get("tree_emberguard_heal") * 100)
		"flow_1": return "Every 4 direct projectile hits grant +%.0f%% movement speed for %.1fs. Fan and piercing hits count; splash does not. Refreshes without stacking." % [game.get("tree_momentum_bonus") * 100, game.get("tree_momentum_duration")]
	if node.tier == 5:
		match node.branch:
			"Power": return "Direct hits deal %.0f%% more damage to enemies at full health. Splash keeps its normal damage." % (game.get("tree_opening_bonus") * 100)
			"Vitality": return "Clearing a wave restores %.0f%% of your maximum health, once per wave. Cannot exceed full health." % (game.get("tree_wave_heal") * 100)
			"Flow": return "After losing health, your attack interval is %.0f%% shorter for %.1fs. Further hits refresh the duration; it never stacks." % [game.get("tree_hurt_haste") * 100, game.get("tree_haste_duration")]
	var notable: bool = node.tier == 4
	match node.branch:
		"Power": return "+%.0f%% base attack damage. Adds to other Power nodes, then multiplies with wave cards and gear." % (game.get("tree_power_notable" if notable else "tree_power_step") * 100)
		"Vitality": return "+%.0f%% maximum health. Adds to other Vitality nodes. Starts each run at full health." % (game.get("tree_health_notable" if notable else "tree_health_step") * 100)
		"Flow": return "%.0f%% shorter attack interval. Adds to other Flow nodes; the combined reduction is capped at 60%%. Multiplies with cards and gear." % (game.get("tree_flow_notable" if notable else "tree_flow_step") * 100)
	return ""
