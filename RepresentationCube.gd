extends RigidBody

var starting_pos : Vector3;
var death_barrier = -50;
var death_distance = 1000;
var attract_point : Spatial;
var store_velocity : Vector3;
var store_angular_vel : Vector3;

func _ready() -> void:
	starting_pos = translation;
	pass

func _process(delta: float) -> void:
	if Input.is_action_pressed("push_zup"):
		apply_central_impulse(translation.direction_to(attract_point.translation));
	elif Input.is_action_just_pressed("push_away"):
		var newvec = (translation - attract_point.translation);
		if newvec.x == 0: newvec.x = rand_range(-0.01, 0.01);
		if newvec.y == 0: newvec.y = rand_range(-0.01, 0.01);
		if newvec.z == 0: newvec.z = rand_range(-0.01, 0.01);
		newvec = 8 * newvec.inverse();
#		newvec.x = sign(newvec.x) * 8 / max(abs(newvec.x), 0.1);
#		newvec.y = sign(newvec.y) * 8 / max(abs(newvec.y), 0.1);
#		newvec.z = sign(newvec.z) * 8 / max(abs(newvec.z), 0.1);
		apply_central_impulse(newvec);
	elif Input.is_action_just_pressed("reset"):
		linear_velocity = Vector3.ZERO;
		angular_velocity = Vector3.ZERO;
		translation = starting_pos;

	if Input.is_action_just_pressed("freeze"):
		if (mode == MODE_RIGID):
			mode = MODE_STATIC;
			store_velocity = linear_velocity;
			store_angular_vel = angular_velocity;
		else:
			mode = MODE_RIGID;
			linear_velocity = store_velocity;
			angular_velocity = store_angular_vel;

	if translation.y < death_barrier:
		translation = starting_pos;
		linear_velocity *= 0.9;

	if attract_point != null:
		if translation.distance_to(attract_point.translation) > death_distance:
			translation = starting_pos;
			linear_velocity *= 0.9;
	pass
