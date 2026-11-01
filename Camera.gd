extends Camera3D

@onready var PitchPivot = $".."
@onready var TwistPivot = $"../.."

const MaxZoom = 10.0
const MinZoom = 1.0
const ZoomStep = 1.0
const ZoomSmoothing = 10.0

var TargetZoom = 4.0

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	TargetZoom = clamp(position.z, MinZoom, MaxZoom)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		TwistPivot.rotate_y(deg_to_rad(-event.relative.x / 4))
		PitchPivot.rotate_x(deg_to_rad(-event.relative.y / 4))
		PitchPivot.rotation_degrees.x = clamp(PitchPivot.rotation_degrees.x, -45, 20)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP && event.is_pressed():
			TargetZoom = clamp(TargetZoom - ZoomStep, MinZoom, MaxZoom)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN && event.is_pressed():
			TargetZoom = clamp(TargetZoom + ZoomStep, MinZoom, MaxZoom)

func _process(Delta: float) -> void:
	position.z = lerp(position.z, TargetZoom, 1 - exp(-ZoomSmoothing * Delta))