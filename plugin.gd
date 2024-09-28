@tool
extends EditorPlugin

var instance: AIGraph:
    get:
        if instance == null:
            instance = load("res://addons/ArcaneAI/Scene/Graph.tscn").instantiate()
            GraphUtils.setup_picker(instance)
            EditorInterface.get_editor_main_screen().add_child(instance)

            _make_visible(false)
        return instance

func _exit_tree():
    instance.queue_free()

func _has_main_screen():
    return true

func _make_visible(visible):
    if instance:
        instance.visible = visible

func _get_plugin_name():
    return "AIGraph"

func _get_plugin_icon():
    return EditorInterface.get_editor_theme().get_icon("Node", "EditorIcons")

func _handles(object: Object) -> bool:
    if object is AI:
        GraphUtils.picker.resource_changed.emit(object)
        return true
    return false
