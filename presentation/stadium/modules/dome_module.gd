extends StadiumModule
## A sealed dome: a ribbed shell over the bowl, catwalk rings hung with
## light banks, a glowing crown at the top. Parks with one play indoors
## (StadiumDef.is_roofed): no sky, skyline or light towers.


func build(stadium: Stadium, piece: StadiumPiece, _home: TeamDef, _away: TeamDef) -> void:
	var def := stadium.def
	var radius := 215.0 * piece.size
	# The wall rises clear of everything in the park (the centerpiece stands
	# on the outfield stands) before the shell curves over.
	var rim := stadium.stand_top(0.0).y + 46.0
	var rise := float(piece.param("rise"))
	var center := Stadium.FIELD_CENTER + Vector3(0.0, 0.0, 10.0)
	var shell := MeshInstance3D.new()
	shell.name = stadium.unique_name("Roof")
	var dome := SphereMesh.new()
	dome.radius = radius
	dome.height = rise * 2.0
	dome.is_hemisphere = true
	dome.radial_segments = 64
	dome.rings = 16
	dome.flip_faces = true
	shell.mesh = dome
	shell.position = center + Vector3.UP * rim
	var roof_mat := GrayboxField._mat(def.structure_color.darkened(0.45))
	roof_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	shell.material_override = roof_mat
	shell.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	stadium.add_child(shell)
	var wall := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = rim
	cyl.radial_segments = 64
	cyl.cap_top = false
	cyl.cap_bottom = false
	cyl.flip_faces = true
	wall.mesh = cyl
	wall.position = center + Vector3.UP * rim * 0.5
	wall.material_override = roof_mat
	wall.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	shell.add_sibling(wall)
	# Ribs and catwalks: thin glowing rings at a few heights up the shell.
	for k in 4:
		var u := (k + 1) / 5.0
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		var r := radius * sqrt(1.0 - u * u)
		torus.inner_radius = r - 1.2
		torus.outer_radius = r
		torus.rings = 96
		ring.mesh = torus
		ring.position = center + Vector3.UP * (rim + rise * u - 1.0)
		ring.material_override = Stadium.glow(def.accent_color if k % 2 == 0 else def.structure_color, 1.2 if k % 2 == 0 else 0.0)
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		stadium.add_child(ring)
	for i in 12:
		var a := TAU * i / 12.0
		var bank := stadium.box(Vector3(10.0, 1.0, 4.0), Color.WHITE)
		bank.position = center + Vector3(cos(a), 0.0, sin(a)) * radius * 0.55 + Vector3.UP * (rim + rise * 0.8)
		bank.material_override = Stadium.glow(Color(1.0, 0.97, 0.88), 5.0)
		bank.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var crown := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 24.0
	disc.bottom_radius = 24.0
	disc.height = 1.0
	crown.mesh = disc
	crown.position = center + Vector3.UP * (rim + rise - 0.8)
	crown.material_override = Stadium.glow(def.accent_color, 2.5)
	crown.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	stadium.add_child(crown)
