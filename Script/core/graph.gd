@tool
class_name AIGraph
extends GraphEdit

@onready var ai: AIGraphNode:
    get: return get_node_or_null("AI")

signal trigger_update(source)

var graph_nodes:
    get: return get_children().filter(func(x): return x is AIGraphNode)

var selected_node: AIGraphNode:
    get:
        var v = get_children().filter(func(x): return x is AIGraphNode and x.selected)
        if v.size() == 1:
            return v[0]
        return null

func _ready() -> void:
    connection_request.connect(_handle_connect_node)
    disconnection_request.connect(_handle_disconnect_node)
    set_selected.call_deferred(get_node("AI"))

    for i in 2:
        add_valid_connection_type(i, i)
        add_valid_left_disconnect_type(i)
        add_valid_right_disconnect_type(i)

    var menu = get_menu_hbox()

    for button_options in [
        ["Add Action", GraphUtils.Action, _place_below_actions],
        ["Add Aggregate", GraphUtils.Aggregate, _place_adjacent],
        ["Add Utility", GraphUtils.Utility, _place_adjacent]
    ]:
        var butt = _create_node_button(button_options[0], button_options[1], button_options[2])
        menu.add_child(butt)

    var clear = _create_action_button("Clear", _clear_graph)
    menu.add_child(clear)
    menu.add_spacer(false)

    trigger_update.connect(
        func(x):
            var p = get_parent()
            if p == null:
                return
            p.propagate_call("_update", [x]),
        CONNECT_DEFERRED
    )




func _create_node_button(text, node_type, place_func):
    var butt = Button.new()
    butt.text = text
    butt.pressed.connect(
        func():
            _add_node(node_type, place_func)
    )
    return butt

func _create_action_button(text, action_func):
    var butt = Button.new()
    butt.text = text
    butt.pressed.connect(action_func)
    return butt

func _add_node(node_type, place_func):
    var c = node_type.instantiate()
    add_child.call_deferred(c, true)
    place_func.call_deferred(c)
    set_selected.call_deferred(c)

    var s = selected_node
    if not s:
        set_selected(get_node("AI"))
        s = selected_node

    var s_title = s.title
    var c_title = c.title

    if [s_title, c_title] in [
        ["Action", "Aggregate"], ["Action", "Utility"],
        ["Aggregate", "Utility"], ["Aggregate", "Aggregate"]
    ]:
        (func():_handle_connect_node(str(get_path_to(s)), 0, str(get_path_to(c)), 0)).call_deferred()
    elif c_title == "Action":
        (func(): _handle_connect_node("AI", 0, str(get_path_to(c)), 0)).call_deferred()

func _clear_graph():
    get_children().filter(func(x): return x is AIGraphNode and x.allow_close).map(func(x): x.queue_free())
    GraphUtils.picker.edited_resource = AI.new()
    GraphUtils.picker.resource_changed.emit(GraphUtils.picker.edited_resource)

func _handle_connect_node(f, fp, t, tp):

    var from = get_node(NodePath(f))
    var to = get_node(NodePath(t))

    if from.title == "Action" and _has_outgoing_connection(f):
        return

    if to.title == "Utility" and _has_incoming_connection(t):
        return

    connect_node(f, fp, t, tp)
    trigger_update.emit.call_deferred(self)

func _has_outgoing_connection(node_path):
    for conn in get_connection_list():
        if conn["from_node"] == node_path:
            return true
    return false

func _has_incoming_connection(node_path):
    for conn in get_connection_list():
        if conn["to_node"] == node_path:
            return true
    return false

func _handle_disconnect_node(f, fp, t, tp):
    if not Input.is_key_pressed(KEY_SHIFT):
        disconnect_node(f, fp, t, tp)
    trigger_update.emit.call_deferred(self)

func _place_adjacent(node):
    var _selected = selected_node
    if _selected:
        node.position_offset = _selected.position_offset + Vector2(300, 0)

func _place_below_actions(node):
    var lowest = Vector2.ZERO
    var actions = get_children().filter(func(x): return x is AIGraphAction)

    if actions.is_empty() or actions.size() == 1:
        set_selected(get_node("AI"))
        _place_adjacent(node)
        return

    for action: AIGraphAction in actions:
        var pos = action.position_offset
        if pos.y > lowest.y:
            lowest = pos

    node.position_offset = lowest + Vector2(0, 200)

func _update(by):
    if by == self:
        return
    var new = AI.build(GraphSerializer._save(self))
    GraphUtils.picker.edited_resource = new
