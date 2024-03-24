extends Node2D

@export_enum("res://scenes/testing_scenes/weapon_testing.tscn") var scene_to_set: String

# Called when the node enters the scene tree for the first time.
func _ready():
	get_tree().change_scene_to_file(scene_to_set)
