extends CharacterBody3D
## Hráč z pohledu první osoby. WASD = chůze, myš = rozhlížení, LMB / E = použít, Esc = uvolnit myš.

signal interacted(act)

const SPEED := 2.8
var cam: Camera3D
var ray: RayCast3D
var shake := false
var main: Node

func _ready() -> void:
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.25
	cap.height = 1.75
	cs.shape = cap
	cs.position.y = 0.875
	add_child(cs)
	cam = Camera3D.new()
	cam.position.y = 1.62
	cam.fov = 75
	add_child(cam)
	ray = RayCast3D.new()
	ray.target_position = Vector3(0, 0, -2.2)
	ray.collide_with_areas = true
	cam.add_child(ray)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-e.relative.x * 0.003)
		cam.rotation.x = clamp(cam.rotation.x - e.relative.y * 0.003, -1.4, 1.4)
	elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			_use()
	elif e is InputEventKey and e.pressed and not e.echo:
		if e.physical_keycode == KEY_E:
			_use()
		elif e.physical_keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func looked_at() -> Object:
	var c := ray.get_collider()
	if c and c.has_meta("act"):
		return c
	return null

func _use() -> void:
	var c := looked_at()
	if c:
		interacted.emit(c.get_meta("act"))

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	var dir := Vector3.ZERO
	if Input.is_physical_key_pressed(KEY_W): dir.z -= 1
	if Input.is_physical_key_pressed(KEY_S): dir.z += 1
	if Input.is_physical_key_pressed(KEY_A): dir.x -= 1
	if Input.is_physical_key_pressed(KEY_D): dir.x += 1
	dir = (transform.basis * dir).normalized() * SPEED
	velocity.x = dir.x
	velocity.z = dir.z
	move_and_slide()
	if shake:
		cam.h_offset = randf_range(-0.006, 0.006)
		cam.v_offset = randf_range(-0.008, 0.008)
	else:
		cam.h_offset = 0
		cam.v_offset = 0
