extends Node3D

@export var isTowerEnabled = false

# Called when the node enters the scene tree for the first time.
func _ready():
  get_node("map/drone_tower").set_enabled(isTowerEnabled)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
  pass
