extends Spatial

const rot_speed = 0.3
onready var planet:Planet = $Planet

func _ready():
	pass

func _process(delta):
	planet.rotate(Vector3.UP, rot_speed * delta)
