class_name Action
extends Resource

@export_storage var name: String
@export var action_name: String
@export var utility: Evaluate

func evaluate(obj: Object, data: Dictionary):
    if utility == null:
        return 0
    if not utility:
        data[action_name] = +INF
    else:
        data[action_name] = utility.evaluate(obj)

func decode(v):
    action_name = v["action_name"]
