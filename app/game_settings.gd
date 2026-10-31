class_name GameSettings
extends RefCounted
## The player's settings, kept in user://settings.cfg between launches and
## applied to the window, the audio buses and the match view.
## Display: full screen (the default), vsync. Audio: master, effects and
## crowd volume, mute. Gameplay: rookie assist, reduced camera shake,
## reduced flashes (06_UI_UX.md's accessibility list).

const PATH := "user://settings.cfg"
const DEFAULTS := {
	"fullscreen": true, "vsync": true,
	"master": 0.8, "effects": 0.9, "crowd": 0.8, "muted": false,
	"rookie_assist": false, "reduce_shake": false, "reduce_flashes": false,
}
## Audio buses made at start-up (the project ships only Master).
const BUSES := [&"Effects", &"Crowd"]

static var values := DEFAULTS.duplicate()


static func load_saved() -> void:
	values = DEFAULTS.duplicate()
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	for key: String in DEFAULTS:
		values[key] = cfg.get_value("settings", key, DEFAULTS[key])


static func save() -> void:
	var cfg := ConfigFile.new()
	for key: String in values:
		cfg.set_value("settings", key, values[key])
	cfg.save(PATH)


static func get_value(key: String) -> Variant:
	return values.get(key, DEFAULTS.get(key))


## Sets one value, saves, and applies it.
static func set_value(key: String, value: Variant) -> void:
	values[key] = value
	save()
	apply()


static func apply() -> void:
	ensure_buses()
	if DisplayServer.get_name() != "headless":
		var full := bool(get_value("fullscreen"))
		var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if full else DisplayServer.WINDOW_MODE_WINDOWED
		if DisplayServer.window_get_mode() != mode:
			DisplayServer.window_set_mode(mode)
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if bool(get_value("vsync")) else DisplayServer.VSYNC_DISABLED)
	var muted := bool(get_value("muted"))
	_volume(&"Master", float(get_value("master")), muted)
	_volume(&"Effects", float(get_value("effects")), false)
	_volume(&"Crowd", float(get_value("crowd")), false)


static func ensure_buses() -> void:
	for name: StringName in BUSES:
		if AudioServer.get_bus_index(name) < 0:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, name)
			AudioServer.set_bus_send(i, &"Master")


static func _volume(bus: StringName, level: float, muted: bool) -> void:
	var i := AudioServer.get_bus_index(bus)
	if i < 0:
		return
	AudioServer.set_bus_volume_db(i, linear_to_db(maxf(level, 0.0001)))
	AudioServer.set_bus_mute(i, muted or level <= 0.001)


static func toggle_fullscreen() -> void:
	set_value("fullscreen", not bool(get_value("fullscreen")))
