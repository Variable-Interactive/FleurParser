extends Control


func _ready() -> void:
	for file_path: String in dir_contents("/home/variable/Programing Projects/Fleur/XMLParser"):
		var parsed_data = parse_fleur(file_path)
		var file = FileAccess.open(file_path.get_basename() + ".txt", FileAccess.WRITE)
		var json = JSON.stringify(parsed_data, "  |", false)
		file.store_string(json)
		file.close()
	get_tree().quit()

func dir_contents(path: String) -> PackedStringArray:
	var out = PackedStringArray()
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				if file_name.ends_with(".xml"):
					out.append(path.path_join(file_name))
			file_name = dir.get_next()
	return out


func parse_fleur(file_path: String) -> Array:
	var parser = XMLParser.new()
	parser.open(file_path)
	var cache_array = []
	while parser.read() != ERR_FILE_EOF:
		if parser.get_node_type() == XMLParser.NODE_ELEMENT:
			var node_name = parser.get_node_name().capitalize()
			var attributes_dict = {}
			for idx in range(parser.get_attribute_count()):
				attributes_dict[parser.get_attribute_name(idx).capitalize()] = parser.get_attribute_value(idx).strip_edges()
			var info := {}
			if not attributes_dict.is_empty():
				info = attributes_dict
			cache_array.append({node_name: info})

		elif parser.get_node_type() == XMLParser.NODE_TEXT:
			var text = (
						parser
						.get_node_data()
						.strip_edges()
						.replace("\n", "")
					)
			text = str(text.split(" ", false)).replace("[", "").replace("]", "").replace("\"", "")
			if not text.is_empty():
				var last_node_name = cache_array[-1].keys()[0]
				cache_array[-1][last_node_name]["value"] = text.capitalize()
				cache_array[-1][last_node_name]["value"] = str(text.replace(", ", " |----| ")).capitalize()

		elif parser.get_node_type() == XMLParser.NODE_ELEMENT_END:
			var parent_name = parser.get_node_name().capitalize()
			var children_dict := []
			while true:
				var child_dict = cache_array.pop_back()
				var keys = child_dict.keys()
				if keys.size() > 0:  # Failsafe
					var child_name = keys[0]
					if child_name != parent_name:
						children_dict.append(child_dict)
					else:
						children_dict.reverse()
						child_dict[parent_name]["sub-properties"] = children_dict
						cache_array.append(child_dict)
						break

	return str_to_var(var_to_str(cache_array).replace("\"sub-properties\": [],", ""))
