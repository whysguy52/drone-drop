extends Control

@onready var warehouse = get_node('/root/world/warehouse')

func _ready():
  update_ui()

func update_ui():
  $outer_margin/inner_margin/h_info_container/max_value.text = str(warehouse.max_drones)
  $outer_margin/inner_margin/h_info_container/available_value.text = str(warehouse.max_drones - warehouse.working_drones_count())

func update_def_ui():
  $outer_margin/inner_margin/h_info_container/max_def_drone_value.text = str(warehouse.max_def_drones)
  $outer_margin/inner_margin/h_info_container/available_def_drone_value.text = str(warehouse.max_def_drones - warehouse.deployed_def_drones_count())
