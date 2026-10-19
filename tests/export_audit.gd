extends SceneTree

# Reads an already-exported PCK; this is not an executable-release gameplay test.
var checks: int = 0
var failures: int = 0

func check(condition: bool, message: String) -> void:
	checks += 1
	print("PASS: " if condition else "FAIL: ", message)
	if not condition:
		failures += 1

func collect_files(path: String) -> Array[String]:
	var paths: Array[String] = []
	var directory := DirAccess.open(path)
	if directory == null:
		return paths
	directory.include_hidden = true
	for file in directory.get_files():
		paths.append(path.path_join(file))
	for folder in directory.get_directories():
		paths.append_array(collect_files(path.path_join(folder)))
	return paths

func _initialize() -> void:
	var pack: String = ""
	var report: String = ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--pack="):
			pack = arg.trim_prefix("--pack=")
		if arg.begins_with("--report="):
			report = arg.trim_prefix("--report=")
	if pack.is_empty() or report.is_empty() or not pack.is_absolute_path() or not report.is_absolute_path():
		push_error("Supply absolute --pack and --report directory paths.")
		quit(1)
		return
	check(ProjectSettings.load_resource_pack(pack), "Exported PCK opens")
	var files: Array[String] = collect_files("res://")
	FileAccess.open(report.path_join("pack-files.txt"), FileAccess.WRITE).store_string("\n".join(files))
	check(not files.any(func(path): return path.begins_with("res://tests/") or path.begins_with("res://addons/") or path.contains(".godot/editor/") or path.contains("shader_cache/") or path.contains(".codex") or path.contains(".mcp.json") or path.contains("progress.json") or path.contains("balance_profile") or path.ends_with(".md")), "No tests, MCP addon, personal config, saves, editor caches or developer documents in PCK")
	check(ResourceLoader.exists("res://scenes/arena.tscn") and ResourceLoader.exists("res://scripts/item_catalog.gd"), "Main scene and item resources resolve from exported PCK")
	var config := FileAccess.open("res://project.binary", FileAccess.READ)
	check(config != null and config.get_buffer(4).get_string_from_ascii() == "ECFG", "Exported binary project settings are valid")
	var settings: Dictionary = {}
	for index in config.get_32():
		var key: String = config.get_buffer(config.get_32()).get_string_from_utf8()
		var value: PackedByteArray = config.get_buffer(config.get_32())
		if key in ["autoload/MCPRuntimeServer", "application/run/main_scene"]:
			settings[key] = bytes_to_var(value)
	check(not settings.get("autoload/MCPRuntimeServer", false), "MCP runtime autoload absent from exported settings")
	check(str(settings.get("application/run/main_scene", "")) == "res://scenes/arena.tscn", "Exported entry point is the real game")
	FileAccess.open(report.path_join("GODOT_LICENSES.txt"), FileAccess.WRITE).store_string(Engine.get_license_text() + "\n\nBundled third-party copyright notices:\n" + JSON.stringify(Engine.get_copyright_info(), "  ") + "\n\nLicense texts:\n" + JSON.stringify(Engine.get_license_info(), "  "))
	print("EXPORT AUDIT: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
