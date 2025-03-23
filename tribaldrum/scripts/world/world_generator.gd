# world_generator.gd
extends Node3D

# World size and region configuration
@export var world_size: Vector2 = Vector2(10000, 10000) # Total world dimensions
@export var region_size: Vector2 = Vector2(4000, 4000) # Size of each seasonal region
@export var chaos_region_size: Vector2 = Vector2(2000, 2000) # Size of central chaos region

# Noise generators for terrain variety
var terrain_noise: FastNoiseLite
var biome_noise: FastNoiseLite
var resource_noise: FastNoiseLite

# Region definitions
enum RegionType {SPRING, SUMMER, AUTUMN, WINTER, CHAOS}

# Region data
var regions = {
    RegionType.SPRING: {
        "position": Vector2(-region_size.x / 2, -region_size.y / 2),
        "color": Color(0.4, 0.8, 0.4), # Spring green
        "resources": [],
        "height_range": Vector2(0, 20), # Min/max height
        "height_scale": 1.0, # How dramatic the hills are
        "crafting_locations": [],
        "unlocked": true # Spring starts unlocked
    },
    RegionType.SUMMER: {
        "position": Vector2(region_size.x / 2, -region_size.y / 2),
        "color": Color(0.8, 0.7, 0.2), # Summer gold
        "resources": [],
        "height_range": Vector2(0, 25),
        "height_scale": 1.2,
        "crafting_locations": [],
        "unlocked": false
    },
    RegionType.AUTUMN: {
        "position": Vector2(-region_size.x / 2, region_size.y / 2),
        "color": Color(0.8, 0.4, 0.2), # Autumn orange
        "resources": [],
        "height_range": Vector2(0, 30),
        "height_scale": 1.5,
        "crafting_locations": [],
        "unlocked": false
    },
    RegionType.WINTER: {
        "position": Vector2(region_size.x / 2, region_size.y / 2),
        "color": Color(0.8, 0.8, 0.9), # Winter white-blue
        "resources": [],
        "height_range": Vector2(10, 40), # Higher elevations for winter
        "height_scale": 2.0,
        "crafting_locations": [],
        "unlocked": false
    },
    RegionType.CHAOS: {
        "position": Vector2(0, 0), # Center of the world
        "color": Color(0.5, 0.2, 0.5), # Chaotic purple
        "resources": [],
        "height_range": Vector2(-10, 50), # More extreme variation
        "height_scale": 3.0,
        "crafting_locations": [],
        "unlocked": false
    }
}

# Resource types for each region
var resource_types = {
    RegionType.SPRING: [
        {"scene": "res://scenes/resources/SpringMoss.tscn", "weight": 0.4, "min_height": 0, "max_height": 10},
        {"scene": "res://scenes/resources/RenewalFlower.tscn", "weight": 0.3, "min_height": 0, "max_height": 15},
        {"scene": "res://scenes/resources/Sapling.tscn", "weight": 0.2, "min_height": 5, "max_height": 15},
        {"scene": "res://scenes/resources/RiverStone.tscn", "weight": 0.1, "min_height": 0, "max_height": 5}
    ],
    # Define similar arrays for other regions
    RegionType.SUMMER: [
        {"scene": "res://scenes/resources/SunBloom.tscn", "weight": 0.4, "min_height": 5, "max_height": 20},
        {"scene": "res://scenes/resources/FireBark.tscn", "weight": 0.3, "min_height": 5, "max_height": 15},
        {"scene": "res://scenes/resources/SummerBerry.tscn", "weight": 0.2, "min_height": 0, "max_height": 20},
        {"scene": "res://scenes/resources/SunStone.tscn", "weight": 0.1, "min_height": 10, "max_height": 25}
    ],
    # Fill in autumn, winter, and chaos regions similarly
}

