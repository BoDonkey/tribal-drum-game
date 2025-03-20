# Dual Fast Travel System: Pedestals & Aurora Pathways

This document outlines a two-tiered fast travel system that provides both regular transportation options and special access to unique locations.

## Core Fast Travel: Wayfinding Pedestal Network

### Concept & Lore
The ancient wayfinding pedestals form a practical network that once helped Guardians navigate between seasonal regions. By restoring these damaged structures, the player gradually rebuilds this network, making regular travel between discovered locations possible.

### Discovery & Activation
1. **Finding Pedestals**
   - Pedestals appear as damaged stone structures with misaligned runes
   - Each region contains 5-7 pedestals in key locations
   - Companions can sense nearby pedestals (subtle animation when close)
   - Dream journal may contain clues to important pedestal locations

2. **Restoration Process**
   - Apply Memory Dust to reveal original configuration
   - Use drumming to stabilize the disrupted energy
   - Physically realign stones and runes
   - Pedestal activates with a surge of seasonal energy

3. **Progression System**
   - **Early Game**: Travel only between pedestals in the same region
   - **Mid-Game**: Unlock travel between adjacent seasonal regions
   - **Late Game**: Full network access between all restored pedestals

### Gameplay Implementation
```gdscript
# Pedestal States
enum PedestalState {UNDISCOVERED, DISCOVERED, RESTORED}

# Stores all pedestals and their states
var pedestals = {
  # Format: "pedestal_id": {"region": "spring", "state": PedestalState.UNDISCOVERED}
}

# Unlocks as player progresses through story
var travel_capabilities = {
  "same_region": true,  # Available from start once pedestals are restored
  "adjacent_regions": false,  # Unlocks after specific quest
  "all_regions": false  # Unlocks late in main story
}

# Check if travel is possible between two pedestals
func can_travel_between(origin_id, destination_id):
  var origin = pedestals[origin_id]
  var destination = pedestals[destination_id]
  
  # Both must be restored
  if origin["state"] != PedestalState.RESTORED or destination["state"] != PedestalState.RESTORED:
    return false
  
  # Same region travel
  if origin["region"] == destination["region"]:
    return travel_capabilities["same_region"]
  
  # Adjacent region travel
  if are_regions_adjacent(origin["region"], destination["region"]):
    return travel_capabilities["adjacent_regions"]
  
  # Any region travel
  return travel_capabilities["all_regions"]
```

### Visual & Interactive Elements
1. **Activation Animation**
   - Runes illuminate with seasonal color
   - Energy pulse radiates outward from restored pedestal
   - Subtle ambient sound indicates active state

2. **Travel Process**
   - Player interacts with restored pedestal
   - Map interface appears showing other connected pedestals
   - Upon selection, brief drumming animation occurs
   - Screen transition effect themed to the destination's season
   - Player appears at destination pedestal with arrival animation

3. **UI Integration**
   - World map shows discovered pedestals with color-coding by region
   - Available connections shown as lines of energy between points
   - Unavailable connections (due to progression) shown as dotted lines

## Special Access: Aurora Pathway System

### Concept & Lore
The aurora pathways represent a more mystical form of travel, connecting special locations that hold deep spiritual significance. These pathways flow through the sky during aurora events, allowing access to hidden or sacred places that cannot be reached by conventional means.

### Activation Requirements
1. **Aurora Conditions**
   - Natural aurora events (occur regularly in Winter region, rarely elsewhere)
   - Summoned auroras (using special drum patterns or ritual sites)
   - Strongest during seasonal transitions or celestial events

2. **Required Components**
   - Aurora Crystal (found or crafted item that resonates with aurora energy)
   - Aurora Basin locations (natural formations that connect to the sky)
   - Knowledge of the Aurora Calling drum pattern

### Special Destinations
Aurora pathways provide exclusive access to:
1. **Harmony Confluence** - The sacred meeting point of all seasons
2. **Ancient Shrines** - Powerful spiritual sites hidden from normal access
3. **Dream Realms** - Physical locations where dream journeys can be initiated
4. **Fifth Season Boundaries** - Gateways to areas influenced by chaos energy

