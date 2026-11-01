extends CharacterBody3D

@onready var PitchPivot = $"../CameraNode/TwistPivot/PitchPivot"
@onready var TwistPivot = $"../CameraNode/TwistPivot"
@onready var BeanMesh = $"BeanMesh"
@onready var CollisionMesh = $"CollisionShape"

const Speed = 15.0
const CrouchingSpeed = 9.0
const DashSpeed = 22.0
const SlideSpeed = 18.0
const SlideMaxSpeed = 999.0
const SlideMinSpeed = 1.5
const SlideFriction = 0.5
const SlideSlopeStrength = 2.5
const DashLaunch = 15.0
const Gravity = 40.0
const JumpPower = 17.0
const AirJumpPower = 13.5
const ShortJumpPower = 10.0
const MaxAirJumps = 2
const StandHeight = 2.0
const CrouchHeight = 1.5
const GroundAcceleration = 3.0
const GroundDeceleration = 4.0
const AirAccelerate = 3.0
const AirDecelerate = 4.0
const SkidDeceleration = 8.0
const MaxHP = 3

var HorizontalVelocity = 0.0
var IFramesTimer = 0.0
var SkidTimer = 0.0
var JumpTimer = 0.0
var XVelocity = 0.0
var ZVelocity = 0.0
var YVelocity = 0.0
var CurrentAirJumps = 0
var HP = MaxHP
var Direction = Vector3.ZERO
var MaxDirection = Vector3.ZERO
var LastDirection = Vector3.ZERO
var DashDirection = Vector3.ZERO
var SlideDirection = Vector3.ZERO
var BonkDirection = Vector3.ZERO
var SkidDirection = Vector3.ZERO
var CurrentNormal = Vector3.UP
var HoldingSpace = false
var CanDash = false
var Jumping = false
var Skidding = false
var Crouching = false
var Dashing = false
var Sliding = false
var Bonked = false
var IFrames

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
		TargetNormal = get_floor_normal()

	CurrentNormal = CurrentNormal.lerp(TargetNormal, 1.0 - exp(-12.0 * Delta)).normalized()

	var Tilt = Basis(Quaternion(Vector3.UP, CurrentNormal))
	BeanMesh.global_transform.basis = Tilt

func HorizontalVelocityHandler(Delta):
	if Bonked:
		LastDirection = BonkDirection
		XVelocity = HorizontalVelocity * BonkDirection.x
		ZVelocity = HorizontalVelocity * BonkDirection.z
	elif Dashing:
		XVelocity = HorizontalVelocity * DashDirection.x
		ZVelocity = HorizontalVelocity * DashDirection.z
	elif Sliding:
		SlideHandler(Delta)
	elif Skidding:
		HorizontalVelocity *= exp(-SkidDeceleration * Delta)
		XVelocity = HorizontalVelocity * SkidDirection.x
		ZVelocity = HorizontalVelocity * SkidDirection.z
	else:
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

func Jump():
	if Sliding: EndSlide()
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

func EndSlide():
	Sliding = false
	LastDirection = SlideDirection

func Slide():
	Sliding = true
	SlideDirection = LastDirection
	HorizontalVelocity = max(HorizontalVelocity, SlideSpeed)

func SlideHandler(Delta):
	var Flat = SlideDirection * HorizontalVelocity
	Flat *= exp(-SlideFriction * Delta)

	if is_on_floor():
		var Slope = Vector3.DOWN.slide(get_floor_normal())
		Slope.y = 0
		Flat += Slope * Gravity * SlideSlopeStrength * Delta

	HorizontalVelocity = min(Flat.length(), SlideMaxSpeed)
	if HorizontalVelocity > 0.1:
		SlideDirection = Flat.normalized()

	XVelocity = HorizontalVelocity * SlideDirection.x
	ZVelocity = HorizontalVelocity * SlideDirection.z

func Reset():
	HorizontalVelocity = 0.0
	IFramesTimer = 0.0
	SkidTimer = 0.0
	JumpTimer = 0.0
	XVelocity = 0.0
	ZVelocity = 0.0
	YVelocity = 0.0
	CurrentAirJumps = 0
	HP = MaxHP
	Direction = Vector3.ZERO
	MaxDirection = Vector3.ZERO
	LastDirection = Vector3.ZERO
	DashDirection = Vector3.ZERO
	SlideDirection = Vector3.ZERO
	BonkDirection = Vector3.ZERO
	SkidDirection = Vector3.ZERO
	CurrentNormal = Vector3.UP
	HoldingSpace = false
	CanDash = false
	Jumping = false
	Skidding = false
	Crouching = false
	Dashing = false
	Sliding = false
	Bonked = false
	SetHeight(StandHeight)
	self.position = Vector3(0, 3, 0)

