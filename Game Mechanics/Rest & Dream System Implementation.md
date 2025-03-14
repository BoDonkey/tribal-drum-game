# **Rest & Dream System Implementation**

## **Core Sleep Mechanics**

### **Multiple Rest Options**

To encourage regular resting without forcing players into rigid
patterns, the game should offer various rest options with different
benefits:

#### **Home Rest (Complete)**

-   Available at any of the player\'s seasonal homes

-   Full restoration of all attributes

-   Guaranteed dream delivery if attunement milestones reached

-   Additional bonuses based on home development

-   Time advancement (full night)

#### **Wilderness Rest (Basic)**

-   Available at discovered rest points throughout the world

-   Campfires, caves, ancient resting stones, fallen logs

-   Partial restoration of attributes

-   Chance for dreams (lower than at home)

-   Affected by weather and season

-   Time advancement (partial night)

#### **Meditation (Brief)**

-   Available anywhere, anytime

-   Minimal restoration

-   No dreams

-   No time advancement

-   Useful for quick rejuvenation during exploration

### **Natural Incentives for Rest**

Rather than forcing sleep through arbitrary mechanics like mandatory
tiredness, encourage rest through positive reinforcement:

1.  **Companion Needs**: Companions suggest rest after extended activity

    -   *\"Bloom seems tired. Perhaps we should find a place to rest
        soon.\"*

    -   Different companions have different stamina levels based on the
        current season

2.  **Beneficial Buffs**: Resting provides temporary bonuses

    -   Well-rested players craft more efficiently

    -   Resource detection range increases

    -   Drumming patterns become easier to perform

3.  **Time-Based Events**: Certain events only occur at specific times

    -   Some resources only appear at dawn after resting

    -   Certain spirits only manifest at night

    -   Seasonal transitions often occur while resting

4.  **Ritual Requirements**: Some rituals require the player to be
    well-rested

    -   More complex patterns require focus that comes from rest

    -   Important story rituals might specify \"Rest and prepare
        yourself for the ceremony\"

## **Dream Delivery System**

### **Dream Triggers**

\# Dream trigger variables

var pending_dreams = {}

var dream_probability = {

\"home\": 1.0, \# 100% chance at home

\"wilderness\": 0.6, \# 60% chance at wilderness rest points

\"special_location\": 0.8 \# 80% chance at special locations

}

\# Check if attunement milestone reached

func check_attunement_milestones():

