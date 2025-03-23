extends CharacterBody3D

# Player movement properties
@export var speed = 5.0
@export var jump_velocity = 4.5
@export var mouse_sensitivity = 0.002
@export var controller_sensitivity = 3.0

var current_resource = null
var inventory = []
var current_interactive_object = null
# Get the gravity from the project settings
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var game_ui = $GameUI

func _ready():
  # Capture the mouse
  Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
  add_to_group("player")

func _input(event):
  # Mouse look
  if event is InputEventMouseMotion:
    rotate_y(-event.relative.x * mouse_sensitivity)
    $Camera3D.rotate_x(-event.relative.y * mouse_sensitivity)
    $Camera3D.rotation.x = clamp($Camera3D.rotation.x, -PI / 2, PI / 2)
  
  # Exit game or release mouse with Escape
  if event.is_action_pressed("ui_cancel"):
    if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
      Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    else:
      get_tree().quit()
  
  # Gather resources with E key
  if event.is_action_pressed("gather") and current_resource != null:
    gather_resource()

  if event.is_action_pressed("interact") and current_interactive_object != null:
    interact_with_object()

func _physics_process(delta):
  # Add gravity
  if not is_on_floor():
    velocity.y -= gravity * delta

  # Handle jump
  if Input.is_action_just_pressed("ui_accept") and is_on_floor():
    velocity.y = jump_velocity

  # Get the input direction
  var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
  
  # Calculate the movement direction relative to the player's rotation
  var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
  
  # Handle movement
  if direction:
    velocity.x = direction.x * speed
    velocity.z = direction.z * speed
  else:
    velocity.x = move_toward(velocity.x, 0, speed)
    velocity.z = move_toward(velocity.z, 0, speed)
  
  var look_dir_x = Input.get_action_strength("look_right") - Input.get_action_strength("look_left")
  var look_dir_y = Input.get_action_strength("look_up") - Input.get_action_strength("look_down")
  
  if abs(look_dir_x) > 0.1 or abs(look_dir_y) > 0.1:
    rotate_y(-look_dir_x * controller_sensitivity * delta)
    $Camera3D.rotate_x(-look_dir_y * controller_sensitivity * delta)
    $Camera3D.rotation.x = clamp($Camera3D.rotation.x, -PI / 2, PI / 2)

  # Apply movement
  move_and_slide()
  
func gather_resource():
  var resource_data = current_resource.gather()
  if resource_data != null:
    inventory.append(resource_data)
    print("Gathered: " + resource_data.name)
    print("Inventory now contains " + str(inventory.size()) + " items")

# Called by resources when player enters their area
func register_resource(resource):
  current_resource = resource
  print("Can gather: " + resource.resource_name)
  game_ui.show_resource_name(resource.resource_name)

# Called by resources when player leaves their area
func unregister_resource(resource):
  if current_resource == resource:
    current_resource = null
    game_ui.clear_resource_name()

func interact_with_object():
    if current_interactive_object.has_method("attempt_restoration"):
        # For pedestals that need restoration
        if current_interactive_object.current_state == 0: # DAMAGED
            print("This pedestal needs Memory Dust to reveal its patterns.")

            # Check if player has Memory Dust
            if has_item("memory_dust"):
                current_interactive_object.apply_memory_dust()
                print("Applied Memory Dust. The pedestal's patterns are now visible.")
            else:
                print("You need Memory Dust to reveal the pedestal's patterns.")

        elif current_interactive_object.current_state == 1: # DISCOVERED
            print("This pedestal needs the right drum pattern to restore it.")

            # In a full implementation, this would open a drumming UI
            # For now, we'll just simulate a successful pattern
            var result = current_interactive_object.attempt_restoration("test_pattern")
            if result:
                print("Pedestal restored! It can now be used for travel.")
            else:
                print("The pattern didn't work. Try a different rhythm.")

        elif current_interactive_object.current_state == 2: # RESTORED
            print("This pedestal can be used for travel. Opening travel map...")

            # In a full implementation, this would open a travel UI
            # For now, we'll just print a message
            print("Travel functionality would open here")

# Called by interactive objects when player enters their area
func register_interactive_object(object):
    current_interactive_object = object

    # Give feedback based on object type
    if object.has_method("attempt_restoration"):
        match object.current_state:
            0:  # DAMAGED
                print("Damaged pedestal found. Needs Memory Dust.")
            1:  # DISCOVERED
                print("Discovered pedestal. Needs restoration through drumming.")
            2:  # RESTORED
                print("Restored pedestal. Can be used for travel.")

# Called by interactive objects when player leaves their area
func unregister_interactive_object(object):
    if current_interactive_object == object:
        current_interactive_object = null

# Check if player has a specific item
func has_item(item_name):
    for item in inventory:
        if item.has("name") and item["name"].to_lower() == item_name.to_lower():
            return true
    return false
