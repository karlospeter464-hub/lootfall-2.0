extends RefCounted

const SAFE_JSON = preload("res://scripts/safe_json.gd")
const FRIENDS = preload("res://scripts/companion_catalog.gd")
const TREE = preload("res://scripts/skill_tree.gd")
const WORLD = preload("res://scripts/world_regions.gd")
const MAX_ECHOES: int = 1000000000
var path: String = "user://progress.json"
var echoes: int = 0
var best_wave: int = 0
var talents: Dictionary = {}
var companions: Dictionary = FRIENDS.fresh()
var world: Dictionary = WORLD.fresh()
var last_settlement: String = ""
var legacy_source: String = ""
var living_source: String = ""
var restoration_run: Dictionary = {"id": "", "region": 0, "credited": 0}
var echo_run: Dictionary = {"id": "", "earned": 0, "paid": 0}
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
		companions = FRIENDS.fresh()
		world = WORLD.fresh()
		last_settlement = ""
		legacy_source = ""
		living_source = ""
		restoration_run = {"id": "", "region": 0, "credited": 0}
		echo_run = {"id": "", "earned": 0, "paid": 0}
		return true
	return _load_from(path)

func _load_from(source: String) -> bool:
	var data: Dictionary = SAFE_JSON.read_object(source)
	if (data.get("version") != 1 and data.get("version") != 2 and data.get("version") != 3 and data.get("version") != 4 and data.get("version") != 5 and data.get("version") != 6) or not _whole(data.get("echoes"), MAX_ECHOES) or not _whole(data.get("best_wave"), 100):
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
	var loaded_world: Variant = data.get("world") if data.version >= 3 else WORLD.fresh(int(data.best_wave))
	var settlement: Variant = data.get("last_settlement") if data.version >= 3 else ""
	if not WORLD.valid(loaded_world) or not settlement is String or settlement.length() > 64:
		return _invalid()
	var loaded_run: Variant = data.get("restoration_run") if data.version >= 4 else {"id": "", "region": 0, "credited": 0}
	if not loaded_run is Dictionary or not loaded_run.get("id") is String or loaded_run.id.length() > 64 or not _whole(loaded_run.get("region"), WORLD.REGIONS.size() - 1) or not _whole(loaded_run.get("credited"), 20200):
		return _invalid()
	if loaded_run.id.is_empty() and loaded_run.credited != 0:
		return _invalid()
	var loaded_echo: Variant = data.get("echo_run") if data.version >= 5 else {"id": "", "earned": 0, "paid": 0}
	if not loaded_echo is Dictionary or not loaded_echo.get("id") is String or loaded_echo.id.length() > 64 or not _whole(loaded_echo.get("earned"), MAX_ECHOES) or not _whole(loaded_echo.get("paid"), MAX_ECHOES):
		return _invalid()
	if loaded_echo.paid > loaded_echo.earned or (loaded_echo.id.is_empty() and loaded_echo.earned != 0) or loaded_echo.earned - loaded_echo.paid > MAX_ECHOES - int(data.echoes) - refund:
		return _invalid()
	var loaded_friends: Variant = data.get("companions") if data.version >= 6 else FRIENDS.fresh(false)
	if not FRIENDS.valid(loaded_friends) or (loaded_friends.enabled and not loaded.is_empty()):
		return _invalid()
	var friend_investment: int = 0
	for price in loaded_friends.purchases.values(): friend_investment += int(price)
	if friend_investment > MAX_ECHOES - int(data.echoes) - refund - int(loaded_echo.earned) + int(loaded_echo.paid):
		return _invalid()
	companions = loaded_friends.duplicate(true)
	echo_run = {"id": loaded_echo.id, "earned": int(loaded_echo.earned), "paid": int(loaded_echo.paid)}
	restoration_run = {"id": loaded_run.id, "region": int(loaded_run.region), "credited": int(loaded_run.credited)}
	legacy_source = source if data.version < 3 else ""
	living_source = source if data.version < 5 else ""
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
	for price in companions.purchases.values(): total += int(price)
	return total

