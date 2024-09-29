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

func _update(by):
    if by == self:
        return
    var new = AI.build(GraphSerializer._save(self))
    GraphUtils.picker.edited_resource = new

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
        ["Add Action", GraphUtils.Action, _place_below_all],
        ["Add Aggregate", GraphUtils.Aggregate, _place_adjacent],
        ["Add Utility", GraphUtils.Utility, _place_adjacent]
    ]:
        var butt = _create_node_button(button_options[0], button_options[1], button_options[2])
        menu.add_child(butt)

    var clear = _create_action_button("Clear", _clear_graph)
    menu.add_child(clear)
    menu.add_child(_create_action_button("Rearrange", _auto_arrange))
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
        set_selected(get_node(NodePath("AI")))
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

#func _place_adjacent(node):
    #var _selected = selected_node
    #if _selected:
        #node.position_offset = _selected.position_offset + Vector2(300, 0)

func _place_adjacent(node):
    var _selected = selected_node
    if not _selected:
        return
    var proposed_position = _selected.position_offset + Vector2(300, 0)
    var spacing = node.size.y + 100
    node.position_offset = _get_available_position(proposed_position, spacing, node)

func _get_available_position(position, spacing, node):
    var offset_y = 0
    while true:
        var test_position = position + Vector2(0, offset_y)
        if not _is_position_occupied(test_position, node):
            return test_position
        offset_y += spacing

func _is_position_occupied(position, node):
    var node_size = node.get_size() if node.is_inside_tree() else Vector2(150, 100)  # Approximate size
    var rect1 = Rect2(position, node_size)
    for child in get_children():
        if child == node or not (child is AIGraphNode):
            continue
        var child_pos = child.position_offset
        var child_size = child.get_size() if child.is_inside_tree() else Vector2(150, 100)
        var rect2 = Rect2(child_pos, child_size)
        if rect1.intersects(rect2):
            return true
    return false

func _place_below_all(node):
    var lowest = Vector2.ZERO
    var actions = get_children().filter(func(x): return x is GraphAction)

    if actions.is_empty() or actions.size() == 1:
        set_selected(get_node(NodePath("AI")))
        _place_adjacent(node)
        return

    for action: GraphAction in actions:
        var pos = action.position_offset
        if pos.y > lowest.y:
            lowest = pos

    node.position_offset = lowest + Vector2(0, 200)

func _topological_sort() -> Array:
    var node_order = []
    var node_stack = []
    var in_degree = {}

    for node in graph_nodes:
        in_degree[node] = 0

    for connection in get_connection_list():
        var target_node = get_node(NodePath(connection.to_node))
        if target_node in in_degree:
            in_degree[target_node] += 1

    for node in in_degree:
        if in_degree[node] == 0:
            node_stack.append(node)

    while not node_stack.is_empty():
        var current_node = node_stack.pop_back()
        node_order.append(current_node)

        for connection in get_connection_list():
            if connection.from_node == current_node.name:
                var target_node = get_node(NodePath(connection.to_node))
                if target_node in in_degree:
                    in_degree[target_node] -= 1
                    if in_degree[target_node] == 0:
                        node_stack.append(target_node)

    return node_order

func _calculate_depth(node: AIGraphNode, depth_map: Dictionary) -> int:
    if node in depth_map:
        return depth_map[node]

    var depth = 0
    for connection in get_connection_list():
        if connection.to_node == node.name:
            var parent_node = get_node(NodePath(connection.from_node))
            depth = max(depth, _calculate_depth(parent_node, depth_map) + 1)

    depth_map[node] = depth
    return depth


func _auto_arrange():
    var sorted_nodes = _topological_sort()
    if sorted_nodes.is_empty():
        return

    var depth_map = {}
    var max_depth = 0

    for node in sorted_nodes:
        var depth = _calculate_depth(node, depth_map)
        if depth > max_depth:
            max_depth = depth

    var horizontal_spacing = 300
    var vertical_spacing = 100

    var total_height = 0
    var placed_nodes = {}
    var node_children = {}

    for connection in get_connection_list():
        var from_node = get_node(NodePath(connection.from_node))
        var to_node = get_node(NodePath(connection.to_node))
        if from_node in node_children:
            node_children[from_node].append(to_node)
        else:
            node_children[from_node] = [to_node]


    for node in sorted_nodes:
        if node in placed_nodes:
            continue

        var has_parent = false
        for connection in get_connection_list():
            if connection.to_node == node.name:
                has_parent = true
                break

        if not has_parent:
            var current_x = horizontal_spacing * depth_map[node]
            var current_y = total_height

            node.position_offset = Vector2(current_x, current_y)
            placed_nodes[node] = true

            var subtree_height = _arrange_subtree(node, depth_map, node_children, placed_nodes, horizontal_spacing, vertical_spacing)

            total_height += subtree_height + vertical_spacing



    sorted_nodes[0].position_offset = Vector2(-horizontal_spacing * 2, total_height / 2)

    trigger_update.emit(self)

func _arrange_subtree(node, depth_map, node_children, placed_nodes, horizontal_spacing, vertical_spacing):
    var node_height = node.size.y
    var depth = depth_map[node]
    var current_x = horizontal_spacing * depth
    var current_y = node.position_offset.y
    var max_height = node_height

    if node in node_children:
        var child_y = current_y
        var is_first_child = true

        var nc = node_children[node]

        nc.sort_custom(
            func(x, y):
                var deg_x = calc_deg(x, node_children)
                var deg_y = calc_deg(y, node_children)
                return deg_x < deg_y

        )

        for child in node_children[node]:
            if child in placed_nodes:
                continue

            var child_depth = depth_map[child]
            var child_x = horizontal_spacing * child_depth

            if is_first_child:
                child_y = current_y
                is_first_child = false
            else:
                child_y += node_height + vertical_spacing

            child.position_offset = Vector2(child_x, child_y)
            placed_nodes[child] = true

            var subtree_height = _arrange_subtree(child, depth_map, node_children, placed_nodes, horizontal_spacing, vertical_spacing)

            child_y += subtree_height - node_height

            var child_total_height = (child_y - current_y) + node_height
            if child_total_height > max_height:
                max_height = child_total_height

    return max_height

func calc_deg(n, nc):
    if not nc.has(n):
        return 0
    return 1 + nc[n].map(calc_deg.bind(nc)).reduce(func(x, y): return x + y)
