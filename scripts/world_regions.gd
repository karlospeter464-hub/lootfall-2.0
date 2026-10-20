extends RefCounted

const REGIONS := [
	{"name": "Ashen Fields", "cost": 600, "blight": "392c36", "healthy": "35493c", "water": "56685d", "accent": "e5b57c", "mood": "Ash gives way to living earth."},
	{"name": "Withered Grove", "cost": 1400, "blight": "262b37", "healthy": "253f3b", "water": "38564e", "accent": "9fc7ab", "mood": "Roots remember how to grow."},
	{"name": "Rotwater Marsh", "cost": 2800, "blight": "30342f", "healthy": "2b4447", "water": "457e86", "accent": "9ed9df", "mood": "Still waters become clear again."},
]
const LIMIT: int = 1000000000

static func fresh(legacy_best: int = 0) -> Dictionary:
	return {"points": [0, 0, 0], "best": [legacy_best, 0, 0], "overflow": 0}

static func frontier(world: Dictionary) -> int:
	for index in REGIONS.size():
		if world.points[index] < REGIONS[index].cost:
			return index
	return REGIONS.size() - 1

static func restored(world: Dictionary) -> int:
	var total: int = 0
	for index in REGIONS.size():
		if world.points[index] == REGIONS[index].cost:
			total += 1
	return total

static func fraction(world: Dictionary, region: int) -> float:
	return float(world.points[region]) / REGIONS[region].cost

static func reward(cleared: int, active_seconds: float, kills: int, hits: int) -> int:
	var count: int = clampi(cleared, 0, 100)
	if count > 0:
		return 2 * count * (count + 1)
	return 2 if active_seconds >= 30 and kills >= 3 and hits >= 3 else 0

static func apply(world: Dictionary, amount: int, region: int, reached: int) -> Dictionary:
	var next: Dictionary = world.duplicate(true)
	next.best[region] = maxi(next.best[region], reached)
	var left: int = amount
	for index in range(region, REGIONS.size()):
		var added: int = mini(left, REGIONS[index].cost - int(next.points[index]))
		next.points[index] += added
		left -= added
	next.overflow = int(next.overflow) + left
	return next

static func valid(world: Variant) -> bool:
	if not world is Dictionary or not world.get("points") is Array or not world.get("best") is Array:
		return false
	if world.points.size() != REGIONS.size() or world.best.size() != REGIONS.size() or not whole(world.get("overflow"), LIMIT):
		return false
	var unfinished: bool = false
	for index in REGIONS.size():
		if not whole(world.points[index], REGIONS[index].cost) or not whole(world.best[index], 100):
			return false
		if unfinished and (world.points[index] > 0 or world.best[index] > 0):
			return false
		unfinished = unfinished or world.points[index] < REGIONS[index].cost
	return world.overflow == 0 or restored(world) == REGIONS.size()

static func whole(value: Variant, maximum: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floorf(float(value)) and value >= 0 and value <= maximum
