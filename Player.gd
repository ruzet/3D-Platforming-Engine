extends CharacterBody3D

const Speed = 300
const Gravity = 500
const Acceleraton = 10

func _ready() -> void:
	pass

func _process(Delta: float) -> void:
	var XVelocity = 0
	var ZVelocity = 0
	var YVelocity = 0
	var XDirection = Input.get_action_strength("Right") - Input.get_action_strength("Left")
	var ZDirection = Input.get_action_strength("Down") - Input.get_action_strength("Up")
	XDirection = Vector2(XDirection, ZDirection).normalized().x
	ZDirection = Vector2(XDirection, ZDirection).normalized().y
	
	var TargetXVelocity = XDirection * Speed * Delta
	var TargetZVelocity = ZDirection * Speed * Delta
	XVelocity = TargetXVelocity + (XVelocity - TargetXVelocity) * exp(-Acceleration * Delta)
	ZVelocity = ZDirection * Speed * Delta

	if is_on_floor():
		YVelocity = 0
		pass
	else:
		YVelocity -= Gravity * Delta

	self.velocity = Vector3(XVelocity, YVelocity, ZVelocity)
	move_and_slide()