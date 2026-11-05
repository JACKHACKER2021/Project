extends RefCounted
## Pózování postav (port rotW/aim z Remasteru). Kloub je buď Node3D (Voxie), nebo kost ve Skeleton3D (Cocoa).

var root: Node3D            # kořen postavy (pozice a natočení ve světě)
var model: Node3D
var joints := {}            # role -> {"n": Node3D} nebo {"sk": Skeleton3D, "i": int}
var rest := []              # [joint, q, p, s]
var side := {"R": -1.0, "L": 1.0}
var C := {"look": 0.0, "look_at": null, "wave_at": 0.0, "lit": 0.0, "twitch": [0.0, 0.0, 0.0], "twitch_next": 0.0, "nice": false}
var name := ""

func has(role: String) -> bool:
	return joints.has(role)

func _q(j: Dictionary) -> Quaternion:
	if j.has("n"):
		return (j.n as Node3D).quaternion
	return (j.sk as Skeleton3D).get_bone_pose_rotation(j.i)

func _set_q(j: Dictionary, q: Quaternion) -> void:
	if j.has("n"):
		(j.n as Node3D).quaternion = q.normalized()
	else:
		(j.sk as Skeleton3D).set_bone_pose_rotation(j.i, q.normalized())

func _parent_wq(j: Dictionary) -> Quaternion:
	if j.has("n"):
		return (j.n as Node3D).get_parent().global_transform.basis.get_rotation_quaternion()
	var sk: Skeleton3D = j.sk
	var p := sk.get_bone_parent(j.i)
	var b := sk.global_transform.basis.orthonormalized()
	if p >= 0:
		b = b * sk.get_bone_global_pose(p).basis.orthonormalized()
	return b.get_rotation_quaternion()

func wpos(j: Dictionary) -> Vector3:
	if j.has("n"):
		return (j.n as Node3D).global_position
	var sk: Skeleton3D = j.sk
	return sk.global_transform * sk.get_bone_global_pose(j.i).origin

func capture_rest() -> void:
	rest.clear()
	for role in joints:
		var j: Dictionary = joints[role]
		if j.has("n"):
			var n: Node3D = j.n
			rest.append([j, n.quaternion, n.position, n.scale])
		else:
			var sk: Skeleton3D = j.sk
			rest.append([j, sk.get_bone_pose_rotation(j.i), sk.get_bone_pose_position(j.i), sk.get_bone_pose_scale(j.i)])

func reset_pose() -> void:
	for r in rest:
		var j: Dictionary = r[0]
		if j.has("n"):
			var n: Node3D = j.n
			n.quaternion = r[1]
			n.position = r[2]
			n.scale = r[3]
		else:
			var sk: Skeleton3D = j.sk
			sk.set_bone_pose_rotation(j.i, r[1])
			sk.set_bone_pose_position(j.i, r[2])
			sk.set_bone_pose_scale(j.i, r[3])

func set_scale(role: String, s: float) -> void:
	if not has(role):
		return
	var j: Dictionary = joints[role]
	if j.has("n"):
		(j.n as Node3D).scale = Vector3.ONE * s
	else:
		(j.sk as Skeleton3D).set_bone_pose_scale(j.i, Vector3.ONE * s)

# rotace v souřadnicích postavy (Euler YXZ jako v three.js)
func rotW(role: String, x: float, y: float, z: float) -> void:
	if not has(role) or (x == 0.0 and y == 0.0 and z == 0.0):
		return
	var j: Dictionary = joints[role]
	var pq := _parent_wq(j)
	var cq := root.global_transform.basis.get_rotation_quaternion()
	var q := cq * Quaternion.from_euler(Vector3(x, y, z)) * cq.inverse()
	_set_q(j, pq.inverse() * q * pq * _q(j))

# natočí kost tak, aby mířila (ke svému "tip" kloubu) daným směrem v souřadnicích postavy
func aim(role: String, tip: String, dir: Vector3) -> void:
	if not has(role) or not has(tip):
		return
	var j: Dictionary = joints[role]
	var cur := (wpos(joints[tip]) - wpos(j))
	if cur.length() < 0.0001:
		return
	cur = cur.normalized()
	var cq := root.global_transform.basis.get_rotation_quaternion()
	var target := (cq * dir.normalized()).normalized()
	var q := Quaternion(cur, target)
	var pq := _parent_wq(j)
	_set_q(j, pq.inverse() * q * pq * _q(j))

func arm(k: String, up: Vector3, fore: Vector3) -> void:
	aim("arm" + k + "1", "arm" + k + "2", up)
	aim("arm" + k + "2", "arm" + k + "3", fore)

static func ease_io(t: float) -> float:
	return 2.0 * t * t if t < 0.5 else 1.0 - pow(-2.0 * t + 2.0, 2.0) / 2.0

func arms_down(t: float, wave: float = 0.0) -> void:
	var r: float = side.R
	var l: float = side.L
	arm("L", Vector3(l * 0.5, -1, 0.08), Vector3(l * 0.3, -1, 0.2))
	var upD := Vector3(r * 0.5, -1, 0.08)
	var foreD := Vector3(r * 0.3, -1, 0.2)
	if wave == 0.0:
		arm("R", upD, foreD)
		return
	arm("R", upD.lerp(Vector3(r * 0.9, 0.3, 0.55), wave), foreD.lerp(Vector3(r * (0.25 + sin(t * 7.0) * 0.45), 1, 0.4), wave))

