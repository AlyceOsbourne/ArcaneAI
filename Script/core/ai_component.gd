class_name AIComponent

extends Node

@export var ai: AI
@export var data: Resource

signal evaluation(data: Dictionary)

func evaluate():
    if ai and data:
        evaluation.emit(ai.evaluate(data))
