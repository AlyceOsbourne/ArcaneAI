class_name AIComponent

extends Node

@export var ai: AI
@export var data: Resource

signal evaluation(data: Dictionary)

func evaluate():
    evaluation.emit(ai.evaluate(data))

func _ready() -> void:
    evaluation.connect(func(x): print("%s: %s" % [name, x]))
