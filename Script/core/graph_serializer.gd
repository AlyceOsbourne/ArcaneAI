@tool
class_name GraphSerializer

static func _is_simple_type(value):
    return typeof(value) in [TYPE_INT, TYPE_FLOAT, TYPE_STRING, TYPE_STRING_NAME, TYPE_BOOL]

static func _deserialize_node(node_data, node_type):
    var node = node_type.instantiate()
    for a in node_data:
        var serialized_value = node_data[a]
        node.set_deferred(a, _deserialize_value(serialized_value))
    return node

static func _serialize_node(node):
    var _data = {}
    for k in node.save_keys():
        var value = node[k]
        _data[k] = _serialize_value(value)
    return _data

static func _serialize_value(value):
    if _is_simple_type(value):
        return value
    else:
        return {
            "__type": "complex",
            "value": Marshalls.variant_to_base64(value, true)
        }

static func _deserialize_value(serialized_value):
    if typeof(serialized_value) == TYPE_DICTIONARY and serialized_value.has("__type"):
        return Marshalls.base64_to_variant(serialized_value["value"], true)
    else:
        return serialized_value

static func _save(graph):
    var data = {}
    data["connections"] = graph.get_connection_list()
    for node in graph.graph_nodes:
        var reg = data.get_or_add(node.title, [])
        reg.append(GraphSerializer._serialize_node(node))
    return data

static func _load(graph, ai: AI):
    var data = ai.data
    if not data.has("connections") or data.is_empty():
        for child in graph.get_children().filter(func(x): return x is AIGraphNode and x.allow_close):
            child.free()
        return

    for child in graph.get_children().filter(func(x): return x is AIGraphNode):
        child.free()

    for k in data.keys().filter(func(x): return not x == "connections"):
        for v in data[k]:
            var node_type = GraphUtils[k if k != "AI" else "_AI"]
            var node = GraphSerializer._deserialize_node(v, node_type)
            graph.add_child(node)

    for _conn in data["connections"]:
        graph.connect_node.call_deferred(_conn["from_node"], _conn["from_port"], _conn["to_node"], _conn["to_port"])

    graph.trigger_update.emit.call_deferred(graph)
