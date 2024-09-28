@tool
class_name AI
extends Resource

static var classes = {
    "Aggregate": Aggregate,
    "Action": Action,
    "Utility": Utility
}

@export_storage var name: String
@export var actions: Array[Action]
@export_storage var data: Dictionary

func evaluate(obj: Object) -> Dictionary:
    var data = {}
    actions.map(func(x: Action): x.evaluate(obj, data))
    return data

static func load_ai(path: String) -> AI:
    return build(JSON.parse_string(FileAccess.get_file_as_string(path)))

static func build(data: Dictionary) -> AI:
    var decoded = {}

    if "AI" not in data:
        return

    var conns = data["connections"]

    for k in data.keys().filter(func(x): return x != "connections"):
        for v in data[k]:
            var inst
            if k == "AI":
                inst = AI.new()
            else:
                inst = classes[k].new()
            inst.name = v["name"]
            if inst.has_method("decode"):
                inst.decode(v)
            decoded[inst.name] = inst

    for c in conns:
        attach(decoded[c["from_node"]], decoded[c["to_node"]])

    decoded["AI"].data = data

    return decoded["AI"]

static func attach(a, b):
    match [a, b]:
        [var _a, var _b] when _a is AI and _b is Action: a.actions.append(b)
        [var _a, var _b] when _a is Action and _b is Evaluate: a.utility = b
        [var _a, var _b] when _a is Aggregate and _b is Evaluate:  a.utilities.append(b)