# Crafting location types for each region
var crafting_location_types = {
    RegionType.SPRING: [
        {"scene": "res://scenes/crafting/LivingTreeHollow.tscn", "weight": 0.5, "min_height": 5, "max_height": 15},
        {"scene": "res://scenes/crafting/SpringHaldiCircle.tscn", "weight": 0.3, "min_height": 0, "max_height": 10},
        {"scene": "res://scenes/crafting/AncestorHearth.tscn", "weight": 0.2, "min_height": 0, "max_height": 20}
    ],
    # Define similar arrays for other regions
}

# Called when the node enters the scene tree for the first time
func _ready():
    initialize_noise_generators()
    generate_world()

# Initialize noise generators with different seeds for variety
func initialize_noise_generators():
    # Terrain height noise
    terrain_noise = FastNoiseLite.new()
    terrain_noise.seed = randi()
    terrain_noise.frequency = 0.002
    terrain_noise.fractal_octaves = 5
    
    # Biome blending noise
    biome_noise = FastNoiseLite.new()
    biome_noise.seed = randi()
    biome_noise.frequency = 0.001
    
    # Resource placement noise
    resource_noise = FastNoiseLite.new()
    resource_noise.seed = randi()
    resource_noise.frequency = 0.01

# Main world generation function
func generate_world():
    generate_terrain()
    generate_region_boundaries()
    generate_resources()
    generate_crafting_locations()
    generate_wayfinding_pedestals()
    place_player_start()
    
    print("World generation complete!")

# Generate the terrain mesh
func generate_terrain():
    # Create a heightmap for the entire world
    var heightmap_size = 128 # Resolution of the heightmap
    var heightmap = generate_heightmap(heightmap_size)
    
    # Create the terrain mesh using heightmap data
    var terrain_mesh = create_terrain_mesh(heightmap, heightmap_size)
    
    # Add collision to terrain
    add_terrain_collision(terrain_mesh)
    
    # Color the terrain based on regions
    apply_terrain_textures(terrain_mesh)

# Generate heightmap based on noise and region settings
func generate_heightmap(size):
    var heightmap = []
    
    # Initialize the heightmap array
    for x in range(size):
        heightmap.append([])
        for y in range(size):
            heightmap[x].append(0.0)
    
    # Fill the heightmap with height values
    for x in range(size):
        for y in range(size):
            # Convert from heightmap coordinates to world coordinates
            var world_x = (x / float(size)) * world_size.x - world_size.x / 2
            var world_y = (y / float(size)) * world_size.y - world_size.y / 2
            
            # Determine which region this point belongs to
            var region_type = get_region_at_position(Vector2(world_x, world_y))
            var region_data = regions[region_type]
            
            # Get the base noise value
            var noise_value = terrain_noise.get_noise_2d(world_x, world_y)
            
            # Scale the noise based on the region's height settings
            var height_range = region_data["height_range"]
            var height_scale = region_data["height_scale"]
            
            # Calculate the final height
            var height = lerp(height_range.x, height_range.y, (noise_value + 1) / 2.0) * height_scale
            
            # Smooth transitions between regions
            if region_type != RegionType.CHAOS:
                # Calculate distance to region boundary
                var region_center = region_data["position"] + region_size / 2
                var distance_to_center = Vector2(world_x, world_y).distance_to(region_center)
                var max_distance = region_size.length() / 2
                
                # Smooth transition factor
                var transition = clamp(distance_to_center / max_distance, 0.0, 1.0)
                
                # Gradually lower height near boundaries
                height = lerp(height, height * 0.7, transition)
                
                # Apply extra elevation to chaos region boundary
                var chaos_distance = Vector2(world_x, world_y).length()
                var chaos_radius = chaos_region_size.x / 2
                if chaos_distance < chaos_radius * 1.2 and chaos_distance > chaos_radius * 0.8:
                    var chaos_factor = 1.0 - abs(chaos_distance / chaos_radius - 1.0) * 5
                    height += 10 * chaos_factor
            
            # Store the final height value
            heightmap[x][y] = height
    
    return heightmap

