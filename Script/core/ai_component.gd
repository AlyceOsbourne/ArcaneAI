@tool
class_name AIComponent

extends Node

@export var ai: AI:
    set(v):
        ai = v
        type = ""
        notify_property_list_changed()

var type: String = "":
    set(v):
        type = v
        if type != "":
            var c = ProjectSettings.get_global_class_list().filter(func(x): return x["class"] == v)
            if not c.is_empty():
                var d = load(c[0]["path"])
                if d.has_method("new"):
                    data = d.new()
        else:
            data = null
        notify_property_list_changed()

var data:
    set(v):
        data = v
        notify_property_list_changed()

signal evaluation(data: String)

func evaluate():
    evaluation.emit(ai.evaluate(data))

func _get_property_list() -> Array[Dictionary]:
    if not ai:
        return []
    var p: Array[Dictionary] = [
        {
            "name": "type",
            "type": TYPE_STRING,
            "hint": PROPERTY_HINT_ENUM_SUGGESTION,
            "hint_string": ",".join(ProjectSettings.get_global_class_list().filter(func(x): return x["base"] == &"Resource").map(func(x): return x["class"]))
        }
    ]
    if type != "":
        p.append(
        {
            "name": "data",
            "type": TYPE_OBJECT,
            "hint": PROPERTY_HINT_RESOURCE_TYPE,
            "hint_string": type
        })
    return p

func _ready() -> void:
    if Engine.is_editor_hint():
        return
    evaluation.connect(func(x): print("%s: %s" % [name, x]))

func _process(delta: float) -> void:
    if Engine.is_editor_hint():
        return
    evaluate()
