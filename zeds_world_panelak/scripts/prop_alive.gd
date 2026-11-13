extends CharacterBody3D
## Jeden oživlý předmět. Jde po hráči, dokud ho nerozsekáš.

const RYCHLOST := 1.9
var zvuk: Node
var hrac: CharacterBody3D
var zdravi := 100.0
var probuzen := false

func _ready() -> void:
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(0.8, 1.6, 0.8)
	cs.shape = bs
	cs.position.y = 0.8
	add_child(cs)
	if zvuk:
		zvuk.hraj_3d(zvuk.nahodny(["predmet_ozije_01", "predmet_ozije_02"]), self, -2.0, 40.0)
	await get_tree().create_timer(2.0).timeout
	probuzen = true

func _physics_process(delta: float) -> void:
	if not probuzen or hrac == null:
		return
	var smer := hrac.global_position - global_position
	smer.y = 0.0
	var d := smer.length()
	if d > 1.1:
		velocity = smer.normalized() * RYCHLOST
	else:
		velocity = Vector3.ZERO
		if randf() < delta * 0.7:
			hrac.zranit(9.0)
	velocity.y -= 9.8 * delta
	move_and_slide()
	# kolébá se, jak jde
	rotation.z = sin(Time.get_ticks_msec() * 0.006) * 0.12

func zasah_sekerou(kolik: float) -> void:
	zdravi -= kolik
	if zdravi <= 0.0:
		if zvuk:
			zvuk.hraj_3d(zvuk.nahodny(["predmet_znicen_01", "predmet_znicen_02"]),
				get_parent(), -2.0, 40.0)
		queue_free()

func pouzij(_kdo: Node) -> void:
	pass