# Create the actual terrain mesh from heightmap data
func create_terrain_mesh(heightmap, size):
    var plane_mesh = PlaneMesh.new()
    plane_mesh.size = Vector2(world_size.x, world_size.y)
    plane_mesh.subdivide_width = size - 1
    plane_mesh.subdivide_depth = size - 1
    
    # Create a mesh instance
    var terrain = MeshInstance3D.new()
    terrain.mesh = plane_mesh
    terrain.name = "Terrain"
    add_child(terrain)
    
    # Apply the heightmap to the mesh
    var surface_tool = SurfaceTool.new()
    surface_tool.create_from(plane_mesh, 0)
    
    var mesh_data = surface_tool.commit()
    var vertices = mesh_data.get_vertex_array()
    
    # Apply height to each vertex
    for i in range(vertices.size()):
        var vertex = vertices[i]
        var x = int((vertex.x + world_size.x / 2) / world_size.x * size)
        var z = int((vertex.z + world_size.y / 2) / world_size.y * size)
        
        # Clamp to avoid array out of bounds
        x = clamp(x, 0, size - 1)
        z = clamp(z, 0, size - 1)
        
        # Set the vertex height
        vertex.y = heightmap[x][z]
        vertices[i] = vertex
    
    # Update the mesh with new vertices
    var arrays = []
    arrays.resize(Mesh.ARRAY_MAX)
    arrays[Mesh.ARRAY_VERTEX] = vertices
    
    # Get the rest of the mesh data
    arrays[Mesh.ARRAY_NORMAL] = mesh_data.get_normal_array()
    arrays[Mesh.ARRAY_TANGENT] = mesh_data.get_tangent_array()
    arrays[Mesh.ARRAY_TEX_UV] = mesh_data.get_uv_array()
    arrays[Mesh.ARRAY_INDEX] = mesh_data.get_index_array()
    
    # Create the final mesh
    var final_mesh = ArrayMesh.new()
    final_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
    terrain.mesh = final_mesh
    
    return terrain

# Add collision to the terrain for player interaction
func add_terrain_collision(terrain_mesh):
    var static_body = StaticBody3D.new()
    static_body.name = "TerrainCollision"
    add_child(static_body)
    
    var collision_shape = CollisionShape3D.new()
    var shape = ConcavePolygonShape3D.new()
    
    # Create collision from the terrain mesh
    shape.set_faces(terrain_mesh.mesh.get_faces())
    collision_shape.shape = shape
    static_body.add_child(collision_shape)

# Apply textures/colors to terrain based on regions
func apply_terrain_textures(terrain_mesh):
    # This is a simplified version - for better results, you'd use a shader
    # or multiple materials with texture splatting
    var surface_tool = SurfaceTool.new()
    surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    
    var mesh = terrain_mesh.mesh
    var mdt = MeshDataTool.new()
    mdt.create_from_surface(mesh, 0)
    
    # Add vertex colors based on region
    for i in range(mdt.get_vertex_count()):
        var vertex = mdt.get_vertex(i)
        var world_pos = Vector2(vertex.x, vertex.z)
        var region_type = get_region_at_position(world_pos)
        var color = regions[region_type]["color"]
        
        # Blend colors at region boundaries
        var blended_color = blend_region_colors(world_pos, region_type, color)
        
        # Add height-based variation
        if vertex.y > 20:
            # Snow caps on high mountains
            blended_color = blended_color.lerp(Color(1, 1, 1), (vertex.y - 20) / 20.0)
        elif vertex.y < 2:
            # Darker at low elevations (potential water areas)
            blended_color = blended_color.darkened(0.3)
        
        mdt.set_vertex_color(i, blended_color)
    
    # Commit changes back to the mesh
    mdt.commit_to_surface(surface_tool)
    var colored_mesh = surface_tool.commit()
    terrain_mesh.mesh = colored_mesh

