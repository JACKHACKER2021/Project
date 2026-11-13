extends Node3D
## Jedny dveře bytu. Dají se otevřít rukou, zavřít za sebou,
## a když se s nimi praští, je to slyšet přes celé patro.

const SIRKA := 1.12
const VYSKA := 2.10

var zvuk: Node
var jmeno := ""
var cislo := 0
var otevreno := false
var zamceno := false
var pivot: Node3D
var telo: StaticBody3D
var tvar: CollisionShape3D
var smer := 1.0          # kam se otevírá

func postav(stred: Vector3, nz: float, jm: String, cis: int) -> void:
	jmeno = jm
	cislo = cis
	smer = -nz             # otevírá se dovnitř bytu
	pivot = Node3D.new()
	pivot.position = stred + Vector3(-SIRKA * 0.5, 0.0, 0.0)
	add_child(pivot)

	telo = StaticBody3D.new()
	pivot.add_child(telo)
	var s := SIRKA * 0.5

	# křídlo
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(SIRKA, VYSKA, 0.08)
	mi.mesh = bm
	mi.position = Vector3(s, VYSKA * 0.5, 0.0)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.46, 0.26, 0.15)
	m.roughness = 0.72
	mi.material_override = m
	telo.add_child(mi)

	# výplně, aby to nebyla jen deska
	var mv := StandardMaterial3D.new()
	mv.albedo_color = Color(0.40, 0.22, 0.12)
	mv.roughness = 0.75
	for dy in [0.62, 1.52]:
		var v := MeshInstance3D.new()
		var vb := BoxMesh.new()
		vb.size = Vector3(SIRKA - 0.26, 0.62, 0.02)
		v.mesh = vb
		v.position = Vector3(s, dy, nz * 0.05)
		v.material_override = mv
		telo.add_child(v)

	# klika
	var mk := StandardMaterial3D.new()
	mk.albedo_color = Color(0.70, 0.66, 0.55)
	mk.metallic = 0.7
	mk.roughness = 0.35
	for dz in [-0.07, 0.07]:
		var k := MeshInstance3D.new()
		var kb := BoxMesh.new()
		kb.size = Vector3(0.16, 0.035, 0.035)
		k.mesh = kb
		k.position = Vector3(SIRKA - 0.18, 1.05, dz)
		k.material_override = mk
		telo.add_child(k)

	# jmenovka
	var l := Label3D.new()
	l.text = "%s\nbyt %d" % [jmeno, cislo]
	l.pixel_size = 0.0016
	l.modulate = Color(0.1, 0.1, 0.1)
	l.outline_size = 0
	l.position = Vector3(s, 1.62, nz * 0.05)
	l.rotation.y = 0.0 if nz < 0.0 else PI
	l.double_sided = true
	telo.add_child(l)
	var jm_podklad := MeshInstance3D.new()
	var jb := BoxMesh.new()
	jb.size = Vector3(0.34, 0.20, 0.01)
	jm_podklad.mesh = jb
	jm_podklad.position = Vector3(s, 1.62, nz * 0.045)
	var mj := StandardMaterial3D.new()
	mj.albedo_color = Color(0.92, 0.90, 0.84)
	jm_podklad.material_override = mj
	telo.add_child(jm_podklad)

	tvar = CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(SIRKA + 0.08, VYSKA, 0.12)
	tvar.shape = bs
	tvar.position = Vector3(s, VYSKA * 0.5, 0.0)
	telo.add_child(tvar)

	telo.set_script(preload("res://scripts/dvere_dotek.gd"))
	telo.dvere = self

func pouzij(_kdo: Node) -> void:
	if zamceno:
		if zvuk:
			zvuk.hraj_3d("sekera_zasah_03", self, -12.0, 25.0)
		return
	otevreno = not otevreno
	var tw := create_tween()
	tw.tween_property(pivot, "rotation:y", smer * 1.5 if otevreno else 0.0, 0.55) \
		.set_trans(Tween.TRANS_SINE)
	tvar.disabled = otevreno
	if zvuk:
		zvuk.hraj_3d("predmet_ozije_02" if otevreno else "sekera_zasah_02",
			self, -14.0, 40.0)

func prasknout() -> void:
	## Zabouchnutí: rychlé a hlasité. Zéd to slyší.
	otevreno = false
	var tw := create_tween()
	tw.tween_property(pivot, "rotation:y", 0.0, 0.12)
	tvar.disabled = false
	if zvuk:
		zvuk.hraj_3d("sekera_zasah_01", self, -2.0, 120.0)
