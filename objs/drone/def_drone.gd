extends CharacterBody3D

const SPEED = 999 # 666 for real, 999 for testing
const DISTANCE_THRESHOLD = 10.0
const DISTANCE_LOCATION_THRESHOLD = 0.3

var hp = 3
var is_attacking = false
var destination_position : Vector3 = Vector3.ZERO
var target_acquired: Object
var will_be_destroyed = false
var go_to_warehouse = false

@onready var warehouse = get_node('/root/world/warehouse')
@onready var drone_spawn_location = get_node('/root/world/warehouse/drone_spawn_location')
@onready var ui = get_node('/root/world/camera_controller/camera/user_interface')

func _ready():
  find_nearest_target()
  $hp_label.text = str(hp)

func _physics_process(delta):
  movement(delta)
  attack()
  #print("Drone height: ",global_position.y)

func movement(delta):
  if target_acquired == null:
    find_nearest_target()
  else:
    update_target_position()

    if destination_position == Vector3.ZERO:
      if $audio_movement.playing:
        $audio_movement.stop()
      return

    if !$audio_movement.playing:
      $audio_movement.play()

    move_laterally(delta)
    movement_go_to_warehouse(delta)
    move_and_slide()

func move_laterally(delta):
  var horz_position = global_position
  horz_position.y = destination_position.y

  if horz_position.x != destination_position.x && horz_position.z != destination_position.z:
    var look_at_position = destination_position
    look_at_position.y = global_position.y
    look_at(look_at_position, Vector3.UP)

  var distance_threshold = DISTANCE_LOCATION_THRESHOLD if go_to_warehouse else DISTANCE_THRESHOLD

  if horz_position.distance_to(destination_position) < distance_threshold:
    # lock into dest x/z since we're close enough
    horz_position.x = destination_position.x
    horz_position.z = destination_position.z

  var direction = (destination_position - horz_position).normalized()

  if direction:
    velocity.x = direction.x * SPEED * delta
    velocity.z = direction.z * SPEED * delta
    return false
  else:
    velocity.x = move_toward(velocity.x, 0, SPEED * delta)
    velocity.z = move_toward(velocity.z, 0, SPEED * delta)
    return true

func movement_go_to_warehouse(delta):
  if !go_to_warehouse: #deleted variable go_to_height
    return

  if !move_laterally(delta):
    return

  # reached warehouse drone spawn location x,z
  if global_position.distance_to(drone_spawn_location.global_position) < DISTANCE_LOCATION_THRESHOLD:
    # mark for destruction
    will_be_destroyed = true
    queue_free()
    ui.update_def_ui()
    return

  move_down_to(drone_spawn_location, delta)

func move_down_to(node, delta):
  var direction = (node.global_position - global_position).normalized()

  if direction:
    velocity.y = direction.y * SPEED * delta
  else:
    velocity.y = move_toward(velocity.y, 0, SPEED * delta)

func find_nearest_target():

  #first check if something is already near
  var bodies_near_by = $Area3D.get_overlapping_bodies()
  for body in bodies_near_by:
    if "enemy_drone" in body.name:
      target_acquired = body
      $Timer.start()
      return
  var list_of_enemy_drones = get_node('/root/world/enemies').get_children()
  if list_of_enemy_drones.size() == 0:
    target_acquired = drone_spawn_location
    go_to_warehouse = true
    return

  var min_dist = 0
  var check_dist = 0

  for target in list_of_enemy_drones:
    check_dist = global_position.distance_to(target.global_position)
    if min_dist == 0 or check_dist < min_dist:
      min_dist = check_dist
      target_acquired = target

func update_target_position():
  destination_position = target_acquired.global_position
  #destination_position = get_node('/root/world/warehouse').global_position
    #else (if check_dist is greater than min_dist, do nothing)

func _on_area_3d_body_entered(body):
  if target_acquired and is_instance_valid(target_acquired) and target_acquired.name == "enemy_drone":
    is_attacking = true
    return #$Timer.start()
  else:
    target_acquired = body
    is_attacking = true

func _on_timer_timeout():
  if target_acquired and is_instance_valid(target_acquired) and target_acquired.name == "enemy_drone":
    target_acquired.hit()
  else:
    is_attacking = false

func attack():
  if !is_attacking or !$Timer.is_stopped():
    return
  else:
    $audio_shoot.play()
    $Timer.start()

func hit():
  hp -= 1
  $hp_label.text = str(hp)
  if hp == 0:
    kill()

func kill():
  $death_explosion.play()
  will_be_destroyed = true
  warehouse.def_drone_destroyed()
  queue_free()