func Damaged():
	HP -= 1

	if HP >= 1:
		IFrames = true
		IFramesTimer = 3
	else:
		Reset()

func Bonk(WallNormal):
	Bonked = true
	BonkDirection = -DashDirection.reflect(WallNormal)
	YVelocity = HorizontalVelocity / 2
	HorizontalVelocity /= 2

func ChangeColor():
	var NewColor = Color.WHITE
	if Bonked:
		NewColor = Color.RED
	elif Dashing:
		NewColor = Color.GREEN
	elif Sliding:
		NewColor = Color.YELLOW
	elif Skidding:
		NewColor = Color.YELLOW_GREEN
	elif !is_on_floor():
		var PercentOfJumpsLeft = float(CurrentAirJumps) / MaxAirJumps
		NewColor = Color(0.2, 0.6, 1.0).lerp(Color.WHITE, PercentOfJumpsLeft)
	BeanMesh.material_override.albedo_color = NewColor

func _ready() -> void:
	var Mat = StandardMaterial3D.new()
	floor_snap_length = 0.6
	floor_constant_speed = true
	floor_stop_on_slope = true
	CollisionMesh.shape = CollisionMesh.shape.duplicate()
	BeanMesh.mesh = BeanMesh.mesh.duplicate()

	Mat.albedo_color = Color.WHITE
	BeanMesh.material_override = Mat

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Jump"): HoldingSpace = true
	if event.is_action_released("Jump"): HoldingSpace = false

	if event.is_action_pressed("Jump") && !Jumping && !Bonked:
		Jump()
	elif event.is_action_pressed("Dash") && !Bonked:
		if is_on_floor():
			if Crouching && !Sliding:
				Slide()
		elif CanDash && !Dashing:
			Dash()
	elif event.is_action_pressed("Crouch") && Sliding:
		EndSlide()
	elif event.is_action_pressed("Crouch") && is_on_floor():
		if !Crouching:
			Crouching = true
			SetHeight(CrouchHeight)
		elif not test_move(global_transform, Vector3(0, StandHeight - CrouchHeight, 0)):
			Crouching = false
			SetHeight(StandHeight)
	elif event.is_action_pressed("Reset"):
		Reset()

func _physics_process(Delta: float) -> void:
	var Input2D = Input.get_vector("Left", "Right", "Down", "Up")
	MaxDirection = TwistPivot.global_transform.basis * Vector3(Input2D.x, 0, -Input2D.y)
	if SkidTimer > 0: SkidTimer -= Delta
	if JumpTimer > 0: JumpTimer -= Delta
	if IFramesTimer > 0:
		IFramesTimer -= Delta
		BeanMesh.visible = int(IFramesTimer * 12) % 2 == 0
	else: 
		BeanMesh.visible = true
	Skidding = SkidTimer > 0
	Jumping = JumpTimer > 0
	IFrames = IFramesTimer > 0

	MaxDirection.y = 0
	MaxDirection = MaxDirection.normalized()
	Direction = Direction.lerp(MaxDirection, (0.15 if is_on_floor() else 0.2))

	if is_on_floor() && LastDirection.dot(MaxDirection) < -0.5 && !Skidding && !Crouching && !Sliding && HorizontalVelocity > Speed * 0.75:
		SkidDirection = LastDirection
		SkidTimer = 0.3
		Skidding = true

	HorizontalVelocityHandler(Delta)
	ChangeColor()

	if Sliding:
		var OnFlat = is_on_floor() && get_floor_angle() < deg_to_rad(5)
		if !is_on_floor() || (OnFlat && HorizontalVelocity < SlideMinSpeed):
			EndSlide()

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

	for i in get_slide_collision_count():
		var Collision = get_slide_collision(i)
		var Collider = Collision.get_collider()
		if Collider && Collider.is_in_group("HitPart") && !IFrames:
			Damaged()

	if Dashing && is_on_wall() && !Bonked:
		if DashDirection.dot(get_wall_normal()) < -0.5:
			Bonk(get_wall_normal())

	AlignToFloor(Delta)
