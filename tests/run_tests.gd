extends SceneTree
## Headless test runner:
##   godot --headless --path . -s res://tests/run_tests.gd
## Optional filter: append `-- <substring>` to run matching test files only.

const TEST_DIRS: Array[String] = ["res://tests/unit", "res://tests/scenario"]


## Counts script errors, so a test that dies on one fails instead of
## quietly passing the checks it never reached.
class ErrorCounter extends Logger:
	var count := 0
	var last := ""

	func _log_error(_function: String, _file: String, _line: int, code: String, rationale: String, _editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_SCRIPT:
			count += 1
			last = rationale if not rationale.is_empty() else code


func _initialize() -> void:
	var filter := ""
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		filter = args[0]
	var errors := ErrorCounter.new()
	OS.add_logger(errors)
	var total := 0
	var failed := 0
	for dir_path in TEST_DIRS:
		for file in _test_files(dir_path):
			if filter != "" and not file.contains(filter):
				continue
			var script := load(file) as GDScript
			if script == null or not script.can_instantiate():
				printerr("FAIL could not load %s" % file)
				failed += 1
				continue
			var suite: TestCase = script.new()
			for method in script.get_script_method_list():
				var method_name: String = method["name"]
				if not method_name.begins_with("test_"):
					continue
				total += 1
				var before := suite.failures.size()
				var errors_before := errors.count
				suite.begin("%s::%s" % [file.get_file(), method_name])
				suite.call(method_name)
				if errors.count > errors_before:
					suite.failures.append("%s::%s: script error: %s" % [file.get_file(), method_name, errors.last])
				if suite.failures.size() > before:
					failed += 1
					for i in range(before, suite.failures.size()):
						printerr("FAIL ", suite.failures[i])
				else:
					print("ok   %s::%s" % [file.get_file(), method_name])
	print("\n%d tests, %d failed" % [total, failed])
	quit(1 if failed > 0 else 0)


func _test_files(dir_path: String) -> PackedStringArray:
	var files := PackedStringArray()
	for file in DirAccess.get_files_at(dir_path):
		if file.begins_with("test_") and file.ends_with(".gd"):
			files.append(dir_path.path_join(file))
	files.sort()
	return files
