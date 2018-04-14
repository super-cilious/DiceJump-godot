extends RigidBody

onready var cam = get_node("../InterpolatedCamera")
onready var game = global.get_game()

var initial_transform = self.transform
const zerovector = Vector3(0,0,0)

var jumpcooldown = 3
var livejumpcooldown = 0
var death = false

var torque = zerovector
var vjump = Vector3(0,10,0)
const vforward = Vector3(-5,0,0)
const vbackward = Vector3(5,0,0)
const vleft = Vector3(0,0,2)
const vright = Vector3(0,0,-2)

var vel = zerovector
var speed = 2

var rotateangle = 0.1

signal use_power (newpower, oldpower)

func _death(reason):
	death = true
func _checkpoint ():
	initial_transform = self.transform


func _ready():
	game.connect("death", self, "_death")
	game.connect("checkpoint", self, "_checkpoint")

func moveWASD (input, dirvel):
		if Input.is_action_pressed(input):
			var rad = global.degreetoradian(cam.rotation_degrees.y)
			torque+=(dirvel*speed).rotated(Vector3(0,1,0),rad)

func _process(delta):
	vel = global.zerovector
	torque = global.zerovector
	
	if Input.is_action_pressed("move_jump") and livejumpcooldown <= 0:
		livejumpcooldown = jumpcooldown
		vel += vjump
		
	moveWASD("move_forward",vforward)
	moveWASD("move_backward",vbackward)
	moveWASD("move_left",vleft)
	moveWASD("move_right",vright)
	
	if livejumpcooldown > 0:
		livejumpcooldown = livejumpcooldown - delta

func _integrate_forces(state):
	state.apply_torque_impulse(torque)
	set_axis_velocity(vel)
	
	if death:
		state.transform = initial_transform
		state.linear_velocity = Vector3(0,0,0)
		state.angular_velocity = Vector3(0,0,0)
		
		death = false

# POWERUPS

var slot = gamedata.Slot		
var currentpower = slot.None

func reset_powers():
	jumpcooldown = 3

func _on_RigidBody_body_shape_entered(body_id, body, body_shape, local_shape):
	var power = game.get_loadout()[local_shape]
	if currentpower != power:
		reset_powers()
	
	emit_signal("use_power", power, currentpower)
	
	currentpower = power
	if power == slot.TripleJump:
		jumpcooldown = 0.5