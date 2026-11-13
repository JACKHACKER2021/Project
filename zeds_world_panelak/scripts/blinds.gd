extends Node3D
## Žaluzie. Lamely jsou v modelu jeden mesh na celý dům, takže si
## pro hratelná podlaží vyrábíme vlastní desky, které jdou stáhnout.

var dum_stav: Node
var zvuk: Node
var patro := 0
var zatazeno := false
var lamely: Array[MeshInstance3D] = []

const POCET_LAMEL := 8

func postav(okno_stred: Vector3, sirka: float, vyska: float) -> void:
	for i in POCET_LAMEL:
		var m := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(sirka, vyska / POCET_LAMEL * 0.85, 0.03)
		m.mesh = bm
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.93, 0.92, 0.88)
		m.material_override = mat
		m.position = okno_stred + Vector3(0, vyska * 0.5 - (i + 0.5) * vyska / POCET_LAMEL, 0.04)
		m.visible = false
		add_child(m)
		lamely.append(m)
	# interakce rukou
	var sb := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(sirka, vyska, 0.25)
	cs.shape = bs
	sb.add_child(cs)
	sb.position = okno_stred
	sb.set_script(preload("res://scripts/blinds_touch.gd"))
	sb.zaluzie = self
	add_child(sb)

func prepni() -> void:
	zatazeno = not zatazeno
	if zvuk:
		zvuk.hraj_3d("sekera_zasah_03", self, -14.0, 20.0)
	var tw := create_tween()
	for i in lamely.size():
		var m := lamely[i]
		if zatazeno:
			m.visible = true
			m.scale.y = 0.05
			tw.parallel().tween_property(m, "scale:y", 1.0, 0.25).set_delay(i * 0.04)
		else:
			tw.parallel().tween_property(m, "scale:y", 0.05, 0.2).set_delay(i * 0.03)
	if not zatazeno:
		await tw.finished
		for m in lamely:
			m.visible = false
	if dum_stav:
		dum_stav.zaluzie_stav[patro] = zatazeno
