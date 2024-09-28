@tool
class_name AIGraph_AI
extends AIGraphNode

@export var button: Button

func _ready():
    button.text = "Test"
    button.pressed.connect(
        func():
            var v = AI.build(GraphSerializer._save(parent))
            GraphUtils.picker.edited_resource = v
            GraphUtils.picker.resource_changed.emit(v)
    )

func _enter_tree() -> void:
    allow_close = false
    super._enter_tree()
