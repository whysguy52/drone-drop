extends CharacterBody3D

const FLY_HEIGHT = 12
const SPEED = 500 # 999 for testing
const DISTANCE_THRESHOLD = 0.3

var hp = 2
var destination_position : Vector3 = Vector3.ZERO
var box_to_pickup = null # NOTE: this is a Box, dunno how to import class/script type names yet
var box_to_deliver = null # NOTE: this is a Box, dunno how to import class/script type names yet
var deliver_box_location : Node3D = null
var go_to_height = false
var go_to_warehouse = false
var will_be_destroyed = false

@onready var warehouse = get_node('/root/world/warehouse')
@onready var drone_spawn_location = get_node('/root/world/warehouse/drone_spawn_location')
@onready var ui = get_node('/root/world/camera_controller/camera/user_interface')
@onready var money_ui = get_node('/root/world/camera_controller/camera/money_ui')


func _read(delta):
  $hp_label.text = str(hp)

func _physics_process(delta):
  movement(delta)
  #print("Drone height: ",global_position.y)

func movement(delta):
  if destination_position == Vector3.ZERO:
    if $audio_movement.playing:
      $audio_movement.stop()
    return

  if !$audio_movement.playing:
    $audio_movement.play()

  movement_pickup(delta)
  movement_deliver(delta)
  movement_go_to_height(delta)
  movement_go_to_warehouse(delta)
  move_and_slide()

func move_laterally(delta):
  var horz_position = global_position
  horz_position.y = destination_position.y

  if horz_position.x != destination_position.x && horz_position.z != destination_position.z:
    var look_at_position = destination_position
    look_at_position.y = global_position.y
    look_at(look_at_position, Vector3.UP)

  if horz_position.distance_to(destination_position) < DISTANCE_THRESHOLD:
    # lock into dest x/z since we're close enough
    horz_position.x = destination_position.x
    horz_position.z = destination_position.z
    global_position.x = destination_position.x
    global_position.z = destination_position.z

  var direction = (destination_position - horz_position).normalized()

  if direction:
    velocity.x = direction.x * SPEED * delta
    velocity.z = direction.z * SPEED * delta
    return false
  else:
    velocity.x = move_toward(velocity.x, 0, SPEED * delta)
    velocity.z = move_toward(velocity.z, 0, SPEED * delta)
    return true

func movement_pickup(delta):
  if go_to_height or !box_to_pickup:
    return

  if !move_laterally(delta):
    return

  # reached box x,z
  if $box_location.global_position.distance_to(box_to_pickup.global_position) < DISTANCE_THRESHOLD:
    # pickup box and prep to go to height
    box_to_deliver = box_to_pickup
    box_to_deliver.reparent($box_location)
    box_to_pickup = null
    warehouse.get_node('box_timer').start()
    go_to_height = true
    destination_position = global_position
    destination_position.y = FLY_HEIGHT
    return

  move_down_to(box_to_pickup, delta)

func move_down_to(node, delta):
  var direction = (node.global_position - global_position).normalized()

  if direction:
    velocity.y = direction.y * SPEED * delta
  else:
    velocity.y = move_toward(velocity.y, 0, SPEED * delta)

func movement_go_to_height(delta):
  if !go_to_height:
    return

  var dist = global_position.distance_to(destination_position)
  if dist < DISTANCE_THRESHOLD:
    global_position = destination_position

  var direction = (destination_position - global_position).normalized()

  if direction:
    velocity.y = direction.y * SPEED * delta
  else:
    velocity.y = move_toward(velocity.y, 0, SPEED * delta)
    go_to_height = false

    if box_to_pickup:
      destination_position = box_to_pickup.global_position
      destination_position.y = global_position.y
    elif deliver_box_location:
      # finished delivering a box, and reached fly height, go back to warehouse
      deliver_box_location = null
      go_to_warehouse = true
      destination_position = drone_spawn_location.global_position

func movement_deliver(delta):
  if go_to_height or !box_to_deliver:
    return

  if !deliver_box_location:
    deliver_box_location = box_to_deliver.delivery_area
    destination_position = box_to_deliver.delivery_area.global_position
  else:
    # found a deliver_box_location, move x,z there
    if !move_laterally(delta):
      return

    # reached box x,z
    if $box_location.global_position.distance_to(deliver_box_location.global_position) < DISTANCE_THRESHOLD:
      # deliver box and prep to go to height
      var house = deliver_box_location.get_parent()
      house.deliver_box(box_to_deliver)
      warehouse.delivered_boxes += 1
      money_ui.update_ui()

      box_to_deliver = null
      go_to_height = true
      destination_position = global_position
      destination_position.y = FLY_HEIGHT

      warehouse.delivered_box()
      return

    move_down_to(deliver_box_location, delta)

func movement_go_to_warehouse(delta):
  if go_to_height or !go_to_warehouse:
    return

  if !move_laterally(delta):
    return

  # reached warehouse drone spawn location x,z
  if global_position.distance_to(drone_spawn_location.global_position) < DISTANCE_THRESHOLD:
    # mark for destruction
    will_be_destroyed = true
    queue_free()
    ui.update_ui()
    return

  move_down_to(drone_spawn_location, delta)

func pickup_box(box):
  if destination_position != Vector3.ZERO or box_to_pickup or box_to_deliver or deliver_box_location or go_to_height:
    return false

  destination_position = global_position
  destination_position.y = FLY_HEIGHT
  go_to_height = true
  box_to_pickup = box

func hit():
  hp -= 1
  if hp == 0:
    kill()

func kill():
  $death_explosion.play()
  will_be_destroyed = true
  warehouse.drone_destroyed()
  queue_free()