func record_echoes(total: int, id: String) -> bool:
	if not available or id.is_empty() or id.length() > 64 or id == last_settlement or total < 0 or total > MAX_ECHOES:
		return false
	var same: bool = echo_run.id == id
	if (same and total < echo_run.earned) or (not same and echo_run.earned > echo_run.paid):
		return false
	var paid: int = int(echo_run.paid) if same else 0
	if total - paid > MAX_ECHOES - echoes - invested():
		message = "Echo storage limit reached. Rewards remain pending."
		return false
	if same and total == echo_run.earned:
		return true
	return _save(echoes, best_wave, talents, {}, "", {}, {"id": id, "earned": total, "paid": paid})

func claim_echoes(total: int, id: String) -> bool:
	if not available or id != echo_run.id or total < echo_run.paid or total > echo_run.earned or total - int(echo_run.paid) > MAX_ECHOES - echoes - invested():
		return false
	if total == echo_run.paid:
		return true
	return _save(echoes + total - int(echo_run.paid), best_wave, talents, {}, "", {}, {"id": id, "earned": int(echo_run.earned), "paid": total})

func recover_echoes() -> bool:
	return available and (echo_run.earned == echo_run.paid or claim_echoes(int(echo_run.earned), str(echo_run.id)))

func debug_set_echoes(amount: int) -> bool:
	if not OS.is_debug_build() or not available or amount < 0 or amount > MAX_ECHOES - invested():
		message = "Test wallet unavailable or outside its safe range."
		return false
	return _save(amount, best_wave, talents)

func debug_advance(amount: int, reached: int, region: int, total: int, run_id: String) -> bool:
	return OS.is_debug_build() and _award_expedition(amount, reached, region, total, run_id, false)

func buy(id: String, price: int) -> bool:
	if companions.enabled or not available or price < 1 or price > echoes or not TREE.accessible(id, talents):
		message = "Purchase unavailable: check Echoes and connected prerequisites."
		return false
	var next: Dictionary = talents.duplicate()
	next[id] = price
	return _save(echoes - price, best_wave, next)

func refund_all() -> bool:
	if companions.enabled or not available or talents.is_empty():
		message = "No saved talents to refund, or progress is unavailable."
		return false
	return _save(echoes + invested(), best_wave, {})

func settle_expedition(amount: int, reached: int, region: int, restoration: int, run_id: String) -> bool:
	return _award_expedition(amount, reached, region, restoration, run_id, true)

func restore_during_run(total: int, reached: int, region: int, run_id: String) -> bool:
	return _award_expedition(0, reached, region, total, run_id, false)

func _award_expedition(amount: int, reached: int, region: int, total: int, run_id: String, final: bool) -> bool:
	if run_id == last_settlement and not run_id.is_empty():
		return final
	var continuing: bool = restoration_run.id == run_id and restoration_run.region == region
	var credited: int = int(restoration_run.credited) if continuing else 0
	if not available or amount < 0 or amount > MAX_ECHOES - echoes - invested() or reached < 0 or reached > 100 or (not continuing and region != WORLD.frontier(world)) or total < credited or total > 20200 or run_id.is_empty() or run_id.length() > 64:
		message = "Expedition reward unavailable. Progress preserved."
		return false
	var next: Dictionary = WORLD.apply(world, total - credited, region, reached)
	if not WORLD.valid(next):
		message = "World storage limit reached. Reward not discarded; save remains unchanged."
		return false
	var next_run := {"id": run_id, "region": region, "credited": total}
	return _save(echoes + amount, maxi(best_wave, reached), talents, next, run_id if final else "", next_run)

