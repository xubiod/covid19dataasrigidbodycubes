extends RigidBody

func _ready() -> void:
	visible = false;
	set_collision_layer_bit(0, visible);
	pass

func _process(_delta: float) -> void:
	set_collision_layer_bit(0, visible);
	pass

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("sword"):
		visible = !visible;
	pass
