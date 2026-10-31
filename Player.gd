extends CharacterBody3D

const GroundSpeed = 10
const Gravity = 20
const Acceleration = 3
const Deceleration = 1

var HorizontalVelocity = 0
var XVelocity = 0
var ZVelocity = 0
var YVelocity = 0
var XDirection = 0
var ZDirection = 0
var LastXDirection = 0
var LastZDirection = 0

func GroundAccelDecel(Delta):
	if XDirection != 0 || ZDirection != 0:
		HorizontalVelocity = GroundSpeed + (HorizontalVelocity - GroundSpeed) * exp(-Acceleration * Delta)
	else:
		HorizontalVelocity = 0 + (HorizontalVelocity - 0) * exp(-Deceleration * Delta)

func _ready() -> void:
	pass

func _process(Delta: float) -> void:
	XDirection = Input.get_action_strength("Right") - Input.get_action_strength("Left")
	ZDirection = Input.get_action_strength("Down") - Input.get_action_strength("Up")
	XDirection = Vector2(XDirection, ZDirection).normalized().x
	ZDirection = Vector2(XDirection, ZDirection).normalized().y

	if XDirection != 0: LastXDirection = XDirection
	if ZDirection != 0: LastZDirection = ZDirection

	if XDirection != 0 && ZDirection == 0: LastZDirection = 0
	if ZDirection != 0 && XDirection == 0: LastXDirection = 0

	XVelocity = HorizontalVelocity * LastXDirection
	ZVelocity = HorizontalVelocity * LastZDirection


	if is_on_floor():
		GroundAccelDecel(Delta)
		YVelocity = 0
		pass
	else:
		YVelocity -= Gravity * Delta

	self.velocity = Vector3(XVelocity, YVelocity, ZVelocity)
	move_and_slide()