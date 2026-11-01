extends CharacterBody3D

const Speed = 15
const CrouchingSpeed = 9
const DashSpeed = 22
const DashLaunch = 15
const Gravity = 40
const JumpPower = 17
const AirJumpPower = 13.5
const ShortJumpPower = 10
const MaxAirJumps = 2
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
var CurrentAirJumps = 0
var Direction = Vector3.ZERO
var MaxDirection = Vector3.ZERO
var LastDirection = Vector3.ZERO
var DashDirection = Vector3.ZERO
var BonkDirection = Vector3.ZERO
var SkidDirection = Vector3.ZERO
var CurrentNormal = Vector3.UP
var HoldingSpace = false
var CanDash = false
var Jumping = false
var Skidding = false
var Crouching = false
var Dashing = false
var Bonked = false

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
	if !Skidding && !Dashing && !Bonked:
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
	elif !Dashing && !Bonked:
		HorizontalVelocity *= exp(-SkidDeceleration * Delta)
		XVelocity = HorizontalVelocity * SkidDirection.x
		ZVelocity = HorizontalVelocity * SkidDirection.z
	elif !Bonked:
		XVelocity = HorizontalVelocity * DashDirection.x
		ZVelocity = HorizontalVelocity * DashDirection.z
	else:
		LastDirection = BonkDirection
		XVelocity = HorizontalVelocity * BonkDirection.x
		ZVelocity = HorizontalVelocity * BonkDirection.z

func Jump():
	SkidTimer = 0
	Jumping = true
	JumpTimer = 0.1

	if is_on_floor():
		if Crouching:
			Crouching = false
			SetHeight(StandHeight)
			YVelocity = ShortJumpPower
		else:
			YVelocity = JumpPower
			await get_tree().create_timer(0.1).timeout
			if !HoldingSpace && !is_on_floor():
				YVelocity = ShortJumpPower
	else:
		if CurrentAirJumps > 0:
			CurrentAirJumps -= 1
			if Dashing: Dashing = false
			YVelocity = AirJumpPower

func Dash():
	CanDash = false
	Dashing = true
	DashDirection = LastDirection
	HorizontalVelocity = DashSpeed
	YVelocity = DashLaunch

func Bonk(WallNormal):
	Bonked = true
	BonkDirection = -DashDirection.reflect(WallNormal)
	YVelocity = HorizontalVelocity / 2
	HorizontalVelocity /= 2
	pass

func _ready() -> void:
	floor_snap_length = 0.6
	floor_constant_speed = true
	floor_stop_on_slope = true
	CollisionMesh.shape = CollisionMesh.shape.duplicate()
	BeanMesh.mesh = BeanMesh.mesh.duplicate()
	pass

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Jump"): HoldingSpace = true
	if event.is_action_released("Jump"): HoldingSpace = false
	if event.is_action_pressed("Jump") && !Jumping && !Bonked:
		Jump()
	elif event.is_action_pressed("Dash") && !is_on_floor() && CanDash && !Bonked:
		Dash()
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
	Direction = Direction.lerp(MaxDirection, (0.15 if is_on_floor() else 0.2))

	if is_on_floor() && LastDirection.dot(MaxDirection) < -0.5 && !Skidding && !Crouching && HorizontalVelocity > Speed * 0.75:
		SkidDirection = LastDirection
		SkidTimer = 0.3
		Skidding = true

	HorizontalVelocityHandler(Delta)

	if is_on_floor():
		if !Jumping:
			CurrentAirJumps = MaxAirJumps
			YVelocity = 0
		CanDash = true
		Bonked = false
		Dashing = false
	else:
		if Crouching:
			Crouching = false
			SetHeight(StandHeight)
		YVelocity -= Gravity * Delta

	self.velocity = Vector3(XVelocity, YVelocity, ZVelocity)
	move_and_slide()

	if Dashing && is_on_wall() && !Bonked:
		if DashDirection.dot(get_wall_normal()) < -0.5:
			Bonk(get_wall_normal())

	AlignToFloor(Delta)
