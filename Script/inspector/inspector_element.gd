@tool
class_name AINodeEditor
extends Resource

var target: AIGraphNode
var keys: Array[String]

func _init(node: AIGraphNode):
    target = node
    keys.assign(node.save_keys())

func _set(property: StringName, value: Variant) -> bool:
    if not is_instance_valid(target):
        return true
    if keys.has(property):
        target.set(property, value)
        target.parent.trigger_update.emit.call_deferred(target)
        return true
    return false

func _get(property: StringName) -> Variant:
    if not is_instance_valid(target):
        return
    if keys.has(property):
        return target.get(property)
    return null

func _get_property_list() -> Array[Dictionary]:
    var props: Array[Dictionary] = []
    for k in keys:
        var t = typeof(target.get(k))
        var p = {
            name = k,
            type = t
        }
        props.append(p)
    return props
