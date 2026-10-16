extends RefCounted

static func read_object(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() > 1048576:
		return {}
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		return {}
	var value: Variant = parser.data
	return value if value is Dictionary else {}

static func write_object(path: String, data: Dictionary) -> Error:
	var temporary: String = path + ".tmp"
	var backup: String = path + ".bak"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	var payload: String = JSON.stringify(data, "\t", true, true)
	file.store_string(payload)
	file.flush()
	var error: Error = file.get_error()
	file.close()
	if error != OK:
		return error
	# JSON reads integer tokens as floats; compare parsed values on both sides.
	if read_object(temporary) != JSON.parse_string(payload):
		return ERR_FILE_CORRUPT
	if FileAccess.file_exists(path):
		if FileAccess.file_exists(backup):
			error = DirAccess.remove_absolute(backup)
			if error != OK:
				return error
		error = DirAccess.rename_absolute(path, backup)
		if error != OK:
			return error
	error = DirAccess.rename_absolute(temporary, path)
	if error != OK and FileAccess.file_exists(backup):
		DirAccess.rename_absolute(backup, path)
	return error
