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
	"power_6": {"name": "Embercraft VI", "branch": "Power", "tier": 6, "parents": ['power_5'], "special": false},
	"power_7": {"name": "Embercraft VII", "branch": "Power", "tier": 7, "parents": ['power_6', 'flow_6'], "special": false},
	"power_8": {"name": "Cinder Memory", "branch": "Power", "tier": 8, "parents": ['power_7'], "special": true},
	"power_9": {"name": "Embercraft IX", "branch": "Power", "tier": 9, "parents": ['power_8'], "special": false},
	"power_10": {"name": "Giant Slayer", "branch": "Power", "tier": 10, "parents": ['power_9'], "special": true},
	"power_11": {"name": "Embercraft XI", "branch": "Power", "tier": 11, "parents": ['power_10', 'flow_10'], "special": false},
	"power_12": {"name": "Convergence", "branch": "Power", "tier": 12, "parents": ['power_11'], "special": true},
	"power_13": {"name": "Embercraft XIII", "branch": "Power", "tier": 13, "parents": ['power_12'], "special": false},
	"power_14": {"name": "Embercraft XIV", "branch": "Power", "tier": 14, "parents": ['power_13'], "special": false},
	"power_15": {"name": "Wildfire", "branch": "Power", "tier": 15, "parents": ['power_14'], "special": true},
	"vitality_6": {"name": "Heartwood VI", "branch": "Vitality", "tier": 6, "parents": ['vitality_5'], "special": false},
	"vitality_7": {"name": "Heartwood VII", "branch": "Vitality", "tier": 7, "parents": ['vitality_6', 'power_6'], "special": false},
	"vitality_8": {"name": "Bulwark", "branch": "Vitality", "tier": 8, "parents": ['vitality_7'], "special": true},
	"vitality_9": {"name": "Heartwood IX", "branch": "Vitality", "tier": 9, "parents": ['vitality_8'], "special": false},
	"vitality_10": {"name": "Living Spring", "branch": "Vitality", "tier": 10, "parents": ['vitality_9'], "special": true},
	"vitality_11": {"name": "Heartwood XI", "branch": "Vitality", "tier": 11, "parents": ['vitality_10', 'power_10'], "special": false},
	"vitality_12": {"name": "Warden Skin", "branch": "Vitality", "tier": 12, "parents": ['vitality_11'], "special": true},
	"vitality_13": {"name": "Heartwood XIII", "branch": "Vitality", "tier": 13, "parents": ['vitality_12'], "special": false},
	"vitality_14": {"name": "Heartwood XIV", "branch": "Vitality", "tier": 14, "parents": ['vitality_13'], "special": false},
	"vitality_15": {"name": "Last Light", "branch": "Vitality", "tier": 15, "parents": ['vitality_14'], "special": true},
	"flow_6": {"name": "Attunement VI", "branch": "Flow", "tier": 6, "parents": ['flow_5'], "special": false},
	"flow_7": {"name": "Attunement VII", "branch": "Flow", "tier": 7, "parents": ['flow_6', 'vitality_6'], "special": false},
	"flow_8": {"name": "Afterglow", "branch": "Flow", "tier": 8, "parents": ['flow_7'], "special": true},
	"flow_9": {"name": "Attunement IX", "branch": "Flow", "tier": 9, "parents": ['flow_8'], "special": false},
	"flow_10": {"name": "Resonant Echo", "branch": "Flow", "tier": 10, "parents": ['flow_9'], "special": true},
	"flow_11": {"name": "Attunement XI", "branch": "Flow", "tier": 11, "parents": ['flow_10', 'vitality_10'], "special": false},
	"flow_12": {"name": "Chain Current", "branch": "Flow", "tier": 12, "parents": ['flow_11'], "special": true},
	"flow_13": {"name": "Attunement XIII", "branch": "Flow", "tier": 13, "parents": ['flow_12'], "special": false},
	"flow_14": {"name": "Attunement XIV", "branch": "Flow", "tier": 14, "parents": ['flow_13'], "special": false},
	"flow_15": {"name": "Unbound", "branch": "Flow", "tier": 15, "parents": ['flow_14'], "special": true},
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
		if node.tier > 5:
			if not node.get("special", false):
				match node.branch:
					"Power": result.damage += 0.12
					"Vitality": result.health += 0.15
					"Flow": result.interval += 0.04
			continue
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
	result.heal_multiplier = 1.25 if owned.has("vitality_10") else 1.0
	result.area_multiplier = 1.35 if owned.has("power_15") else 1.0
	return result

static func description(id: String, game: Object) -> String:
	var node: Dictionary = NODES[id]
	if node.tier > 5:
		var effects := {
			"power_8": "Kindling gains +25 percentage points of direct damage. Kills still ready one central shot.",
			"power_10": "Direct projectiles deal 25% more damage to bosses. Includes actual Echo hits.",
			"power_12": "Gain 6% base damage for each distinct mechanic card: Burst, Pierce, Overcharge (up to 18%). No starting cards.",
			"power_15": "Wildfire: Burst and Codex area damage deal 35% more damage. No new explosions or chain reactions.",
			"vitality_8": "After actual damage, gain 0.2 additional seconds of hit protection.",
			"vitality_10": "All wave, Emberguard and Phoenix healing is 25% stronger. Cannot exceed maximum health.",
			"vitality_12": "Take 12% less incoming enemy damage. Does not change enemy values.",
			"vitality_15": "Once per run, a lethal hit leaves you at 1 HP and grants 2 seconds of protection. New runs restore this safeguard.",
			"flow_8": "Arcane Momentum lasts 2 additional seconds; its four-hit requirement is unchanged.",
			"flow_10": "Echo Scepter's repeated central projectile deals 30% more direct damage. It still triggers every fourth attack.",
			"flow_12": "Storm Grimoire gains 40% lightning reach and 25% lightning damage. Still at most one attempt per attack.",
			"flow_15": "While Arcane Momentum is active, your casting interval is 12% shorter. Refreshes without stacking."
		}
		if effects.has(id):
			return effects[id]
		return {"Power": "+12% base damage, additive with permanent Power and multiplied with cards/gear.", "Vitality": "+15% maximum health. Starts each run full.", "Flow": "4% shorter casting interval. Additive permanent reduction, capped at 60%."}[node.branch]
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
