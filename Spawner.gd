extends Spatial

var connection : HTTPClient;
var data = PoolByteArray();
export var ui_option_path : NodePath;
onready var ui_option = get_node(ui_option_path) as OptionButton;
export var ui_subset_path : NodePath;
onready var ui_subset = get_node(ui_subset_path) as OptionButton;
export var ui_label_path : NodePath;
onready var ui_label = get_node(ui_label_path) as Label;
export var ui_updated_path : NodePath;
onready var ui_updated = get_node(ui_updated_path) as Label;
export var cubes_to_spawn : PackedScene;

export var explode_particles_path : NodePath;
onready var explode_particles = get_node(explode_particles_path) as Particles;

export var attract_point_path : NodePath;
onready var attract_point_n = get_node(attract_point_path) as Spatial;

var parsed_data;

func _ready() -> void:

	connection = HTTPClient.new();
	var err = connection.connect_to_host("covid-193.p.rapidapi.com", 443, true);
	assert(err == OK);

	while connection.get_status() == HTTPClient.STATUS_CONNECTING or connection.get_status() == HTTPClient.STATUS_RESOLVING:
		connection.poll()
		print("Connection polling")
		yield(Engine.get_main_loop(), "idle_frame")

	# var f : File = File.new();
	# f.open("res://rapidapi.txt", File.READ);
	var apikey = ApiKey.return_api_key();
	# f.close();

	var headers = ["x-rapidapi-host: covid-193.p.rapidapi.com", "x-rapidapi-key: " + apikey];
	connection.request(HTTPClient.METHOD_GET, "/statistics", headers);

	while connection.get_status() == HTTPClient.STATUS_REQUESTING:
		connection.poll();
		print("Request polling");
		yield(Engine.get_main_loop(), "idle_frame");

	if connection.has_response():
		while connection.get_status() == HTTPClient.STATUS_BODY:
			connection.poll();
			print("Data polling");
			var chunk = connection.read_response_body_chunk();
			if chunk.size() == 0:
				yield(Engine.get_main_loop(), "idle_frame");
			else:
				data = data + chunk;
	else:
		print("No response");

	var jsonResult : JSONParseResult = JSON.parse(data.get_string_from_ascii());
	parsed_data = jsonResult.result.response;
	parsed_data.sort_custom(Sorter, "sort_ascending");
	for obj in parsed_data:
		if (obj.has("country")):
			if obj.has("continent") && obj["continent"] != null:
				ui_option.add_item(obj["country"] + ", " + obj["continent"]);
			else:
				ui_option.add_item(obj["country"]);

	ui_option.selected = -1;
	ui_option.text = "Done. Pick a country"
	pass

const subsets = ["cases", "deaths", "tests", "recovered", "critical", "active"];
var materials = [load("res://rep_total.tres"), load("res://rep_dead.tres"), load("res://rep_tests.tres"), load("res://rep_recovered.tres"),
					load("res://rep_critical.tres"), load("res://rep_active.tres")];

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("push_away"):
		explode_particles.restart();
		explode_particles.emitting = true;
	pass

func _on_UIOption_item_selected(index: int) -> void:
	index = ui_option.selected;
	for child in get_children():
		(child as Spatial).queue_free();
	var new_data : Dictionary = parsed_data[index];
	var total_cases;

	if ui_subset.selected == 3:
		total_cases = new_data[subsets[0]].recovered;
	elif ui_subset.selected == 4:
		total_cases = new_data[subsets[0]].critical;
	elif ui_subset.selected == 5:
		total_cases = new_data[subsets[0]].active;
	else:
		total_cases = new_data[subsets[ui_subset.selected]].total;

	ui_updated.text = "Last updated: " + new_data["time"];

	if total_cases == null:
		total_cases = 0;
		ui_label.text = "No data is supplied for that combo";
		return;

	# total_cases = total_cases.replace(",", "");
	var total_cases_int : int = (total_cases);
	var total_cases_int_b : int = (total_cases);
	var scale_factor : int = 1;

	if total_cases_int > 100_000_000:
		total_cases_int /= 400_000;
		scale_factor = 2.2;
		ui_label.text = "One cube = 400K";
	elif total_cases_int > 10_000_000:
		total_cases_int /= 75_000;
		scale_factor = 2.0;
		ui_label.text = "One cube = 75K";
	elif total_cases_int > 2_500_000:
		total_cases_int /= 50_000;
		scale_factor = 1.8;
		ui_label.text = "One cube = 50K";
	elif total_cases_int > 500_000:
		total_cases_int /= 7_000;
		scale_factor = 1.6;
		ui_label.text = "One cube = 7K";
	elif total_cases_int > 5_000:
		total_cases_int /= 1_000;
		scale_factor = 1.4;
		ui_label.text = "One cube = 1K";
	elif total_cases_int > 2_000:
		total_cases_int /= 100;
		scale_factor = 1.2;
		ui_label.text = "One cube = 100";
	else:
		total_cases_int /= 1;
		ui_label.text = "One cube = 1";
	ui_label.text += "\nTotal cases = " + comma_sep(total_cases_int_b) + " instances, approx. into " + comma_sep(total_cases_int) + " cubes";

	var child : Spatial;
	var location : Vector3;
	for _number in range(total_cases_int):
		child = cubes_to_spawn.instance();
		child.attract_point = attract_point_n;
		(child.get_child(0) as CSGBox).material = materials[ui_subset.selected];
		location = Vector3((_number % 16) - 8, (((_number / 16) / 16) % 16 + 20), (_number / 16) % 16 - 8);
		child.translation = location * .7 * scale_factor;
		child.scale *= scale_factor;
		add_child(child);
	pass

func comma_sep(number):
	var string = str(number)
	var mod = string.length() % 3
	var res = ""

	for i in range(0, string.length()):
		if i != 0 && i % 3 == mod:
			res += ","
		res += string[i]

	return res

class Sorter:
	static func sort_ascending(a, b):
		if a["continent"] != null && b["continent"] != null:
			if a["continent"] < b["continent"] && a["country"] < b["country"]:
				return true;
		if a["country"] < b["country"]:
				return true;
		return false;