### Gameplay Implementation
```gdscript
# Aurora Travel System
extends Node

# Aurora conditions
var aurora_active = false
var aurora_intensity = 0.0  # 0.0 to 1.0
var celestial_event_active = false

# Known aurora anchors
var aurora_anchors = {}  # Format: "anchor_id": {"region": "winter", "discovered": false}
var aurora_pathways = {}  # Format: "origin_id-destination_id": {"discovered": false, "requirement": "none/item/ritual"}

# Check if aurora travel is possible
func can_use_aurora_travel():
  # Basic requirement - aurora must be active
  if not aurora_active:
    return false
  
  # Player must have aurora crystal or equivalent item
  if not player.has_item("aurora_crystal"):
    return false
    
  return true

# Check if specific pathway is available
func is_pathway_available(origin_id, destination_id):
  var pathway_id = origin_id + "-" + destination_id
  
  # Must know both anchor points
  if not aurora_anchors[origin_id]["discovered"] or not aurora_anchors[destination_id]["discovered"]:
    return false
  
  # Check if pathway is discovered
  if not aurora_pathways.has(pathway_id) or not aurora_pathways[pathway_id]["discovered"]:
    return false
  
  # Check special requirements
  var req = aurora_pathways[pathway_id]["requirement"]
  if req == "item" and not player.has_item("pathway_key_" + pathway_id):
    return false
  if req == "ritual" and not player.knows_ritual("pathway_ritual_" + pathway_id):
    return false
  
  # Check aurora intensity for distant travel
  if get_anchor_distance(origin_id, destination_id) > 1000:
    return aurora_intensity >= 0.7
  
  return true

# Initiate aurora travel
func travel_aurora_pathway(origin_id, destination_id):
  # Begin travel sequence
  play_aurora_drums_animation()
  
  # Create visual effect of player transforming into light
  play_ascension_effect()
  
  # Move along aurora path
  move_through_aurora(origin_id, destination_id)
  
  # Arrival sequence
  play_descent_effect()
  
  # Aftermath - aurora crystal might be depleted or need recharging
  deplete_aurora_crystal()
```

### Visual & Interactive Elements
1. **Aurora Detection**
   - Sky effects indicate when aurora travel is possible
   - Aurora crystal glows when near an anchor point
   - Companions react to aurora conditions (especially Frost)

2. **Travel Experience**
   - Player performs Aurora Calling drum pattern
   - Character transforms into streaming light
   - Camera follows light path through auroras in sky
   - Brief glimpses of other potential pathways visible during travel
   - Descent at destination with shower of light particles

3. **UI Elements**
   - Special map layer shows discovered aurora anchor points
   - Available pathways appear only during active auroras
   - Subtle compass indicator points to nearest anchor when aurora is active

## Combined System Benefits

### Strategic Travel Choices
- Regular travel keeps the game world connected and accessible
- Special destinations require effort and timing to access
- Players must plan around aurora events for certain quests

### Thematic Integration
- Both systems reinforce the game's focus on restoration and connection
- Travel methods reflect the spiritual framework of the game world
- Visual spectacle of aurora travel provides memorable moments

### Progression Feel
- Expanding travel options mark player progress
- Aurora travel capabilities grow with player's spiritual attunement
- Access to sacred locations feels earned and special

## Implementation Timeline

### Phase 1: Basic Pedestal System
- Create fundamental pedestal restoration mechanic
- Implement same-region travel functionality
- Establish visual language for active/inactive pedestals

### Phase 2: Aurora Framework
- Add aurora sky effects and conditions
- Implement first aurora anchor points in Winter region
- Create aurora crystal item and basic interaction

### Phase 3: Full Integration
- Connect both systems to world progression
- Implement special destinations accessible only via aurora
- Add drumming patterns specific to each travel method
- Create tutorial moments for introducing each travel system

## Additional Considerations

### Accessibility Options
- Allow for simplified interaction for players who struggle with rhythm mechanics
- Provide clear visual feedback when travel options are available
- Create shortcut options for frequently used travel points

### Balance and Pacing
- Pedestal locations spaced to encourage exploration without frustration
- Aurora events frequent enough to be useful but rare enough to feel special
- Key story locations accessible via pedestals, with optional aurora-only areas

### Companion Integration
- Each companion provides unique benefits to travel:
  - Bloom can extend pedestal connection range in Spring region
  - Ember can temporarily enhance aurora visibility
  - Wispy can sense aurora pathways even when inactive
  - Frost can stabilize aurora pathways for longer duration