# Blend colors at region boundaries for smoother transitions
func blend_region_colors(world_pos, primary_region, primary_color):
    var final_color = primary_color
    
    # Calculate distances to all region boundaries
    var blend_distances = {}
    var total_blend_factor = 0.0
    
    for region_type in regions.keys():
        if region_type == primary_region:
            continue
            
        var region_center = regions[region_type]["position"] + region_size / 2
        var distance = world_pos.distance_to(region_center)
        
        # Only blend nearby regions
        var blend_distance = 500.0 # Blend range in world units
        if distance < blend_distance:
            var blend_factor = 1.0 - (distance / blend_distance)
            blend_distances[region_type] = blend_factor
            total_blend_factor += blend_factor
    
    # If we're near boundaries, blend the colors
    if total_blend_factor > 0:
        for region_type in blend_distances.keys():
            var normalized_factor = blend_distances[region_type] / total_blend_factor
            normalized_factor *= 0.5 # Reduce the blend strength to preserve primary color
            
            final_color = final_color.lerp(regions[region_type]["color"], normalized_factor)
    
    return final_color

# Generate visual boundaries between regions
func generate_region_boundaries():
    # Create boundary markers or effects
    for region_type in regions.keys():
        var region_data = regions[region_type]
        
        if region_type == RegionType.CHAOS:
            # Special boundary for chaos region - circle of stones
            var radius = chaos_region_size.x / 2
            var stone_count = 24
            
            for i in range(stone_count):
                var angle = i * TAU / stone_count
                var pos_x = radius * cos(angle)
                var pos_z = radius * sin(angle)
                
                # Create a boundary stone
                var stone = create_boundary_marker(Vector3(pos_x, 0, pos_z), region_type)
                stone.scale = Vector3(2, 3, 2) # Larger stones for chaos boundary
                
                # Adjust height to terrain
                var terrain_height = get_terrain_height(Vector2(pos_x, pos_z))
                stone.position.y = terrain_height
        else:
            # Regular region boundaries - stones along edges
            var region_pos = region_data["position"]
            var step = 500.0 # Space between markers
            
            # Top edge
            for x in range(region_pos.x, region_pos.x + region_size.x, step):
                create_boundary_marker_at_position(Vector2(x, region_pos.y), region_type)
            
            # Bottom edge
            for x in range(region_pos.x, region_pos.x + region_size.x, step):
                create_boundary_marker_at_position(Vector2(x, region_pos.y + region_size.y), region_type)
                
            # Left edge
            for y in range(region_pos.y, region_pos.y + region_size.y, step):
                create_boundary_marker_at_position(Vector2(region_pos.x, y), region_type)
                
            # Right edge
            for y in range(region_pos.y, region_pos.y + region_size.y, step):
                create_boundary_marker_at_position(Vector2(region_pos.x + region_size.x, y), region_type)

# Create a boundary marker at a specific 2D position
func create_boundary_marker_at_position(pos_2d, region_type):
    var terrain_height = get_terrain_height(pos_2d)
    var pos_3d = Vector3(pos_2d.x, terrain_height, pos_2d.y)
    return create_boundary_marker(pos_3d, region_type)

# Create a boundary marker at a specific 3D position
func create_boundary_marker(pos_3d, region_type):
    var marker = MeshInstance3D.new()
    marker.name = "BoundaryMarker_" + str(RegionType.keys()[region_type])
    
    # Create a tall stone-like mesh
    var mesh = CylinderMesh.new()
    mesh.top_radius = 0.5
    mesh.bottom_radius = 0.8
    mesh.height = 3.0
    
    # Apply material
    var material = StandardMaterial3D.new()
    material.albedo_color = regions[region_type]["color"].darkened(0.3)
    mesh.material = material
    
    marker.mesh = mesh
    marker.position = pos_3d
    
    # Random rotation for variety
    marker.rotate_y(randf() * TAU)
    
    add_child(marker)
    return marker

