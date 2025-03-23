extends Control

@onready var label = $Label

func _ready():
	label.text = ""
	
func show_resource_name(resource_name):
	label.text = "Press E to gather " + resource_name
	
func clear_resource_name():
	label.text = ""