func _save(next_echoes: int, next_best: int, next_talents: Dictionary, next_world: Dictionary = {}, settlement: String = "", next_run: Dictionary = {}, next_echo: Dictionary = {}, next_friends: Dictionary = {}) -> bool:
	var saved_friends: Dictionary = companions if next_friends.is_empty() else next_friends
	if not FRIENDS.valid(saved_friends) or (saved_friends.enabled and not next_talents.is_empty()): return false
	var saved_world: Dictionary = world if next_world.is_empty() else next_world
	var saved_id: String = last_settlement if settlement.is_empty() else settlement
	var saved_run: Dictionary = restoration_run if next_run.is_empty() else next_run
	var saved_echo: Dictionary = echo_run if next_echo.is_empty() else next_echo
	var reserved: int = int(saved_echo.earned) - int(saved_echo.paid)
	for price in next_talents.values(): reserved += int(price)
	for price in saved_friends.purchases.values(): reserved += int(price)
	if next_echoes < 0 or next_echoes > MAX_ECHOES - reserved:
		message = "Echo storage limit reached. Pending rewards preserved."
		return false
	var data := {"version": 6, "companions": saved_friends, "echoes": next_echoes, "best_wave": next_best, "talents": next_talents, "world": saved_world, "last_settlement": saved_id, "restoration_run": saved_run, "echo_run": saved_echo}
	if not saved_friends.enabled:
		data.version = 5
		data.erase("companions")
	if not living_source.is_empty() and not FileAccess.file_exists(path + ".pre_living.json"):
		var original: Dictionary = SAFE_JSON.read_object(living_source)
		if original.is_empty() or SAFE_JSON.write_object(path + ".pre_living.json", original) != OK:
			message = "Migration backup could not be saved. Original preserved."
			return false
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
	companions = saved_friends.duplicate(true)
	world = saved_world.duplicate(true)
	last_settlement = saved_id
	restoration_run = saved_run.duplicate()
	echo_run = saved_echo.duplicate()
	legacy_source = ""
	living_source = ""
	message = ""
	return true

func _whole(value: Variant, maximum: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floorf(float(value)) and float(value) >= 0 and float(value) <= maximum

func migrate_companions() -> bool:
	if not available or companions.enabled: return false
	# Copy bytes before the first conversion; never mutate an old save while reading it.
	var source: String = path if FileAccess.file_exists(path) else path + ".bak"
	if FileAccess.file_exists(source):
		var backup_path: String = path + ".pre_companions.json"
		var original: PackedByteArray = FileAccess.get_file_as_bytes(source)
		# A previous failed conversion may have left a backup of an older valid save.
		if FileAccess.file_exists(backup_path) and FileAccess.get_file_as_bytes(backup_path) != original:
			backup_path = path + ".pre_companions_%d.json" % Time.get_ticks_usec()
		if not FileAccess.file_exists(backup_path):
			var backup := FileAccess.open(backup_path, FileAccess.WRITE)
			if backup == null:
				message = "Companion backup could not be written. Original preserved."
				return false
			backup.store_buffer(original)
			backup.flush()
			var error: Error = backup.get_error()
			backup.close()
			if error != OK or FileAccess.get_file_as_bytes(backup_path) != original:
				message = "Companion backup verification failed. Original preserved."
				return false
	var next: Dictionary = FRIENDS.fresh()
	next.legacy_refund = invested()
	return _save(echoes + invested(), best_wave, {}, {}, "", {}, {}, next)

func rescue_companion(id: String) -> bool:
	if not available or not companions.enabled or not FRIENDS.SPECIALS.has(id): return false
	if id in companions.rescued: return true
	var next: Dictionary = companions.duplicate(true)
	next.rescued.append(id)
	for index in 2:
		if next.slots[index] == "":
			next.slots[index] = id
			break
	return _save(echoes, best_wave, talents, {}, "", {}, {}, next)

func equip_companions(slots: Array) -> bool:
	var next: Dictionary = companions.duplicate(true)
	next.slots = slots.duplicate()
	return available and companions.enabled and FRIENDS.valid(next) and _save(echoes, best_wave, talents, {}, "", {}, {}, next)

func buy_companion(id: String) -> bool:
	var tree: Dictionary = FRIENDS.nodes(id.get_slice(".", 0))
	if not available or not companions.enabled or id.get_slice(".", 0) not in companions.rescued or not FRIENDS.accessible(id, companions.purchases) or not tree.has(id):
		message = "Rescue this friend and learn a connected predecessor first."
		return false
	var price: int = tree[id].cost
	if price > echoes:
		message = "Not enough Echoes."
		return false
	var next: Dictionary = companions.duplicate(true)
	next.purchases[id] = price
	return _save(echoes - price, best_wave, talents, {}, "", {}, {}, next)
