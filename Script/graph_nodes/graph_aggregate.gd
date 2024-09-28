@tool
class_name GraphAggregate
extends AIGraphNode

enum Aggregation {
    PROD,
    SUM,
    AVG,
    MIN,
    MAX,
}


@export var options_button: OptionButton

var aggregation: String:
    get:
        if aggregation == "":
            aggregation = Aggregation.find_key(0)
            options_button.select(0)
        return aggregation
    set(v):
        aggregation = v
        options_button.select(Aggregation[v])
        parent.trigger_update.emit.call_deferred(self)

func _ready() -> void:
    options_button.clear()
    for k in Aggregation.keys():
        options_button.add_item(k, Aggregation[k])
    options_button.item_selected.connect(func(x): aggregation = Aggregation.find_key(x))
    options_button.focus_entered.connect(func(): selected = true)
    options_button.focus_exited.connect(func(): selected = false)

func save_keys():
    return super.save_keys() + ["aggregation"]
