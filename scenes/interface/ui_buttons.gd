extends HBoxContainer

var tower_to_buy = null

@onready var warehouse = get_node('/root/world/warehouse')

func _process(_delta):
  if Input.is_action_just_pressed("deploy_button"):
    warehouse.deploy_def_drone()

func _on_buy_drone_button_pressed():
  warehouse.buy_drone()

func _on_buy_tower_button_pressed():
  warehouse.buy_tower(tower_to_buy)

func _on_buy_def_drone_button_pressed():
  warehouse.buy_def_drone()

func _on_deploy_button_pressed():
  warehouse.deploy_def_drone()
