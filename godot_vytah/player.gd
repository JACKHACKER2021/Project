extends CharacterBody3D
## Hráč z pohledu první osoby.
## PC: WASD chůze, myš rozhled, LMB / E použít, Esc uvolní myš.
## Mobil: levá půlka obrazovky = joystick chůze, pravá = rozhled, ťuknutí vpravo = použít.

signal interacted(act)

const SPEED := 2.8
var cam: Camera3D
var ray: RayCast3D
var shake := false

var mobile := false
var move_id := -1
var move_start := Vector2.ZERO
var touch_move := Vector2.ZERO
var look_id := -1
var look_dist := 0.0
var use_rect := Rect2()      # nastaví main.gd – tlačítko POUŽÍT
var joy_center := Vector2.ZERO # střed joysticku

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
	mobile = OS.has_feature("mobile")
	if not mobile:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(e: InputEvent) -> void:
	if e is InputEventScreenTouch:
		var left: bool = e.position.x < get_viewport().get_visible_rect().size.x * 0.5
		if e.pressed:
			if use_rect.has_point(e.position):
				_use()
				return
			if left and move_id == -1:
				move_id = e.index
				move_start = joy_center if joy_center != Vector2.ZERO else e.position
			elif not left and look_id == -1:
				look_id = e.index
				look_dist = 0.0
		else:
			if e.index == move_id:
				move_id = -1
				touch_move = Vector2.ZERO
			elif e.index == look_id:
				look_id = -1
	elif e is InputEventScreenDrag:
		if e.index == move_id:
			touch_move = ((e.position - move_start) / 100.0).limit_length(1.0)
		elif e.index == look_id:
			look_dist += e.relative.length()
			rotate_y(-e.relative.x * 0.005)
			cam.rotation.x = clamp(cam.rotation.x - e.relative.y * 0.005, -1.4, 1.4)

func _unhandled_input(e: InputEvent) -> void:
	if mobile:
		return
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
	else:
		interacted.emit(["drop"])   # POUŽÍT do prázdna = odložit nesený díl

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	var dir := Vector3.ZERO
	if Input.is_physical_key_pressed(KEY_W): dir.z -= 1
	if Input.is_physical_key_pressed(KEY_S): dir.z += 1
	if Input.is_physical_key_pressed(KEY_A): dir.x -= 1
	if Input.is_physical_key_pressed(KEY_D): dir.x += 1
	if touch_move != Vector2.ZERO:
		dir = Vector3(touch_move.x, 0, touch_move.y)
	dir = transform.basis * dir
	if dir.length() > 1.0:
		dir = dir.normalized()
	velocity.x = dir.x * SPEED
	velocity.z = dir.z * SPEED
	move_and_slide()
	if shake:
		cam.h_offset = randf_range(-0.006, 0.006)
		cam.v_offset = randf_range(-0.008, 0.008)
	else:
		cam.h_offset = 0
		cam.v_offset = 0
