@tool
class_name AIGraphNode
extends GraphNode

var allow_close = true

var parent: AIGraph:
    get:
        return (get_parent() as AIGraph)

var slot:
    get: return get_child(0)

func _enter_tree():
    var root = get_tree().root
    var update_theme = func(__=null):
        for i in 10:
            if is_slot_enabled_left(i):
                set_slot_color_left(i, root.get_theme_color("accent_color", "Editor"))
            if is_slot_enabled_right(i):
                set_slot_color_right(i, root.get_theme_color("accent_color", "Editor"))

    get_tree().root.theme_changed.connect(update_theme)
    update_theme.call()

    if allow_close:
        var close = Button.new()
        close.flat = true
        close.text = "x"
        close.button_up.connect(queue_free)
        get_titlebar_hbox().add_child(close)
    else:
        var dummy = Control.new()
        dummy.custom_minimum_size.y = 30
        get_titlebar_hbox().add_child(dummy)

    custom_minimum_size.x = 200
    custom_minimum_size.y = 100

    node_selected.connect(
        func():
            if Engine.is_editor_hint():
                EditorInterface.inspect_object(AINodeEditor.new(self))
    )

    if parent != null:
        parent.trigger_update.emit.call_deferred(self)

func _exit_tree():
    if parent != null:
        (parent as AIGraph).trigger_update.emit.call_deferred(self)

func _update(triggered_by):
    if triggered_by == self or triggered_by == null:
        return

func save_keys():
    return [
        "position_offset",
        "name"
    ]

func _save_data():
    var data = {}
    for k in save_keys():
        data[k] = self[k]
    return data

func _load_data(data):
    for k in data.keys():
        set(k, data[k])