# Generate and place resource objects throughout the world
func generate_resources():
    var rng = RandomNumberGenerator.new()
    rng.randomize()
    
    # Loop through each region
    for region_type in regions.keys():
        var region_data = regions[region_type]
        var resource_list = resource_types[region_type]
        
        # Skip if no resource types defined
        if resource_list.empty():
            continue
            
        var region_pos = region_data["position"]
        var region_area = region_size.x * region_size.y
        
        # Determine number of resources based on region size
        var resource_density = 0.00005 # Adjust this value to control overall density
        var resource_count = int(region_area * resource_density)
        
        # The chaos region gets fewer resources
        if region_type == RegionType.CHAOS:
            resource_count = int(resource_count * 0.5)
            
        print("Placing " + str(resource_count) + " resources in " + RegionType.keys()[region_type] + " region")
        
        # Place resources
        for i in range(resource_count):
            # Determine resource position within region
            var pos_x = region_pos.x + rng.randf() * region_size.x
            var pos_z = region_pos.y + rng.randf() * region_size.y
            
            # Adjust position for chaos region (circular)
            if region_type == RegionType.CHAOS:
                # Generate in circle instead of square
                var angle = rng.randf() * TAU
                var distance = rng.randf() * (chaos_region_size.x / 2)
                pos_x = distance * cos(angle)
                pos_z = distance * sin(angle)
            
            # Get terrain height at this position
            var terrain_height = get_terrain_height(Vector2(pos_x, pos_z))
            
            # Select resource type based on weights and height
            var selected_resource = select_resource_type(resource_list, terrain_height, rng)
            if selected_resource.empty():
                continue
                
            # Create the resource instance
            create_resource(selected_resource["scene"], Vector3(pos_x, terrain_height, pos_z), region_type)

# Select a resource type based on weights and terrain height
func select_resource_type(resource_list, height, rng):
    # Filter resources by valid height range
    var valid_resources = []
    var total_weight = 0.0
    
    for resource in resource_list:
        if height >= resource["min_height"] and height <= resource["max_height"]:
            valid_resources.append(resource)
            total_weight += resource["weight"]
    
    if valid_resources.empty() or total_weight == 0:
        return {}
        
    # Select a resource based on weights
    var selection_value = rng.randf() * total_weight
    var current_weight = 0.0
    
    for resource in valid_resources:
        current_weight += resource["weight"]
        if selection_value <= current_weight:
            return resource
            
    # Fallback to last resource if something went wrong
    return valid_resources[valid_resources.size() - 1]

# Create a resource instance at the specified position
func create_resource(resource_scene_path, position, region_type):
    # Load the resource scene
    var resource_scene = load(resource_scene_path)
    if not resource_scene:
        print("Failed to load resource scene: " + resource_scene_path)
        return null
        
    # Instance the resource
    var resource_instance = resource_scene.instantiate()
    resource_instance.position = position
    
    # Apply random rotation for variety
    resource_instance.rotate_y(randf() * TAU)
    
    # Apply random scale variation (subtle)
    var scale_var = 0.8 + randf() * 0.4 # 0.8 to 1.2
    resource_instance.scale = Vector3(scale_var, scale_var, scale_var)
    
    # Add to the world
    add_child(resource_instance)
    
    # Store in region data for management
    regions[region_type]["resources"].append(resource_instance)
    
    return resource_instance

# Generate crafting locations throughout the world
func generate_crafting_locations():
    var rng = RandomNumberGenerator.new()
    rng.randomize()
    
    # Loop through each region
    for region_type in regions.keys():
        var region_data = regions[region_type]
        
        # Skip if this region has no crafting locations defined
        if not crafting_location_types.has(region_type) or crafting_location_types[region_type].empty():
            continue
            
        var location_list = crafting_location_types[region_type]
        var region_pos = region_data["position"]
        
        # Determine number of crafting locations
        var location_count = 5 # Adjust as needed
        if region_type == RegionType.CHAOS:
            location_count = 2 # Fewer in chaos region
            
        print("Placing " + str(location_count) + " crafting locations in " + RegionType.keys()[region_type] + " region")
        
        # Place crafting locations
        for i in range(location_count):
            # Determine position within region
            var pos_x
            var pos_z
            
            if region_type == RegionType.CHAOS:
                # Place in circle
                var angle = rng.randf() * TAU
                var distance = rng.randf() * (chaos_region_size.x / 2) * 0.7 # Keep away from boundary
                pos_x = distance * cos(angle)
                pos_z = distance * sin(angle)
            else:
                # Place within region, but away from edges
                var margin = region_size.x * 0.1
                pos_x = region_pos.x + margin + rng.randf() * (region_size.x - 2 * margin)
                pos_z = region_pos.y + margin + rng.randf() * (region_size.y - 2 * margin)
            
            # Get terrain height
            var terrain_height = get_terrain_height(Vector2(pos_x, pos_z))
            
            # Select crafting location type based on weights and height
            var selected_location = select_resource_type(location_list, terrain_height, rng)
            if selected_location.empty():
                continue
                
            # Create the crafting location
            create_crafting_location(selected_location["scene"], Vector3(pos_x, terrain_height, pos_z), region_type)

