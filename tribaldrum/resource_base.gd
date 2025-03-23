extends StaticBody3D

# Resource properties
@export var resource_name: String = "Resource"
@export var resource_type: String = "misc"
@export var respawn_time: float = 10.0  # Keep short for testing

# Current state
var is_gathered: bool = false
var time_since_gathered: float = 0.0
var original_material = null

# References to child nodes
@onready var model = $Model
@onready var interaction_area = $InteractionArea

# Called when the node enters the scene tree for the first time
func _ready():
	# Add to resources group for easy finding
	add_to_group("resources")
	
	# Connect area signals
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)
	
	# Store original material
	if $Model.mesh and $Model.mesh.get_surface_count() > 0:
		original_material = $Model.get_active_material(0)
	elif $Model.mesh and $Model.mesh.material:
		original_material = $Model.mesh.material
# Called every frame
func _process(delta):
	# Handle respawning
	if is_gathered:
		time_since_gathered += delta
		if time_since_gathered >= respawn_time:
			respawn()

# Gather this resource
func gather():
	if is_gathered:
		return null
		
	is_gathered = true
	time_since_gathered = 0.0
	model.visible = false
	
	# Return resource data
	return {
		"name": resource_name,
		"type": resource_type
	}
	
# Resource respawns
func respawn():
	is_gathered = false
	model.visible = true
	
# Player entered interaction range
func _on_body_entered(body):
	if body.is_in_group("player") and not is_gathered:
		print("Player has entered!")
		# Create glow effect
		var glow_material = StandardMaterial3D.new()
		glow_material.albedo_color = Color(1, 1, 0.5)  # Yellowish color
		glow_material.emission_enabled = true
		glow_material.emission = Color(1, 1, 0.5)  # Matching emission
		glow_material.emission_energy_multiplier = 1.5
		$Model.material_override = glow_material
		
		# Register with player
		if body.has_method("register_resource"):
			print("resource registered")
			body.register_resource(self)
# Player exited interaction range
func _on_body_exited(body):
	if body.is_in_group("player"):
		# Remove glow effect
		$Model.material_override = null
		
		if body.has_method("unregister_resource"):
			body.unregister_resource(self)