for season in \[\"spring\", \"summer\", \"autumn\", \"winter\"\]:

var current_level = player_data.attunement_levels\[season\]

\# Check each threshold

for threshold in ATTUNEMENT_THRESHOLDS:

\# If we\'ve reached this threshold and haven\'t had the dream yet

if current_level \>= threshold and not
player_data.milestone_dreams_experienced\[season\]\[threshold\]:

\# Queue this dream

pending_dreams\[season\] = threshold

return true

return false

\# When player chooses to rest

func initiate_rest(rest_type):

\# Apply appropriate restoration based on rest type

apply_rest_benefits(rest_type)

\# Check if we have pending milestone dreams

var has_pending_dreams = pending_dreams.size() \> 0

\# If no pending milestone dreams, check for random dreams based on
location

var random_dream_chance = dream_probability\[rest_type\]

var trigger_random_dream = randf() \<= random_dream_chance and not
has_pending_dreams

\# Advance time

advance_game_time(rest_type)

\# Process dreams

if has_pending_dreams:

\# Select one dream if multiple are pending (prioritize main season)

var dream_season = select_priority_dream()

var dream_threshold = pending_dreams\[dream_season\]

trigger_milestone_dream(dream_season, dream_threshold)

pending_dreams.erase(dream_season)

elif trigger_random_dream:

trigger_random_dream()

### **Special Dream Locations**

Beyond homes and basic wilderness rest points, special locations can
provide unique dream experiences:

1.  **Ancient Dream Stones**: Special rest locations with higher dream
    probability

    -   Mystical stones carved with symbols

    -   Often located at seasonal boundaries

    -   Can trigger unique cross-seasonal dreams

2.  **Spirit Resting Places**: Locations where veridian spirits gather

    -   Higher chance for spirit communication dreams

    -   May provide hints about nearby resources or secrets

3.  **Seasonal Peaks**: The heart of each seasonal region

    -   Guaranteed dreams related to that season

    -   More powerful attunement growth when resting here

## **Flexible Rest Patterns**

To accommodate different play styles, the system should be flexible:

### **For Explorers**

-   Wilderness rest points are common enough to support extended
    expeditions

-   Special dream locations reward thorough exploration

-   Portable items can improve wilderness rest quality

### **For Home-Focused Players**

-   Home resting provides superior benefits

-   House upgrades enhance rest quality and dream clarity

-   Quick travel options to return home when tired

### **For Continuous Players**

-   Meditation allows for quick refreshment without interrupting
    gameplay

-   Companion abilities can temporarily substitute for rest benefits

-   Consumable items can provide rest-like benefits in a pinch

## **Dream Notification System**

### **Subtle Dream Indicators**

When a milestone dream is pending, provide subtle indicators to
encourage resting:

1.  **Visual Cues**: Small sparkling effects around the player when
    tired

2.  **Companion Dialogue**: *\"I sense you have much to process\...
    perhaps we should rest soon.\"*

3.  **Environmental Signs**: Stars shine more brightly, auroras appear

4.  **Journal Notes**: Dream journal glows softly in inventory

### **Rest Prompt Integration**

When significant events occur that trigger attunement growth:

func complete_significant_event(event_type, season):

\# Award attunement points

var points = calculate_attunement_gain(event_type)

player_data.attunement_levels\[season\] += points

\# Check if this pushed us over a milestone

if check_attunement_milestones():

\# Suggest rest with appropriate dialogue

var dialogue = get_rest_suggestion_dialogue(season)

trigger_companion_dialogue(dialogue)

\# Subtle visual effect on player

play_attunement_glow_effect(season)

\# Journal notification

notify_journal_update()

## **Wilderness Rest Implementation**

### **Rest Point Types**

var rest_point_types = {

\"campfire\": {

\"restoration\": 0.7, \# 70% attribute restoration

\"dream_bonus\": 0.1, \# +10% dream chance

\"weather_protection\": 0.3, \# 30% weather protection

\"placement\": \"clearings, paths\"

},

\"cave\": {

\"restoration\": 0.6,

\"dream_bonus\": 0.0,

\"weather_protection\": 0.8,

\"placement\": \"mountainous areas\"

},

\"ancient_stone\": {

\"restoration\": 0.5,

\"dream_bonus\": 0.3,

\"weather_protection\": 0.1,

\"placement\": \"special locations, boundaries\"

},

\"large_tree\": {

\"restoration\": 0.5,

\"dream_bonus\": 0.2,

\"weather_protection\": 0.4,

\"placement\": \"forests, spring region\"

}

}

\# When player interacts with a rest point

func interact_with_rest_point(rest_point):

var type = rest_point.type

var base_chance = dream_probability\[\"wilderness\"\]

var dream_chance_bonus = rest_point_types\[type\]\[\"dream_bonus\"\]

var total_dream_chance = min(base_chance + dream_chance_bonus, 1.0)

\# Store rest point data for when player chooses to rest

current_rest_data = {

\"type\": \"wilderness\",

\"specific_type\": type,

\"dream_chance\": total_dream_chance,

\"restoration\": rest_point_types\[type\]\[\"restoration\"\],

\"weather_protection\":
rest_point_types\[type\]\[\"weather_protection\"\]

}

\# Show rest UI with appropriate options

show_rest_interface(current_rest_data)

### **Enhanced Wilderness Rest**

As players progress, they can improve wilderness resting:

1.  **Craftable Items**:

    -   Bedrolls increase restoration

    -   Dream catchers increase dream chance

    -   Seasonal shelters improve weather protection

2.  **Companion Bonuses**:

    -   Frost provides better protection in winter regions

    -   Ember creates better warmth at campfires

    -   Wispy enhances dream chances at night

    -   Bloom improves rest quality in natural settings

3.  **Discovered Locations**:

    -   Finding and restoring ancient rest sites

    -   Creating permanent camps throughout the world

    -   Unlocking fast travel between discovered rest points

## **Home vs. Wilderness Dream Differences**

### **Home Dreams**

-   Full visual fidelity

-   Complete narrative sequence

-   Guaranteed milestone rewards

-   Dream journal automatically updates

### **Wilderness Dreams**

-   May be shorter or fragmented

-   Sometimes presented as partial visions

-   Might require returning home to \"complete\" the dream

-   Can contain unique wilderness-specific content
