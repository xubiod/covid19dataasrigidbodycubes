extends Camera

var starting_rotation : Vector3;
var change_factor = 0.05;

var _size : Vector2;
var frames : float = 0;
var bob_effect = 0;
# export(NodePath) var raycast_path;
# var raycast : RayCast;

func _ready() -> void:
	starting_rotation = rotation_degrees;
	pass


func _process(_delta: float) -> void:
	var mouse = get_viewport().get_mouse_position();
	_size = get_viewport().size;

	var change = Vector2((_size.x / 2) - mouse.x, (_size.y / 2) - mouse.y);
	change.x *= change_factor;
	change.y *= change_factor;
	change.x += sin(frames / 30) * bob_effect;
	change.y += cos(frames / 30) * bob_effect;

	rotation_degrees = Vector3(starting_rotation.x + change.y, starting_rotation.y + change.x, starting_rotation.z);
	frames += 1.0;
	pass
