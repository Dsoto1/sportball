class_name MenuTile
extends BaseButton
## One of the menus' buttons, drawn in MenuStyle: gold when selected
## (focused or under the mouse), navy-blue otherwise, grey when disabled.
## Kinds:
##   WIDE: the main menu's big slanted bars (icon, title, subtitle);
##   TILE: a sub-menu's square tile (icon over its title);
##   BAR:  a shorter bar (pause menu, settings' back);
##   ICON: the round-cornered icon buttons top right.
## `soon` marks a feature that isn't built yet: it still takes focus (so
## the menu reads like the finished one) and says so when pressed.

enum Kind { WIDE, TILE, BAR, ICON }

var kind := Kind.WIDE
var title := ""
var subtitle := ""
var icon: StringName = &""
var soon := false
## Lifts toward the reader when selected (px), eased.
var _lift := 0.0


func _init(p_kind: Kind = Kind.WIDE, p_title: String = "", p_icon: StringName = &"", p_subtitle: String = "") -> void:
	kind = p_kind
	title = p_title
	icon = p_icon
	subtitle = p_subtitle
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP
	match kind:
		Kind.WIDE:
			custom_minimum_size = Vector2(440, 96)
		Kind.TILE:
			custom_minimum_size = Vector2(250, 230)
		Kind.BAR:
			custom_minimum_size = Vector2(380, 64)
		Kind.ICON:
			custom_minimum_size = Vector2(64, 56)
	mouse_entered.connect(func() -> void:
		if not disabled:
			grab_focus())
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)


func selected() -> bool:
	return has_focus() and not disabled


func _process(delta: float) -> void:
	var want := 12.0 if selected() and kind != Kind.ICON else 0.0
	if not is_equal_approx(_lift, want):
		_lift = move_toward(_lift, want, delta * 90.0)
		queue_redraw()


func _draw() -> void:
	var on := selected()
	var r := Rect2(Vector2(_lift, 0), size)
	var fill := MenuStyle.BLUE.darkened(0.2)
	var rim := MenuStyle.HIGHLIGHT.darkened(0.35)
	var ink := MenuStyle.NEUTRAL
	if on:
		fill = MenuStyle.GOLD
		rim = MenuStyle.GOLD.lightened(0.45)
		ink = MenuStyle.NAVY
	if disabled:
		fill = Color("2A3A55")
		rim = Color("3C4C68")
		ink = Color("7D8AA0")
	var slant := MenuStyle.SLANT if kind in [Kind.WIDE, Kind.BAR] else 0.12
	if kind == Kind.ICON:
		slant = 0.2
	MenuStyle.draw_panel(self, r, fill, rim, 3.0 if on else 2.0, slant, not on)
	if on and kind in [Kind.WIDE, Kind.BAR]:
		# A white flash along the leading edge, as the reference's selected bar.
		MenuStyle.draw_stripe(self, r.position + Vector2(r.size.y * slant + 6.0, 4.0), 5.0, r.size.y - 8.0, Color(1, 1, 1, 0.5))
	match kind:
		Kind.WIDE:
			var ic := r.position + Vector2(r.size.y * slant + 58.0, r.size.y * 0.5)
			MenuStyle.draw_icon(self, icon, ic, 50.0, ink)
			var x := ic.x + 52.0
			var head := 52 if subtitle == "" else 44
			var y := r.position.y + (r.size.y - head * 0.95) * 0.5 - (12.0 if subtitle != "" else 0.0)
			MenuStyle.draw_text(self, Vector2(x, y), title, MenuStyle.HEAD_FONT, head, ink, not on)
			if subtitle != "":
				MenuStyle.draw_text(self, Vector2(x, y + head * 0.92), subtitle, MenuStyle.body(600), 17, Color(ink, 0.85), not on)
		Kind.BAR:
			var ic := r.position + Vector2(r.size.y * slant + 34.0, r.size.y * 0.5)
			MenuStyle.draw_icon(self, icon, ic, 30.0, ink)
			MenuStyle.draw_text(self, Vector2(ic.x + 32.0, r.position.y + (r.size.y - 34.0) * 0.5), title, MenuStyle.HEAD_FONT, 36, ink, not on)
		Kind.TILE:
			MenuStyle.draw_icon(self, icon, r.position + Vector2(r.size.x * 0.5, r.size.y * 0.38), 86.0, ink if on else MenuStyle.GOLD)
			var lines := title.split("\n")
			var y := r.size.y * 0.66 - (lines.size() - 1) * 16.0
			for line in lines:
				var tw := MenuStyle.text_width(line, MenuStyle.HEAD_FONT, 34)
				MenuStyle.draw_text(self, Vector2(r.position.x + (r.size.x - tw) * 0.5, y), line, MenuStyle.HEAD_FONT, 34, ink, not on)
				y += 32.0
		Kind.ICON:
			MenuStyle.draw_icon(self, icon, r.get_center(), 32.0, ink)
	if soon and kind != Kind.ICON:
		# A small tag in the far corner.
		var tag := "COMING SOON"
		var tw := MenuStyle.text_width(tag, MenuStyle.body(700), 13) + 18.0
		var at := Vector2(r.end.x - tw - (r.size.y * slant if kind != Kind.TILE else 10.0) - 6.0, r.position.y + 8.0)
		draw_rect(Rect2(at, Vector2(tw, 20)), MenuStyle.DEEP if on else MenuStyle.GOLD)
		MenuStyle.draw_text(self, at + Vector2(9, 2), tag, MenuStyle.body(700), 13, MenuStyle.GOLD if on else MenuStyle.NAVY, false)
