@tool
class_name GraphAction
extends AIGraphNode

@export var line_edit: LineEdit

var action_name: String:
    get: return line_edit.text
    set(v):
        if v == line_edit.text:
            return
        line_edit.text = v
        parent.trigger_update.emit.call_deferred(self)

func _ready():
    line_edit.text_submitted.connect(
        func(x):
            parent.trigger_update.emit.call_deferred(self)
    )
    line_edit.focus_entered.connect(func(): parent.set_selected(self))
    line_edit.focus_exited.connect(
        func():
            parent.trigger_update.emit.call_deferred(self)
    )

func save_keys():
    return super.save_keys() + ["action_name"]
