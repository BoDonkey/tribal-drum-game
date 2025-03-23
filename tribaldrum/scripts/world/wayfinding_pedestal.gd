# wayfinding_pedestal.gd
extends StaticBody3D

signal pedestal_restored

enum PedestalState {DAMAGED, DISCOVERED, RESTORED}
enum RegionType {SPRING, SUMMER, AUTUMN, WINTER, CHAOS}

@export var region_type: RegionType = RegionType.SPRING
@export var pedestal_id: String = ""

var current_state = PedestalState.DAMAGED
var rune_configuration = []

# References to node children
@onready var interaction_area = $InteractionArea
@onready var rune_container = $RuneContainer
@onready var activation_particles = $ActivationParticles

# Called when the node enters the scene tree for the first time
func _ready():
    # Generate a unique ID if none provided
    if pedestal_id.is_empty():
        pedestal_id = "pedestal_" + RegionType.keys()[region_type] + "_" + str(randi())
    
    # Set up initial appearance based on state
    update_appearance()
    
    # Generate random rune configuration
    generate_rune_configuration()
    
    # Connect signals
    interaction_area.connect("body_entered", Callable(self, "_on_body_entered"))
    interaction_area.connect("body_exited", Callable(self, "_on_body_exited"))

# Set the pedestal's region type
func set_region_type(type):
    region_type = type
    update_appearance()

# Set the pedestal's state
func set_state(state_name):
    match state_name.to_lower():
        "damaged":
            current_state = PedestalState.DAMAGED
        "discovered":
            current_state = PedestalState.DISCOVERED
        "restored":
            current_state = PedestalState.RESTORED
    
    update_appearance()

# Update visual appearance based on state and region
func update_appearance():
    # Base color based on region
    var region_colors = {
        RegionType.SPRING: Color(0.2, 0.8, 0.2),  # Green
        RegionType.SUMMER: Color(0.9, 0.7, 0.1),  # Gold
        RegionType.AUTUMN: Color(0.8, 0.4, 0.1),  # Orange
        RegionType.WINTER: Color(0.6, 0.8, 1.0),  # Light blue
        RegionType.CHAOS: Color(0.6, 0.1, 0.6)    # Purple
    }
    
    # Apply base color to material
    var material = $PedestalMesh.get_active_material(0)
    if material:
        material.albedo_color = region_colors[region_type]
        
        # Apply state-based modifications
        match current_state:
            PedestalState.DAMAGED:
                # Darker, with cracks
                material.albedo_color = material.albedo_color.darkened(0.5)
            PedestalState.DISCOVERED:
                # Slightly glowing
                material.emission_enabled = true
                material.emission = material.albedo_color
                material.emission_energy = 0.3
            PedestalState.RESTORED:
                # Brightly glowing
                material.emission_enabled = true
                material.emission = material.albedo_color
                material.emission_energy = 1.0
    
    # Show/hide runes based on state
    if rune_container:
        rune_container.visible = current_state != PedestalState.DAMAGED
        
        for rune in rune_container.get_children():
            if rune is MeshInstance3D:
                var rune_material = rune.get_active_material(0)
                if rune_material:
                    rune_material.emission_enabled = current_state == PedestalState.RESTORED
                    rune_material.emission_energy = 2.0 if current_state == PedestalState.RESTORED else 0.0
    
    # Enable/disable particles based on state
    if activation_particles:
        activation_particles.emitting = current_state == PedestalState.RESTORED

# Generate random rune configuration (puzzle elements)
func generate_rune_configuration():
    # Number of runes to place
    var rune_count = 4 + randi() % 3  # 4-6 runes
    
    # Possible positions around the pedestal
    var positions = []
    for i in range(8):
        var angle = i * TAU / 8
        var radius = 0.6
        positions.append(Vector3(cos(angle) * radius, 0.8, sin(angle) * radius))
    
    # Shuffle positions
    positions.shuffle()
    
    # Create runes at selected positions
    for i in range(rune_count):
        if i >= positions.size():
            break
            
        var rune = create_rune(positions[i])
        rune_configuration.append({
            "position": positions[i],
            "rotation": Vector3(0, randf() * TAU, 0),
            "color": get_rune_color(),
            "node": rune
        })

