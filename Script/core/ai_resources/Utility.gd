class_name Utility
extends Evaluate

var name: String
@export var expression: String
@export var curve: Curve

func evaluate(obj) -> float:
    var data: Dictionary
    if obj.has_method("_gather_data"):
        data = obj.gather_data()
    else:
        data = inst_to_dict(obj)

    var keys = data.keys()
    keys.sort()

    var expr = Expression.new()
    expr.parse(expression, keys)

    var result = expr.execute(keys.map(func(x): return data[x]), obj)

    return curve.sample(type_convert(result, TYPE_FLOAT))

func decode(v):
    expression = v["evaluation"]
    curve = Marshalls.base64_to_variant(v["curve"]["value"], true)
