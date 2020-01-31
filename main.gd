extends Spatial

const rot_speed = 0.3
const ZOOM_SPEED = 1.5
const MIN_DIST = 1.1
const DRAG_SPEED = 0.1

onready var planet:Planet = $Planet
onready var camera:Camera = $Camera
onready var tween:Tween = $Tween

var target_dist:float = 4.0
var mouse_drag:bool = false
var planet_rotation:Vector2 = Vector2(0.0, 0.0)

func _ready():
	pass

func _unhandled_input(event):
	if event.is_action_pressed('camera_closer'):
		target_dist = (target_dist - MIN_DIST) * (1 / ZOOM_SPEED) + MIN_DIST
	elif event.is_action_pressed('camera_farther'):
		target_dist = (target_dist - MIN_DIST) * ZOOM_SPEED + MIN_DIST
	if event.is_action_pressed('camera_drag'):
		mouse_drag = true
	elif event.is_action_released('camera_drag'):
		mouse_drag = false
	
	if event is InputEventMouseMotion and mouse_drag:
		planet_rotation += event.relative
		

func _process(delta):
	# planet.rotate(Vector3.UP, rot_speed * delta)
	camera.translation.z = target_dist
	
	planet.rotate(planet.to_global(Vector3.UP), planet_rotation.x * delta * DRAG_SPEED)
	planet.rotate_x(planet_rotation.y * delta * DRAG_SPEED)
	planet_rotation = Vector2.ZERO
