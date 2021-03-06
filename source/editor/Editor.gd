extends Node2D

const Scenario = preload("res://source/core/scenario/Scenario.tscn")
const DEFAULT_PATH = "res://data/scenarios/"
const DEFAULT_MAP_SIZE := Vector2(44, 33)

export var button_size := 60

onready var HUD := $HUD as CanvasLayer
onready var scenario_container := $ScenarioContainer as Node2D
onready var scenario := $ScenarioContainer/Scenario as Scenario
onready var line_edit := $HUD/UIButtons/HBoxContainer/LineEdit as LineEdit

var current_tile := 0

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_pressed("mouse_left"):
		var mouse_position: Vector2 = get_global_mouse_position()
		scenario.map.set_tile(mouse_position, current_tile)

	if Input.is_action_just_released("mouse_left"):
		_update()

	if Input.is_action_pressed("mouse_right"):
		var mouse_position: Vector2 = get_global_mouse_position()
		scenario.map.set_tile(mouse_position, -1)

func _ready() -> void:
	_new_map()
	_setup_scenario()

func _update():
	scenario.map.update_terrain()

func _setup_scenario() -> void:
	for id in scenario.map.tile_set.get_tiles_ids():
		_add_terrain_button(id)

func _add_terrain_button(id: int) -> void:
	var button := TextureButton.new()
	#warning-ignore:return_value_discarded
	button.connect("pressed", self, "_on_button_pressed", [id])
	var texture := AtlasTexture.new()
	texture.atlas = scenario.map.tile_set.tile_get_texture(id)
	texture.region = _normalize_region(scenario.map.tile_set.tile_get_region(id))
	button.texture_normal = texture
	button.rect_size = Vector2(54, 72)
	HUD.add_button(button)

func _normalize_region(region : Rect2) -> Rect2:
	var rect_position = (region.position + (region.size / 2.0)) -\
			Vector2(button_size / 2.0, button_size / 2.0)
	var rect = Rect2(rect_position, Vector2(button_size, button_size))

	return rect

func _new_map() -> void:
	scenario.queue_free()
	scenario = Scenario.instance()
	scenario_container.add_child(scenario)
	scenario.map.set_size(DEFAULT_MAP_SIZE)
	scenario.map.fog.hide()

func _load_map(scenario_name: String) -> void:
	var packed_scene = load(DEFAULT_PATH + scenario_name + ".tscn")

	if packed_scene == null:
		return

	scenario.queue_free()
	scenario = packed_scene.instance()
	scenario_container.add_child(scenario)

func _save_map(scenario_name: String) -> void:
	var id = scenario_name.replace(" ", "_").to_lower()
	var scn_path: String = DEFAULT_PATH + id + ".tscn"
	var res_path: String = DEFAULT_PATH + id + ".tres"

	var packed_scene := PackedScene.new()
	#warning-ignore:return_value_discarded
	packed_scene.pack(scenario)

	var r_scenario = RScenario.new();
	r_scenario.title = scenario_name

	if ResourceSaver.save(scn_path, packed_scene) != OK:
		print("Failed to save map scene ", scn_path)
	elif ResourceSaver.save(res_path, r_scenario) != OK:
		print("Failed to save map resource", res_path)
	else:
		Registry.scenarios[id] = {}
		Registry.scenarios[id].data = r_scenario
		Registry.scenarios[id].base_path = scn_path.get_basename()

func _on_button_pressed(id: int) -> void:
	print(id)
	current_tile = id

func _on_Back_pressed() -> void:
	Scene.change(Scene.TitleScreen)

func _on_Save_pressed() -> void:
	_save_map(line_edit.text)

func _on_Load_pressed() -> void:
	_load_map(line_edit.text)

func _on_New_pressed() -> void:
	_new_map()
