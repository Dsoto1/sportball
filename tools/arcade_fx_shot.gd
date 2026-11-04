extends SceneTree
## Stills of the arcade effects, driven straight through the match view
## and HUD (the match loop is paused once the first batter is set):
##   godot --path . --resolution 1600x900 -s res://tools/arcade_fx_shot.gd -- <out_dir> [trails] [k] [flames]
## trails: every pitch family's trail mid-flight, from the batter's view
##         (`<family>_bat.png`) and over the pitcher's shoulder (`_pitch.png`);
## k:      the strikeout stamp swinging and looking, through its slam;
## flames: the batter's bat on fire (2 and 3 straight hits), from the
##         pitcher's view and the batter's, and mid-swing.
## With no kind given, all three.

var _out := ""
var _kinds: Array = []
var _director: Node
var _frames := 0
var _queue: Array = []  # [frames to wait, Callable]
var _wait := 0
var _ready_at := -1


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0]
	DirAccess.make_dir_recursive_absolute(_out)
	for k in ["trails", "k", "flames"]:
		if args.has(k):
			_kinds.append(k)
	if _kinds.is_empty():
		_kinds = ["trails", "k", "flames"]
	root.add_child(load("res://app/main.tscn").instantiate())


func _process(_d: float) -> bool:
	_frames += 1
	if _director == null:
		_director = root.get_node_or_null("Main/MatchDirector")
		return false
	if _ready_at < 0:
		if _frames == 20:
			var press := InputEventAction.new()
			press.action = &"swing_contact"
			press.pressed = true
			Input.parse_input_event(press)
		if _frames == 23:
			var release := InputEventAction.new()
			release.action = &"swing_contact"
			release.pressed = false
			Input.parse_input_event(release)
		if _frames > 30 and _director.state != null and _director.current_phase() == MatchDirector.Phase.PRE_PITCH and not _director._view.batter_busy():
			_ready_at = _frames
			_director.set_process(false)
			_director._hud.show_callout("", "", 0.0)
			_director._hud.show_prompt("")
			_plan()
		return false
	if _wait > 0:
		_wait -= 1
		return false
	if _queue.is_empty():
		return true
	var step: Array = _queue.pop_front()
	_wait = step[0]
	(step[1] as Callable).call()
	return false


func _then(frames: int, what: Callable) -> void:
	_queue.append([frames, what])


func _shot(name: String) -> void:
	_then(0, func() -> void:
		root.get_texture().get_image().save_png(_out.path_join(name + ".png"))
		print("saved ", name))


func _plan() -> void:
	var view: MatchView = _director._view
	var hud: MatchHud = _director._hud
	var content: ContentLibrary = _director.content
	if "trails" in _kinds:
		for family: PitchFamilyDef in content.pitches:
			for mode in [MatchView.CameraMode.BAT, MatchView.CameraMode.PITCH]:
				var f := family
				var m: int = mode
				_then(12, func() -> void: view.set_camera_mode(m))
				_then(2, func() -> void:
					var intent := PitchIntent.new(f.id, PitchResolver.zone_center(_director.tuning) + Vector2(0.08, 0.05), 0.0)
					var pitch := PitchResolver.resolve(intent, f, _director.tuning, MatchRng.new(3))
					view.show_pitch(pitch, pitch.travel_time * (0.62 if m == MatchView.CameraMode.BAT else 0.4), f.tell_color, f.tell_trail, f))
				_shot("%s_%s" % [f.id, "bat" if m == MatchView.CameraMode.BAT else "pitch"])
		_then(1, func() -> void:
			view._pitch_trail.hide_trail()
			for ghost: MeshInstance3D in view._trail:
				ghost.visible = false)
	if "k" in _kinds:
		_then(4, func() -> void:
			view.set_camera_mode(MatchView.CameraMode.PITCH)
			view.strikeout_moment(PitchResolver.zone_center(_director.tuning), Color(0.9, 0.2, 0.25))
			hud.show_strikeout(false, MenuStyle.GOLD, Color.WHITE, "SWINGING · 4 K TODAY"))
		for i in [0, 2, 4, 8, 20]:
			var at: int = i
			_then(at if at == 0 else 2, func() -> void: pass)
			_shot("k_swinging_%02d" % at)
		_then(60, func() -> void: hud.show_strikeout(true, Color(0.4, 0.75, 1.0), Color.WHITE))
		_then(8, func() -> void: pass)
		_shot("k_looking")
	if "flames" in _kinds:
		for streak in [2, 3]:
			var s: int = streak
			_then(2, func() -> void:
				view.set_camera_mode(MatchView.CameraMode.PITCH)
				view.set_hot_streak(s))
			_then(40, func() -> void: pass)
			_shot("flames_%d_pitch" % s)
			_then(2, func() -> void: view.set_camera_mode(MatchView.CameraMode.BAT))
			_then(40, func() -> void: pass)
			_shot("flames_%d_bat" % s)
		_then(2, func() -> void:
			view.set_camera_mode(MatchView.CameraMode.PITCH)
			view.swing_bat(true))
		for i in 4:
			_then(3, func() -> void: pass)
			_shot("flames_swing_%d" % i)
