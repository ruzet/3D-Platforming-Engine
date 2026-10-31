extends Camera3D

@onready var PitchPivot = $".."
@onready var TwistPivot = $"../.."

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	pass

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		TwistPivot.rotate_y(deg_to_rad(-event.relative.x / 4))
		PitchPivot.rotate_x(deg_to_rad(-event.relative.y / 4))