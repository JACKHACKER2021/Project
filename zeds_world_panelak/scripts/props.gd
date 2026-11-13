extends Node3D
## Oživlé předměty. Občas v domě něco ožije — pozná se podle očí a zvuku.
## Zneškodní se sekerou.

const MODEL := "res://assets/models/props_zed.glb"
## ALIVER oživuje techniku, ne nábytek — kánon Edice 2.5, odd. 1.
const DRUHY := ["lednice_oziva", "televize_oziva", "pracka_oziva", "radio_oziva"]

var zvuk: Node
var hrac: CharacterBody3D
var _cas_do_dalsiho := 40.0

func _process(delta: float) -> void:
	_cas_do_dalsiho -= delta
	if _cas_do_dalsiho <= 0.0:
		_cas_do_dalsiho = randf_range(45.0, 140.0)
		_oziv()

func _oziv() -> void:
	if hrac == null:
		return
	var scn := load(MODEL) as PackedScene
	if scn == null:
		return
	var inst := scn.instantiate()
	var druh: String = DRUHY[randi() % DRUHY.size()]
	var model: Node3D = null
	for n in inst.find_children(druh + "*", "MeshInstance3D", true, false):
		model = n.duplicate()
		break
	inst.queue_free()
	if model == null:
		return

	var p := preload("res://scripts/prop_alive.gd").new()
	p.zvuk = zvuk
	p.hrac = hrac
	add_child(p)
	p.add_child(model)
	# objeví se kousek za hráčem, v jeho patře
	var uhel := randf() * TAU
	p.global_position = hrac.global_position \
		+ Vector3(cos(uhel) * randf_range(5.0, 11.0), 0, sin(uhel) * randf_range(5.0, 11.0))
	p.global_position.y = ZWConfig.floor_y(ZWConfig.y_to_floor(hrac.global_position.y))
