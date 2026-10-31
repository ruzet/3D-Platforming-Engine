extends CharacterBody3D

const GroundSpeed = 20
const Gravity = 20
const Acceleration = 3
const Deceleration = 3
const SkidDeceleration = 8

@onready var PitchPivot = $"TwistPivot/PitchPivot"
@onready var TwistPivot = $"TwistPivot"


var SkidTimer = 0
var HorizontalVelocity = 0
var XVelocity = 0
var ZVelocity = 0
var YVelocity = 0
var Direction = Vector3.ZERO
var LastDirection = Vector3.ZERO
var SkidDirection = Vector3.ZERO
var Skidding = false

func RotateValue(Value, Degrees):
	var Angle = Value * 180
	Angle += Degrees
	return clamp(Angle / 180, -1, 1)

func HorizontalVelocityHandler(Delta):
	if Skidding == false:
		if Direction != Vector3.ZERO:
			LastDirection = Direction
			HorizontalVelocity = GroundSpeed + (HorizontalVelocity - GroundSpeed) * exp(-Acceleration * Delta)
		else:
			HorizontalVelocity *= exp(-Deceleration * Delta)
			if HorizontalVelocity < 0.1: HorizontalVelocity = 0

		XVelocity = HorizontalVelocity * LastDirection.x
		ZVelocity = HorizontalVelocity * LastDirection.z
	else:
		HorizontalVelocity *= exp(-SkidDeceleration * Delta)
		XVelocity = HorizontalVelocity * SkidDirection.x
		ZVelocity = HorizontalVelocity * SkidDirection.z


func _ready() -> void:
	pass

func _physics_process(Delta: float) -> void:
	var Input2D = Input.get_vector("Left", "Right", "Down", "Up")
	if SkidTimer > 0:
		SkidTimer -= Delta
	Skidding = SkidTimer > 0

	Direction = TwistPivot.global_transform.basis * Vector3(Input2D.x, 0, -Input2D.y)
	Direction.y = 0
	Direction = Direction.normalized()

	if LastDirection.dot(Direction) < -0.5 && Skidding == false && HorizontalVelocity > GroundSpeed * 0.75:
		SkidDirection = LastDirection
		SkidTimer = 0.3
		Skidding = true

	HorizontalVelocityHandler(Delta)

	if is_on_floor():
		YVelocity = 0
		pass
	else:
		YVelocity -= Gravity * Delta

	self.velocity = Vector3(XVelocity, YVelocity, ZVelocity)
	move_and_slide()