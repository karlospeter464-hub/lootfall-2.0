extends RefCounted

const SAFE_JSON = preload("res://scripts/safe_json.gd")
const MAX_ECHOES: int = 1000000000
var path: String = "user://progress.json"
var echoes: int = 0
var best_wave: int = 0
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
		return true
	return _load_from(path)

func _load_from(source: String) -> bool:
	var data: Dictionary = SAFE_JSON.read_object(source)
	if data.get("version") != 1 or not _whole(data.get("echoes"), MAX_ECHOES) or not _whole(data.get("best_wave"), 100):
		available = false
		message = "Progress file is invalid. Original preserved; no rewards will overwrite it."
		return false
	echoes = int(data.echoes)
	best_wave = int(data.best_wave)
	return true

func award(amount: int, reached_wave: int) -> bool:
	if not available or amount < 0 or amount > MAX_ECHOES - echoes or reached_wave < 0 or reached_wave > 100:
		message = "Reward could not be saved. Check the progress file or storage."
		return false
	var data := {"version": 1, "echoes": echoes + amount, "best_wave": maxi(best_wave, reached_wave)}
	var error: Error = SAFE_JSON.write_object(path, data)
	if error != OK:
		message = "Reward not saved: %s. Retry before starting another run." % error_string(error)
		return false
	echoes += amount
	best_wave = int(data.best_wave)
	message = ""
	return true

func _whole(value: Variant, maximum: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floorf(float(value)) and float(value) >= 0 and float(value) <= maximum
