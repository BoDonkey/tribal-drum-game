extends Node3D

func _ready():
	# Get reference to the ResourceBase instance
	var resource_base = $ResourceBase
	
	# Set specific properties for Spring Moss
	resource_base.get_node("Model").mesh.material = StandardMaterial3D.new()
	resource_base.get_node("Model").mesh.material.albedo_color = Color(0.2, 0.8, 0.3)  # Bright green
	resource_base.resource_name = "Spring Moss"
	resource_base.resource_type = "plant"
	
	# Add to appropriate group
	resource_base.add_to_group("spring_resources")
