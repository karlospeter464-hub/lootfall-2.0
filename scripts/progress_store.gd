extends RefCounted

const SAFE_JSON = preload("res://scripts/safe_json.gd")
const TREE = preload("res://scripts/skill_tree.gd")
const WORLD = preload("res://scripts/world_regions.gd")
const MAX_ECHOES: int = 1000000000
var path: String = "user://progress.json"
var echoes: int = 0
var best_wave: int = 0
var talents: Dictionary = {}
var world: Dictionary = WORLD.fresh()
var last_settlement: String = ""
var legacy_source: String = ""
var available: bool = true
var message: String = ""

func load_progress() -> bool:
	available = true
	message = ""
	if not FileAccess.file_exists(path):
		# Recover a validated backup if a process stopped between the two renames.
		if FileAccess.file_exists(path + ".bak"):
			return _load_from(path + ".bak")
		echoes = 0
		best_wave = 0
		talents = {}
		world = WORLD.fresh()
		last_settlement = ""
		legacy_source = ""
		return true
	return _load_from(path)

func _load_from(source: String) -> bool:
	var data: Dictionary = SAFE_JSON.read_object(source)
	if (data.get("version") != 1 and data.get("version") != 2 and data.get("version") != 3) or not _whole(data.get("echoes"), MAX_ECHOES) or not _whole(data.get("best_wave"), 100):
		return _invalid()
	var loaded: Variant = {} if data.version == 1 else data.get("talents")
	if not loaded is Dictionary or loaded.size() > TREE.NODES.size():
		return _invalid()
	var refund: int = 0
	for id in loaded:
		if not TREE.NODES.has(id) or not _whole(loaded[id], MAX_ECHOES) or loaded[id] < 1:
			return _invalid()
		refund += int(loaded[id])
		var rest: Dictionary = loaded.duplicate()
		rest.erase(id)
		if not TREE.accessible(id, rest):
			return _invalid()
	if refund > MAX_ECHOES - int(data.echoes):
		return _invalid()
	var loaded_world: Variant = data.get("world") if data.version == 3 else WORLD.fresh(int(data.best_wave))
	var settlement: Variant = data.get("last_settlement") if data.version == 3 else ""
	if not WORLD.valid(loaded_world) or not settlement is String or settlement.length() > 64:
		return _invalid()
	legacy_source = source if data.version != 3 else ""
	world = loaded_world.duplicate(true)
	for index in WORLD.REGIONS.size():
		world.points[index] = int(world.points[index])
		world.best[index] = int(world.best[index])
	world.overflow = int(world.overflow)
	last_settlement = settlement
	echoes = int(data.echoes)
	best_wave = int(data.best_wave)
	talents = loaded.duplicate()
	return true

func _invalid() -> bool:
	available = false
	message = "Progress file is invalid. Original preserved; no purchases or rewards will overwrite it."
	return false

func award(amount: int, reached_wave: int) -> bool:
	if not available or amount < 0 or amount > MAX_ECHOES - echoes - invested() or reached_wave < 0 or reached_wave > 100:
		message = "Reward could not be saved. Check the progress file or storage."
		return false
	return _save(echoes + amount, maxi(best_wave, reached_wave), talents)

func invested() -> int:
	var total: int = 0
	for price in talents.values():
		total += int(price)
	return total

func buy(id: String, price: int) -> bool:
	if not available or price < 1 or price > echoes or not TREE.accessible(id, talents):
		message = "Purchase unavailable: check Echoes and connected prerequisites."
		return false
	var next: Dictionary = talents.duplicate()
	next[id] = price
	return _save(echoes - price, best_wave, next)

func refund_all() -> bool:
	if not available or talents.is_empty():
		message = "No saved talents to refund, or progress is unavailable."
		return false
	return _save(echoes + invested(), best_wave, {})

func settle_expedition(amount: int, reached: int, region: int, restoration: int, run_id: String) -> bool:
	if run_id == last_settlement and not run_id.is_empty():
		return true
	if not available or amount < 0 or amount > MAX_ECHOES - echoes - invested() or reached < 0 or reached > 100 or region != WORLD.frontier(world) or restoration < 0 or restoration > 20200 or run_id.is_empty() or run_id.length() > 64:
		message = "Expedition reward unavailable. Progress preserved."
		return false
	var next: Dictionary = WORLD.apply(world, restoration, region, reached)
	if not WORLD.valid(next):
		message = "World storage limit reached. Reward not discarded; save remains unchanged."
		return false
	return _save(echoes + amount, maxi(best_wave, reached), talents, next, run_id)

func _save(next_echoes: int, next_best: int, next_talents: Dictionary, next_world: Dictionary = {}, settlement: String = "") -> bool:
	var saved_world: Dictionary = world if next_world.is_empty() else next_world
	var saved_id: String = last_settlement if settlement.is_empty() else settlement
	var data := {"version": 3, "echoes": next_echoes, "best_wave": next_best, "talents": next_talents, "world": saved_world, "last_settlement": saved_id}
	if not legacy_source.is_empty() and not FileAccess.file_exists(path + ".pre_world.json"):
		var original: PackedByteArray = FileAccess.get_file_as_bytes(legacy_source)
		var backup := FileAccess.open(path + ".pre_world.json.tmp", FileAccess.WRITE)
		if backup == null:
			message = "Migration backup could not be written. Original preserved."
			return false
		backup.store_buffer(original)
		backup.flush()
		var backup_error: Error = backup.get_error()
		backup.close()
		if backup_error != OK or FileAccess.get_file_as_bytes(path + ".pre_world.json.tmp") != original:
			message = "Migration backup could not be verified. Original preserved."
			return false
		if DirAccess.rename_absolute(path + ".pre_world.json.tmp", path + ".pre_world.json") != OK:
			message = "Migration backup could not be finalized. Original preserved."
			return false
	var error: Error = SAFE_JSON.write_object(path, data)
	if error != OK:
		message = "Progress not saved: %s. Nothing changed; retry the action." % error_string(error)
		return false
	echoes = next_echoes
	best_wave = next_best
	talents = next_talents.duplicate()
	world = saved_world.duplicate(true)
	last_settlement = saved_id
	legacy_source = ""
	message = ""
	return true

func _whole(value: Variant, maximum: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floorf(float(value)) and float(value) >= 0 and float(value) <= maximum
