@tool
class_name GraphUtility
extends AIGraphNode

@export var code_edit: CodeEdit:
    set(v):
        if Engine.is_editor_hint() and ClassDB.class_exists("GDScriptSyntaxHighlighter"):
            var h = ClassDB.instantiate("GDScriptSyntaxHighlighter")
            v.syntax_highlighter = h
        code_edit = v

@export var curve: Curve:
    get:
        if curve == null:
            curve = Curve.new()
            curve.resource_local_to_scene = true
            curve.add_point(Vector2.ZERO)
            curve.add_point(Vector2(1, 1))
        return curve

var evaluation: String:
    get:
        return code_edit.text
    set(v):
        code_edit.text = v
        parent.trigger_update.emit.call_deferred(self)

func _ready() -> void:
    code_edit.text_changed.connect(func(): parent.trigger_update.emit.call_deferred(self), CONNECT_DEFERRED)
    code_edit.focus_entered.connect(func(): parent.set_selected(self), CONNECT_DEFERRED)

func save_keys():
    return super.save_keys() + ["evaluation", "curve"]

func _save_data():
    var data = {
        "evaluation": evaluation,
        "curve": Marshalls.variant_to_base64(curve)
    }

    for key in super.save_keys():
        data[key] = get(key)
    return data
