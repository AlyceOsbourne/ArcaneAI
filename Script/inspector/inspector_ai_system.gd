@tool
class_name InspectAISystem
extends Resource

@export_group("Test")
var chosen_action: String:
    get:
        if not evaluation:
            return ""
        var e = evaluation
        var r = e.keys()
        r.sort_custom(func(x, y): return e[x] > e[y])
        if chosen_action != r[0]:
            chosen_action = r[0]
            changed.emit.call_deferred()
        return r[0]

var test_object:
    set(v):
        test_object = v
        if test_object:
            if not test_object.changed.is_connected(changed.emit):
                test_object.changed.connect(changed.emit)
        changed.emit()
        notify_property_list_changed()

@export_group("Data")
var type: String:
    set(v):
        type = v
        test_object = null
        notify_property_list_changed()

var ai: AI:
    set(v):
        ai = v
        type = ""
        if ai:
            if not ai.changed.is_connected(changed.emit):
                ai.changed.connect(changed.emit)
        changed.emit()

var evaluation: Dictionary:
    set(v):
        if evaluation != v:
            return
        evaluation = v
        changed.emit()
        notify_property_list_changed()
    get:
        if not test_object or not ai:
            return {}
        return ai.evaluate(test_object)

static func build(data):
    var i = InspectAISystem.new()
    i.ai  = AI.build(data)
    return i

func _get_property_list() -> Array[Dictionary]:
    var p: Array[Dictionary] = [
        {
            "name": "type",
            "type": TYPE_STRING,
            "hint": PROPERTY_HINT_ENUM_SUGGESTION,
            "hint_string": ",".join(ProjectSettings.get_global_class_list().filter(func(x): return x["base"] == &"Resource").map(func(x): return x["class"]))
        }
    ]
    if type != "":
        p.append_array([
        {
            "name": "Test",
            "type": TYPE_NIL,
            "usage": PROPERTY_USAGE_GROUP
        },
        {
            "name": "test_object",
            "type": TYPE_OBJECT,
            "hint": PROPERTY_HINT_RESOURCE_TYPE,
            "hint_string": type
        }
    ])
    if test_object:

        p.append({
            "name": "Test_Evaluation",
            "type": TYPE_NIL,
            "usage": PROPERTY_USAGE_SUBGROUP
        },)
        p.append({
            "name": "chosen_action",
            "type": TYPE_STRING,
        })
        for k in evaluation:
            p.append({
                "name": k,
                "type": TYPE_FLOAT
            })
    return p

func _get(property: StringName) -> Variant:
    if evaluation.has(property):
        return evaluation[property]
    return null
