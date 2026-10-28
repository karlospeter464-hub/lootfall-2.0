extends RefCounted

# Four schools are catalog entries only; their rescues and trees ship in later slices.
const FRIENDS := {
	"gravity": {"name": "Gravitation", "color": "b497ff", "ability": "Black Hole", "rescue": "shared_battle", "wave": 1},
	"prism": {"name": "Prisma", "color": "8ce9f7", "ability": "Light Beam", "rescue": "challenge", "wave": 2},
	"storm": {"name": "Storm", "rescue": "confrontation"},
	"nature": {"name": "Nature", "rescue": "shared_battle"},
	"inferno": {"name": "Inferno", "rescue": "challenge"},
	"soul": {"name": "Soul Echo", "rescue": "confrontation"}
}
const SPECIALS := {
	"gravity": [
		["radius", "Event Horizon", "Black Hole radius grows from 150 to 200."],
		["slow", "Heavy Embers", "Direct fireballs slow targets by 30% for 1.5 seconds."],
		["duration", "Lingering Void", "Black Hole lasts 5 seconds instead of 3.5."],
		["captured", "Crushing Flame", "Direct fireballs deal 25% more damage inside Black Hole."],
		["collapse", "Gravitational Collapse", "The closing field explodes for 3x base fireball damage."],
		["harvest", "Gathering Mass", "Each kill inside the field adds 15% collapse damage, capped at 150%. Requires Collapse for damage."]],
	"prism": [
		["width", "Radiance", "Beam width grows from 30 to 54."],
		["mark", "Spectral Embers", "Direct fireballs mark targets for 4 seconds."],
		["charge", "Quick Refraction", "Beam windup falls from 0.65 to 0.3 seconds."],
		["marked", "Focus Spectrum", "Marked targets take 40% more beam damage. Requires Spectral Embers to mark."],
		["split", "Prismatic Split", "The first beam hit emits two short 50% damage rays. No recursive splitting."],
		["kindle", "Light from Ash", "Direct fireball kills reduce the next beam windup by 0.1 seconds, up to 0.3. Minimum windup 0.15 seconds."]]
}

static func fresh(enabled: bool = true) -> Dictionary:
	return {"enabled": enabled, "rescued": [], "slots": ["", ""], "purchases": {}, "legacy_refund": 0}

static var tree_cache: Dictionary = {}

static func nodes(friend: String) -> Dictionary:
	if tree_cache.has(friend): return tree_cache[friend]
	var result := {}
	if not SPECIALS.has(friend): return result
	for branch in 3:
		var prefix: String = ["damage", "health", "speed"][branch]
		var previous: String = ""
		for tier in 5:
			var special: bool = tier in [1, 3]
			var index: int = branch * 2 + (1 if tier == 3 else 0)
			var part: String = SPECIALS[friend][index][0] if special else prefix + str(tier)
			var id: String = friend + "." + part
			var parents: Array = [] if tier == 0 else [previous]
			if tier == 2: parents.append(friend + "." + SPECIALS[friend][((branch + 2) % 3) * 2][0])
			result[id] = {"name": SPECIALS[friend][index][1] if special else ["Ember Power", "Vitality", "Cast Speed"][branch] + " " + str(tier + 1), "description": SPECIALS[friend][index][2] if special else ["+8% base damage (also companion damage).", "+10% maximum health.", "3% shorter fireball interval (additive; capped at 30% across both friends)."][branch], "cost": [10, 25, 50, 100, 180][tier], "parents": parents, "branch": branch, "tier": tier, "stat": "" if special else prefix}
			previous = id
	tree_cache[friend] = result
	return result

static func accessible(id: String, purchases: Dictionary) -> bool:
	var tree: Dictionary = nodes(id.get_slice(".", 0))
	if not tree.has(id) or purchases.has(id): return false
	if tree[id].parents.is_empty(): return true
	for parent in tree[id].parents:
		if purchases.has(parent): return true
	return false

static func snapshot(state: Dictionary) -> Dictionary:
	var result := {}
	if not state.enabled: return result
	for id in state.purchases:
		if id.get_slice(".", 0) in state.slots: result[id] = state.purchases[id]
	return result

static func bonuses(purchases: Dictionary) -> Dictionary:
	var result := {"damage": 0.0, "health": 0.0, "interval": 0.0}
	for id in purchases:
		var node: Dictionary = nodes(id.get_slice(".", 0))[id]
		match node.stat:
			"damage": result.damage += 0.08
			"health": result.health += 0.10
			"speed": result.interval += 0.03
	result.interval = minf(0.30, result.interval)
	return result

static func valid(state: Variant) -> bool:
	if not state is Dictionary or not state.get("enabled") is bool or not state.get("rescued") is Array or not state.get("slots") is Array or not state.get("purchases") is Dictionary: return false
	if state.slots.size() != 2 or state.rescued.size() > SPECIALS.size() or state.purchases.size() > 30: return false
	var seen := []
	for id in state.rescued:
		if not id is String or not SPECIALS.has(id) or id in seen: return false
		seen.append(id)
	if state.slots[0] != "" and state.slots[0] == state.slots[1]: return false
	for id in state.slots:
		if not id is String or (id != "" and id not in state.rescued): return false
	var refund: Variant = state.get("legacy_refund")
	if not (refund is int or refund is float) or not is_finite(float(refund)) or refund < 0 or refund > 1000000000 or refund != floorf(refund): return false
	var reached := {}
	for id in state.purchases:
		if not id is String or id.get_slice(".", 0) not in state.rescued: return false
		var tree: Dictionary = nodes(id.get_slice(".", 0))
		var price: Variant = state.purchases[id]
		if not tree.has(id) or not (price is int or price is float) or not is_finite(float(price)) or price < 1 or price > 1000000000 or price != floorf(price): return false
	for pass_index in 30:
		if reached.size() == state.purchases.size(): break
		for id in state.purchases:
			if accessible(id, reached): reached[id] = state.purchases[id]
	if reached.size() != state.purchases.size(): return false
	return state.enabled or (state.rescued.is_empty() and state.purchases.is_empty() and state.slots == ["", ""])
