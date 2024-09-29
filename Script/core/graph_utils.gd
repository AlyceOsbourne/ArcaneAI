@tool
class_name GraphUtils

const _AI = preload("res://addons/ArcaneAI/Scene/AI.tscn")
const Action = preload("res://addons/ArcaneAI/Scene/Action.tscn")
const Aggregate = preload("res://addons/ArcaneAI/Scene/Aggregate.tscn")
const Utility = preload("res://addons/ArcaneAI/Scene/Utility.tscn")

static var inspector := InspectAISystem.new()
static var picker := EditorResourcePicker.new()

static func setup_picker(graph: AIGraph):
    var menu = graph.get_menu_hbox()
    picker.base_type = "AI"
    var b: Button = picker.get_children(true)[0]
    b.text = "None"
    b.size_flags_horizontal = graph.SIZE_EXPAND_FILL
    b.clip_text = false
    var f = func(x: AI, flag=false):
            if not x:
                graph._clear_graph()
            else:
                x = x.duplicate(true)
                GraphSerializer._load(graph, x)
                inspector.set_deferred("ai", x)
                _inspect.call_deferred(graph)
                b.text = x.resource_path if x.resource_path else "Unsaved"
                b.size_flags_horizontal = graph.SIZE_EXPAND_FILL
                b.clip_text = false

    picker.resource_changed.connect(f, CONNECT_DEFERRED)
    picker.resource_selected.connect(f, CONNECT_DEFERRED)
    if picker.get_parent() != null:
        picker.reparent.call_deferred(menu)
    else:
        menu.add_child.call_deferred(picker)
    menu.size_flags_horizontal = graph.SIZE_EXPAND_FILL

static func _update_activations(graph: AIGraph):
    var nodes = graph.graph_nodes
    var connections = graph.get_connection_list()
    for c in connections:
        graph.set_connection_activity.call_deferred(c["from_node"], c["from_port"], c["to_node"], c["to_port"], 0)

    var ev = inspector.evaluation
    var to_activate = ev.keys().reduce(func(x, y): return x if ev[x] > ev[y] else y)

    for action in nodes.filter(func(x): return x.title == "Action"):
        var _action_name = action.action_name
        var _activate_flag = to_activate == _action_name
        graph.set_connection_activity.call_deferred("AI", 0, str(graph.get_path_to(action)), 0, _activate_flag)
        if _activate_flag:
            _activate(graph, action, connections)

static func _activate(graph, node, conns):
    var n_path = str(graph.get_path_to(node))
    for c in conns:
        if c["from_node"] == n_path:
            graph.set_connection_activity.call_deferred(c["from_node"], c["from_port"], c["to_node"], c["to_port"], 1)
            _activate.call_deferred(graph, graph.get_node(str(c["to_node"])), conns)

static func _inspect(graph):
    if not Engine.is_editor_hint():
        return
    for child in graph.get_children():
        if "selected" in child:
            child.selected = false
    if not inspector.changed.is_connected(_update_activations.bind(graph)):
        inspector.changed.connect(_update_activations.bind(graph))
    EditorInterface.inspect_object(inspector)
    _update_activations.call_deferred(graph)