## mode: idle / stage / door / walk / broken / scare ; scare_t pro lekačku
func pose(t: float, mode: String, scare_t: float = 0.0) -> void:
	reset_pose()
	if model == null:
		return
	if mode == "scare":
		var k: float = ease_io(clampf(scare_t / 0.12, 0, 1))
		var jj: float = 1.0 - clampf((scare_t - 0.9) / 0.5, 0, 1)
		var r: float = side.R
		var l: float = side.L
		arm("R", Vector3(r * 0.2, -1, 0.1).lerp(Vector3(r * 0.35, 0.3, 1), k), Vector3(r * 0.1, -1, 0.2).lerp(Vector3(r * 0.15, 0.45, 1), k))
		arm("L", Vector3(l * 0.2, -1, 0.1).lerp(Vector3(l * 0.35, 0.3, 1), k), Vector3(l * 0.1, -1, 0.2).lerp(Vector3(l * 0.15, 0.45, 1), k))
		rotW("chest", 0.3 * k, 0, 0)
		rotW("head", (-0.35 + randf_range(-0.12, 0.12) * jj) * k, randf_range(-0.15, 0.15) * jj, randf_range(-0.25, 0.25) * jj * k)
		set_scale("head", 1.0 + 0.18 * k)
		var jaw := 0.0 if scare_t < 0.12 else (1.0 if sin(scare_t * 38.0) > -0.2 else 0.35)
		if has("jaw"):
			rotW("jaw", 0.7 * jaw, 0, 0)
		else:
			rotW("head", -0.22 * jaw, 0, 0)
		rotW("earR1", randf_range(-0.3, 0.3) * jj, 0, 0)
		rotW("earL1", randf_range(-0.3, 0.3) * jj, 0, 0)
		return
	if mode == "broken":
		arms_down(t, 0.0)
		var tw := randf_range(-0.3, 0.3) if sin(t * 17.0) > 0.93 else 0.0
		rotW("chest", 0.35, 0, 0)
		rotW("head", 0.75 + tw, tw, 0.5)
		return
	if mode == "walk":
		var ww := t * 6.0
		var sn := sin(ww)
		var r: float = side.R
		var l: float = side.L
		rotW("legR1", sn * 0.5, 0, 0)
		rotW("legL1", -sn * 0.5, 0, 0)
		rotW("legR2", maxf(0.0, -cos(ww)) * 0.5, 0, 0)
		rotW("legL2", maxf(0.0, cos(ww)) * 0.5, 0, 0)
		arm("R", Vector3(r * 0.2, -1, -sn * 0.4), Vector3(r * 0.1, -1, 0.1 - sn * 0.3))
		arm("L", Vector3(l * 0.2, -1, sn * 0.4), Vector3(l * 0.1, -1, 0.1 + sn * 0.3))
		rotW("head", 0, sn * 0.06, 0)
		return
	var w := 0.0
	if mode == "idle" or mode == "stage":
		if t > C.wave_at + 2.6:
			C.wave_at = t + 8.0 + randf() * 8.0
		var kk: float = (t - C.wave_at) / 2.6
		if kk > 0 and kk < 1:
			w = ease_io(clampf(minf(kk, 1.0 - kk) * 4.0, 0, 1))
	if C.nice and (mode == "door" or C.look > 0.4):
		w = maxf(w, 1.0 if mode == "door" else clampf(C.look * 1.6, 0, 1))
	arms_down(t, w)
	var yaw := sin(t * 0.45) * 0.2 * (1.0 - w) + 0.15 * w
	var pitch := sin(t * 0.7) * 0.04
	var roll := sin(t * 3.5) * 0.08 * w
	if C.look > 0 and C.look_at != null:
		var p: Vector3 = root.to_local(C.look_at)
		var ly := clampf(atan2(p.x, p.z), -1.1, 1.1)
		var lp := clampf(-atan2(p.y - 1.7, Vector2(p.x, p.z).length()), -0.6, 0.6)
		yaw += (ly - yaw) * C.look
		pitch += (lp - pitch) * C.look
		roll += 0.35 * C.look
	if mode == "door" and not C.nice:
		roll += 0.25 + sin(t * 0.8) * 0.05
		pitch += 0.1
	if C.lit > 2.3 and not C.nice:
		if t > C.twitch_next:
			C.twitch_next = t + 0.06 + randf() * 0.25
			C.twitch = [randf_range(-0.4, 0.4), randf_range(-0.7, 0.7), randf_range(-0.5, 0.5)]
		pitch += C.twitch[0]
		yaw += C.twitch[1]
		roll += C.twitch[2]
		var r: float = side.R
		arm("R", Vector3(r * 0.2, -0.3, 1), Vector3(r * 0.1, -0.1, 1))
	rotW("chest", sin(t * 1.6) * 0.02, 0, 0)
	rotW("head", pitch, yaw, roll)