# Create a crafting location at the specified position
func create_crafting_location(location_scene_path, position, region_type):
    # Load the location scene
    var location_scene = load(location_scene_path)
    if not location_scene:
        print("Failed to load crafting location scene: " + location_scene_path)
        return null
        
    # Instance the location
    var location_instance = location_scene.instantiate()
    location_instance.position = position
    
    # Apply random rotation
    location_instance.rotate_y(randf() * TAU)
    
    # Add to the world
    add_child(location_instance)
    
    # Store in region data for management
    regions[region_type]["crafting_locations"].append(location_instance)
    
    return location_instance

# Generate wayfinding pedestals for fast travel system
func generate_wayfinding_pedestals():
    var rng = RandomNumberGenerator.new()
    rng.randomize()
    
    # Load the pedestal scene
    var pedestal_scene_path = "res://scenes/world/WayfindingPedestal.tscn"
    var pedestal_scene = load(pedestal_scene_path)
    
    if not pedestal_scene:
        print("Failed to load wayfinding pedestal scene!")
        return
    
    # Place pedestals in each region
    for region_type in regions.keys():
        var region_data = regions[region_type]
        var region_pos = region_data["position"]
        
        # Determine number of pedestals for this region
        var pedestal_count = 5 # Default
        if region_type == RegionType.CHAOS:
            pedestal_count = 1 # Only one in chaos region
            
        # Place pedestals
        for i in range(pedestal_count):
            var pos_x
            var pos_z
            
            if region_type == RegionType.CHAOS:
                # Place in center of chaos region
                pos_x = 0
                pos_z = 0
            else:
                # Strategic placement based on index
                if i == 0:
                    # First pedestal near region center
                    pos_x = region_pos.x + region_size.x / 2 + rng.randf_range(-200, 200)
                    pos_z = region_pos.y + region_size.y / 2 + rng.randf_range(-200, 200)
                elif i < 4:
                    # Pedestals near each corner (but not too close to edge)
                    var margin = region_size.x * 0.2
                    var corner_x = i % 2 == 0?margin: region_size.x - margin
                    var corner_z = i < 2?margin: region_size.y - margin
                    pos_x = region_pos.x + corner_x + rng.randf_range(-100, 100)
                    pos_z = region_pos.y + corner_z + rng.randf_range(-100, 100)
                else:
                    # Additional pedestals in interesting locations
                    pos_x = region_pos.x + rng.randf() * region_size.x
                    pos_z = region_pos.y + rng.randf() * region_size.y
            
            # Get terrain height
            var terrain_height = get_terrain_height(Vector2(pos_x, pos_z))
            
            # Create pedestal
            var pedestal = pedestal_scene.instantiate()
            pedestal.position = Vector3(pos_x, terrain_height, pos_z)
            
            # Set pedestal properties
            if pedestal.has_method("set_region_type"):
                pedestal.set_region_type(region_type)
                
            # Set initial state (damaged for most, intact for spring)
            if pedestal.has_method("set_state"):
                if region_type == RegionType.SPRING and i == 0:
                    # First spring pedestal starts restored
                    pedestal.set_state("restored")
                else:
                    pedestal.set_state("damaged")
            
            add_child(pedestal)