# Create a rune mesh at the specified position
func create_rune(position):
    var rune = MeshInstance3D.new()
    rune.name = "Rune_" + str(rune_container.get_child_count())
    
    # Create rune mesh
    var mesh = CylinderMesh.new()
    mesh.top_radius = 0.1
    mesh.bottom_radius = 0.1
    mesh.height = 0.1
    
    # Create rune material
    var material = StandardMaterial3D.new()
    material.albedo_color = get_rune_color()
    material.emission_enabled = current_state == PedestalState.RESTORED
    material.emission = material.albedo_color
    material.emission_energy = 2.0 if current_state == PedestalState.RESTORED else 0.0
    
    mesh.material = material
    rune.mesh = mesh
    
    # Position the rune
    rune.position = position
    rune.rotate_y(randf() * TAU)  # Random rotation
    
    # Add to rune container
    rune_container.add_child(rune)
    return rune

# Get a color for runes based on region type
func get_rune_color():
    var base_colors = {
        RegionType.SPRING: Color(0.0, 1.0, 0.3),
        RegionType.SUMMER: Color(1.0, 0.8, 0.0),
        RegionType.AUTUMN: Color(1.0, 0.4, 0.0),
        RegionType.WINTER: Color(0.5, 0.8, 1.0),
        RegionType.CHAOS: Color(0.8, 0.0, 0.8)
    }
    
    # Add some variation
    var color = base_colors[region_type]
    color.r += randf_range(-0.1, 0.1)
    color.g += randf_range(-0.1, 0.1)
    color.b += randf_range(-0.1, 0.1)
    
    return color

# Called when a body enters the interaction area
func _on_body_entered(body):
    if body.is_in_group("player"):
        # Highlight the pedestal
        highlight(true)
        
        # If player has a method to register interactive objects, call it
        if body.has_method("register_interactive_object"):
            body.register_interactive_object(self)

# Called when a body exits the interaction area
func _on_body_exited(body):
    if body.is_in_group("player"):
        # Remove highlight
        highlight(false)
        
        # If player has a method to unregister interactive objects, call it
        if body.has_method("unregister_interactive_object"):
            body.unregister_interactive_object(self)

# Highlight the pedestal when player is nearby
func highlight(enabled):
    var material = $PedestalMesh.get_active_material(0)
    if material:
        if enabled:
            material.emission_energy += 0.5
        else:
            material.emission_energy = current_state == PedestalState.RESTORED ? 1.0 : 0.3

# Apply memory dust to reveal original configuration
func apply_memory_dust():
    if current_state == PedestalState.DAMAGED:
        # Change state to discovered
        current_state = PedestalState.DISCOVERED
        update_appearance()
        
        # Show ghost images of correct rune positions
        reveal_correct_configuration()
        
        return true
    return false

# Reveal the correct configuration as ghost images
func reveal_correct_configuration():
    # In a full implementation, this would show ghostly outlines
    # of where runes should be placed
    
    # For now, just highlight the runes
    for i in range(rune_configuration.size()):
        var rune = rune_configuration[i]["node"]
        if rune is MeshInstance3D:
            var material = rune.get_active_material(0)
            if material:
                material.emission_enabled = true
                material.emission_energy = 0.5

# Try to restore the pedestal with a drum pattern
func attempt_restoration(drum_pattern):
    if current_state == PedestalState.DISCOVERED:
        # In a full implementation, check if the pattern matches
        # the required restoration pattern for this pedestal
        
        # For now, any drum pattern works
        restore_pedestal()
        return true
    return false

# Restore the pedestal to working order
func restore_pedestal():
    current_state = PedestalState.RESTORED
    update_appearance()
    
    # Play restoration effects
    $ActivationParticles.emitting = true
    $RestorationSound.play()
    
    # Emit signal
    emit_signal("pedestal_restored", self)

# Attempt to travel to another pedestal
func initiate_travel(destination_pedestal):
    if current_state != PedestalState.RESTORED:
        return false
    
    # In a full implementation, this would trigger the travel sequence
    # For now, just emit a signal that could be caught by a travel manager
    emit_signal("travel_initiated", self, destination_pedestal)
    return true