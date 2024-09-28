class_name Aggregate
extends Evaluate
var name: String

enum Aggregation {
    PROD,
    SUM,
    AVG,
    MIN,
    MAX,
}

@export var utilities: Array[Evaluate]
@export var aggregate: Aggregation

func evaluate(obj) -> float:
    if len(utilities) == 0:
        return 0
    var utils = utilities.map(func(x: Evaluate): return x.evaluate(obj))
    match aggregate:
        Aggregation.PROD: return utils.reduce(func(x, y): return x * y, 1)
        Aggregation.SUM: return utils.reduce(func(x, y): return x + y, 0)
        Aggregation.AVG: return utils.reduce(func(x, y): return x + y, 0) / len(utils)
        Aggregation.MAX: return utils.reduce(func(x, y): return x if x >= y else y)
        Aggregation.MIN: return utils.reduce(func(x, y): return x if x <= y else y)
        _:
            assert(false, "Invalid Aggregation")
            return 0

func decode(data):
    aggregate = Aggregation[data["aggregation"]]