# Place player at starting position
func place_player_start():
    # Find the player in the scene
    var player = get_node_or_null("../Player")
    if not player:
        print("Player node not found!")
        return
        
    # Place player in spring region near first pedestal
    var spring_pos = regions[RegionType.SPRING]["position"]
    var start_x = spring_pos.x + region_size.x / 2
    var start_z = spring_pos.y + region_size.y / 2
    
    # Get terrain height at start position
    var terrain_height = get_terrain_height(Vector2(start_x, start_z))
    
    # Set player position
    player.position = Vector3(start_x, terrain_height + 2.0, start_z) # Add small offset above ground
    
    print("Player placed at starting position")

# Get the region type at a specific world position
func get_region_at_position(pos):
    # Check if in chaos region first (center circle)
    var distance_to_center = pos.length()
    if distance_to_center < chaos_region_size.x / 2:
        return RegionType.CHAOS
        
    # Then check which quadrant of the world we're in
    var region_type
    if pos.x < 0 and pos.y < 0:
        region_type = RegionType.SPRING
    elif pos.x >= 0 and pos.y < 0:
        region_type = RegionType.SUMMER
    elif pos.x < 0 and pos.y >= 0:
        region_type = RegionType.AUTUMN
    else:
        region_type = RegionType.WINTER
        
    return region_type

# Get terrain height at a specific world position
func get_terrain_height(pos):
    # Use noise to get approximate height at this position
    var region_type = get_region_at_position(pos)
    var region_data = regions[region_type]
    
    # Get the base noise value
    var noise_value = terrain_noise.get_noise_2d(pos.x, pos.y)
    
    # Scale the noise based on the region's height settings
    var height_range = region_data["height_range"]
    var height_scale = region_data["height_scale"]
    
    # Calculate the final height
    var height = lerp(height_range.x, height_range.y, (noise_value + 1) / 2.0) * height_scale
    
    # Apply boundary smoothing
    if region_type != RegionType.CHAOS:
        # Calculate distance to region boundary
        var region_center = region_data["position"] + region_size / 2
        var distance_to_center = pos.distance_to(region_center)
        var max_distance = region_size.length() / 2
        
        # Smooth transition factor
        var transition = clamp(distance_to_center / max_distance, 0.0, 1.0)
        
        # Gradually lower height near boundaries
        height = lerp(height, height * 0.7, transition)
    
    # Special handling for chaos region boundary
    var chaos_distance = pos.length()
    var chaos_radius = chaos_region_size.x / 2
    if chaos_distance < chaos_radius * 1.2 and chaos_distance > chaos_radius * 0.8:
        var chaos_factor = 1.0 - abs(chaos_distance / chaos_radius - 1.0) * 5
        height += 10 * chaos_factor
    
    return height

# Unlock a previously locked region
func unlock_region(region_type):
    if regions.has(region_type) and not regions[region_type]["unlocked"]:
        # Mark region as unlocked
        regions[region_type]["unlocked"] = true
        
        # Spawn additional resources now that the region is accessible
        populate_unlocked_region(region_type)
        
        print("Region unlocked: " + RegionType.keys()[region_type])
        
        # Signal to other systems that a region was unlocked
        emit_signal("region_unlocked", region_type)

