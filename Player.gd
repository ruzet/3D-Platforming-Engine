extends CharacterBody3D

const Speed = 15
const CrouchingSpeed = 9
const DiveSpeed = 25
const DiveLaunch = 15
const Gravity = 40
const JumpPower = 17
const ShortJumpPower = 10
const StandHeight = 2
const CrouchHeight = 1.5
const GroundAcceleration = 3
const GroundDeceleration = 4
const AirAccelerate = 3
const AirDecelerate = 4
const SkidDeceleration = 8

@onready var PitchPivot = $"TwistPivot/PitchPivot"
@onready var TwistPivot = $"TwistPivot"
@onready var BeanMesh = $"BeanMesh"
@onready var CollisionMesh = $"CollisionShape"

var SkidTimer = 0
var JumpTimer = 0
var HorizontalVelocity = 0
var XVelocity = 0
var ZVelocity = 0
var YVelocity = 0
var Direction = Vector3.ZERO
var MaxDirection = Vector3.ZERO
var LastDirection = Vector3.ZERO
var DiveDirection = Vector3.ZERO
var SkidDirection = Vector3.ZERO
var CurrentNormal = Vector3.UP
var HoldingSpace = false
var Jumping = false
var Skidding = false
var Crouching = false
var Diving = false

func SetHeight(Height):
	CollisionMesh.shape.height = Height
	BeanMesh.mesh.height = Height
	var Offset = (Height - StandHeight) / 2.0
	CollisionMesh.position.y = Offset
	BeanMesh.position.y = Offset

func RotateValue(Value, Degrees):
	var Angle = Value * 180
	Angle += Degrees
	return clamp(Angle / 180, -1, 1)

func AlignToFloor(Delta):
	var TargetNormal = Vector3.UP
	if is_on_floor() && get_floor_angle() < floor_max_angle:
		TargetNormal = get_floor_normal() if is_on_floor() else Vector3.UP
	else:
		TargetNormal = Vector3.UP
	CurrentNormal = CurrentNormal.slerp(TargetNormal, 1 - exp(-12 * Delta)).normalized()

	var Tilt = Basis(Quaternion(Vector3.UP, CurrentNormal))
	BeanMesh.global_transform.basis = Tilt

func HorizontalVelocityHandler(Delta):
	if !Skidding && !Diving:
		if is_on_floor():
			if MaxDirection != Vector3.ZERO:
				var TargetSpeed = Speed if !Crouching else CrouchingSpeed
				LastDirection = Direction
				HorizontalVelocity = TargetSpeed + (HorizontalVelocity - TargetSpeed) * exp(-GroundAcceleration * Delta)
			else:
				HorizontalVelocity *= exp(-GroundDeceleration * Delta)
				if HorizontalVelocity < 0.1: HorizontalVelocity = 0
		else:
			var CurrentHorizontalVelocity = HorizontalVelocity * LastDirection
			var TargetHorizontalVelocity = (Direction * Speed if MaxDirection != Vector3.ZERO else Vector3.ZERO)
			CurrentHorizontalVelocity = TargetHorizontalVelocity + (CurrentHorizontalVelocity - TargetHorizontalVelocity) * exp(- (AirAccelerate if MaxDirection != Vector3.ZERO else AirDecelerate) * Delta)

			HorizontalVelocity = CurrentHorizontalVelocity.length()
			if HorizontalVelocity > 0.1:
				LastDirection = CurrentHorizontalVelocity / HorizontalVelocity

		XVelocity = HorizontalVelocity * LastDirection.x
		ZVelocity = HorizontalVelocity * LastDirection.z
	elif !Diving:
		HorizontalVelocity *= exp(-SkidDeceleration * Delta)
		XVelocity = HorizontalVelocity * SkidDirection.x
		ZVelocity = HorizontalVelocity * SkidDirection.z
	else:
		XVelocity = HorizontalVelocity * DiveDirection.x
		ZVelocity = HorizontalVelocity * DiveDirection.z

func Jump():
	SkidTimer = 0
	Jumping = true
	JumpTimer = 0.1

	if Crouching:
		Crouching = false
		SetHeight(StandHeight)
		YVelocity = ShortJumpPower
	else:
		YVelocity = JumpPower
		await get_tree().create_timer(0.1).timeout
		if !HoldingSpace && !is_on_floor():
			YVelocity = ShortJumpPower

func Dive():
	Diving = true
	DiveDirection = LastDirection
	HorizontalVelocity = DiveSpeed
	YVelocity = DiveLaunch

func _ready() -> void:
	floor_snap_length = 0.6
	floor_constant_speed = true
	floor_stop_on_slope = true
	CollisionMesh.shape = CollisionMesh.shape.duplicate()
	BeanMesh.mesh = BeanMesh.mesh.duplicate()
	pass

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Jump") && !Jumping && is_on_floor():
		HoldingSpace = true
		Jump()
	elif event.is_action_released("Jump"):
		HoldingSpace = false
	elif event.is_action_pressed("Dive") && !is_on_floor():
		Dive()
	elif event.is_action_pressed("Crouch") && is_on_floor():
		if !Crouching:
			Crouching = true
			SetHeight(CrouchHeight)
		elif not test_move(global_transform, Vector3(0, StandHeight - CrouchHeight, 0)):
			Crouching = false
			SetHeight(StandHeight)

func _physics_process(Delta: float) -> void:
	var Input2D = Input.get_vector("Left", "Right", "Down", "Up")
	MaxDirection = TwistPivot.global_transform.basis * Vector3(Input2D.x, 0, -Input2D.y)
	if SkidTimer > 0: SkidTimer -= Delta
	if JumpTimer > 0: JumpTimer -= Delta
	Skidding = SkidTimer > 0
	Jumping = JumpTimer > 0

	MaxDirection.y = 0
	MaxDirection = MaxDirection.normalized()
	Direction = Direction.lerp(MaxDirection, 0.2)

	if is_on_floor() && LastDirection.dot(MaxDirection) < -0.5 && !Skidding && !Crouching && HorizontalVelocity > Speed * 0.75:
		SkidDirection = LastDirection
		SkidTimer = 0.3
		Skidding = true

	HorizontalVelocityHandler(Delta)

	if is_on_floor():
		if !Jumping: YVelocity = 0
		Diving = false
	else:
		if Crouching:
			Crouching = false
			SetHeight(StandHeight)
		YVelocity -= Gravity * Delta

	self.velocity = Vector3(XVelocity, YVelocity, ZVelocity)
	move_and_slide()
	AlignToFloor(Delta)
