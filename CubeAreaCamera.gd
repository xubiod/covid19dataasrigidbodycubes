extends Camera

var camera_mode : int = 0;

var starting_rotation : Vector3;
var change_factor = 0.05;

var _size : Vector2;
var frames : float = 0;
var bob_effect = 0;

var moving : bool = false;

var default_position : Vector3;
var default_rotation : Vector3;

var speed = 0.4;

var _viewport;
var _last_pos : Vector2;

func _ready() -> void:
	starting_rotation = rotation_degrees;
	default_position = translation;
	default_rotation = rotation;

	_viewport = get_viewport();
	pass


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("toggle_camera_mode"):
		if camera_mode == 0:
			camera_mode = 1;
		else:
			camera_mode = 0;

	match camera_mode:
		0:
			var mouse = get_viewport().get_mouse_position();
			_size = get_viewport().size;

			var change = Vector2((_size.x / 2) - mouse.x, (_size.y / 2) - mouse.y);
			change.x *= change_factor;
			change.y *= change_factor;
			change.x += sin(frames / 30) * bob_effect;
			change.y += cos(frames / 30) * bob_effect;

			rotation_degrees = Vector3(starting_rotation.x + change.y, starting_rotation.y + change.x, starting_rotation.z);
			frames += 1.0;
		1:
			if Input.get_action_strength("reset_camera") > 0:
				translation = translation.linear_interpolate(default_position, 0.5);
				rotation = rotation.linear_interpolate(default_rotation, 0.5);

			if moving:
				var inout : float = -Input.get_axis("camera_backwards", "camera_forwards");
				var strafe : float = Input.get_axis("camera_left", "camera_right");
				var zrotat : float = Input.get_axis("camera_rotate_ccw", "camera_rotate_cw");

				if Input.is_action_just_released("camera_speed_up"):
					speed *= 2;
				elif Input.is_action_just_released("camera_speed_down"):
					speed /= 2;

				speed = clamp(speed, 0.025, 3.2);

				var mouse = _viewport.get_mouse_position();
				_size = _viewport.size;

				var change = Vector3(round(_size.x / 2) - mouse.x, round(_size.y / 2) - mouse.y, zrotat);
				change.x *= change_factor * 10;
				change.y *= change_factor * 10;
				change.z *= speed;
				_viewport.warp_mouse(Vector2(round(_size.x / 2), round(_size.y / 2)));

				translate_object_local(Vector3(strafe * speed, 0, inout * speed));
				rotation_degrees = Vector3(rotation_degrees.x + change.y, rotation_degrees.y + change.x, rotation_degrees.z + change.z);

			if Input.is_action_just_pressed("move_camera"):
				moving = !moving;
				if moving:
					_viewport = get_viewport();
					_last_pos = _viewport.get_mouse_position();
					_size = _viewport.size;
					_viewport.warp_mouse(Vector2(_size.x / 2, _size.y / 2));
					Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN);
				else:
					_viewport.warp_mouse(_last_pos);
					Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE);
	pass