# Populate a newly unlocked region with additional content
func populate_unlocked_region(region_type):
    # This could add more resources, special landmarks, or region-specific elements
    # that weren't present while the region was locked
    # For now, we'll just add some extra resources
    var rng = RandomNumberGenerator.new()
    rng.randomize()
    
    var region_data = regions[region_type]
    var region_pos = region_data["position"]
    
    # Add some special resources that only appear in unlocked regions
    var special_resource_count = 10
    
    for i in range(special_resource_count):
        # Determine position within region
        var pos_x = region_pos.x + rng.randf() * region_size.x
        var pos_z = region_pos.y + rng.randf() * region_size.y
        
        if region_type == RegionType.CHAOS:
            # Place in circle
            var angle = rng.randf() * TAU
            var distance = rng.randf() * (chaos_region_size.x / 2)
            pos_x = distance * cos(angle)
            pos_z = distance * sin(angle)
        
        # Get terrain height
        var terrain_height = get_terrain_height(Vector2(pos_x, pos_z))
        
        # Create special resource - for now, just using regular resources
        # In a full implementation, you'd have special resource types for unlocked regions
        if resource_types.has(region_type) and not resource_types[region_type].empty():
            var selected_resource = select_resource_type(resource_types[region_type], terrain_height, rng)
            if not selected_resource.empty():
                create_resource(selected_resource["scene"], Vector3(pos_x, terrain_height, pos_z), region_type)

# Helper function to find nearest valid position for placement
func find_valid_position_near(base_position, radius_min, radius_max):
    var rng = RandomNumberGenerator.new()
    rng.randomize()
    
    # Try several positions
    for _attempt in range(10):
        # Generate random angle and distance
        var angle = rng.randf() * TAU
        var distance = rng.randf_range(radius_min, radius_max)
        
        # Calculate position
        var pos_x = base_position.x + distance * cos(angle)
        var pos_z = base_position.z + distance * sin(angle)
        
        # Get terrain height
        var terrain_height = get_terrain_height(Vector2(pos_x, pos_z))
        
        # Check if position is valid (not too steep, not underwater, etc.)
        # This is a simplified check - you might want more complex validation
        if terrain_height > 0:
            return Vector3(pos_x, terrain_height, pos_z)
    
    # If no valid position found, return the original with proper height
    var terrain_height = get_terrain_height(Vector2(base_position.x, base_position.z))
    return Vector3(base_position.x, terrain_height, base_position.z)

# Save current world state
func save_world_state():
    # Create a dictionary with all the data we want to save
    var save_data = {
        "regions": {},
        "player_position": null
    }
    
    # Save region unlock status
    for region_type in regions.keys():
        save_data["regions"][region_type] = {
            "unlocked": regions[region_type]["unlocked"]
        }
    
    # Save player position
    var player = get_node_or_null("../Player")
    if player:
        save_data["player_position"] = {
            "x": player.position.x,
            "y": player.position.y,
            "z": player.position.z
        }
    
    # Additional data like collected resources, completed quests, etc. would go here
    
    return save_data

# Load world state from saved data
func load_world_state(save_data):
    # Load region unlock status
    for region_type in save_data["regions"].keys():
        if int(region_type) in regions:
            regions[int(region_type)]["unlocked"] = save_data["regions"][region_type]["unlocked"]
            
            # If region is unlocked, ensure it's properly populated
            if regions[int(region_type)]["unlocked"] and int(region_type) != RegionType.SPRING:
                populate_unlocked_region(int(region_type))
    
    # Restore player position
    if save_data.has("player_position"):
        var player = get_node_or_null("../Player")
        if player:
            var pos = save_data["player_position"]
            player.position = Vector3(pos["x"], pos["y"], pos["z"])
    
    print("World state loaded successfully")

# Get current world season (could be influenced by game time)
# This would be expanded in your full implementation
func get_current_world_season():
    # For now, return a fixed season - in the full game, this would change over time
    return RegionType.SPRING

# Get the rarity factor for resources based on world season and region
func get_resource_rarity_factor(region_type):
    var world_season = get_current_world_season()
    
    # Resources are more abundant in their matching season
    if region_type == world_season:
        return 1.5 # 50% more resources
    
    # Resources are scarcer in the opposite season
    var opposite_seasons = {
        RegionType.SPRING: RegionType.AUTUMN,
        RegionType.SUMMER: RegionType.WINTER,
        RegionType.AUTUMN: RegionType.SPRING,
        RegionType.WINTER: RegionType.SUMMER
    }
    
    if opposite_seasons[region_type] == world_season:
        return 0.75 # 25% fewer resources
    
    # Neutral for other seasons
    return 1.0