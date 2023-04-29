extends CharacterBody3D

const SPEED = 5.0

var box_to_pickup : Node3D = null

func _physics_process(delta):
  var current_position = global_position
  var destination_dir = current_position

  if box_to_pickup:
    destination_dir = box_to_pickup.global_position

  destination_dir.y = current_position.y

  look_at(destination_dir, Vector3.UP)

  var direction = (destination_dir - current_position).normalized()

  if direction:
    velocity.x = direction.x * SPEED
    velocity.z = direction.z * SPEED
  else:
    velocity.x = move_toward(velocity.x, 0, SPEED)
    velocity.z = move_toward(velocity.z, 0, SPEED)

  move_and_slide()

func pickup_box(box):
  if box_to_pickup:
    return false

  box_to_pickup = box