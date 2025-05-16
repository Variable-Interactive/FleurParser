class_name Parser
extends Node


static func parse_xml(file_path: String) -> Array:
	var parser = XMLParser.new()
	parser.open(file_path)

	var tree_array = []
	while parser.read() != ERR_FILE_EOF:
		if parser.get_node_type() == XMLParser.NODE_ELEMENT:  # A new section is detected
			var node_name = parser.get_node_name().capitalize()
			var attributes_dict = {}
			for idx in range(parser.get_attribute_count()):
				var value = parse_attribute(parser.get_attribute_value(idx))
				attributes_dict[parser.get_attribute_name(idx).capitalize()] = value
			tree_array.append({node_name: attributes_dict})

		elif parser.get_node_type() == XMLParser.NODE_TEXT:  # Text (child of above node)
			var value = parse_attribute(parser.get_node_data())
			if not value.is_empty():
				var last_node_name = tree_array[-1].keys()[0]
				tree_array[-1][last_node_name]["value"] = value

		elif parser.get_node_type() == XMLParser.NODE_ELEMENT_END:  # A section has ended (it may contain children)
			var parent_name = parser.get_node_name().capitalize()
			var children_dict := []
			while true:
				var child_dict = tree_array.pop_back()
				var keys = child_dict.keys()
				if keys.size() > 0:  # Failsafe
					var child_name = keys[0]
					if child_name != parent_name:
						children_dict.append(child_dict)
					else:
						children_dict.reverse()
						child_dict[parent_name]["sub-properties"] = children_dict
						tree_array.append(child_dict)
						break
	return str_to_var(var_to_str(tree_array).replace("\"sub-properties\": [],", ""))


## This function just converts the values into a more suitable form
static func parse_attribute(value: String):
	value = value.strip_edges().replace("\n", "")
	var value_array := Array(value.split(" ", false))

	# convert numbers to a form where they can be recognized
	var numbers = 0
	for i in value_array.size():
		var item: String = value_array[i]
		if item.begins_with("."):
			item = "0" + item
		if str_to_var(item) != null:
			if "*" in value:
				var unit_split = item.split("*", false)
				if unit_split.size() == 2:  # ignore all other sizes
					value_array[i] = var_to_str(str_to_var(item)) + " " + unit_split[1]
			else:
				value_array[i] = str_to_var(item)
		# try conversion to numbers where possible
		if typeof(value_array[i]) == TYPE_FLOAT or typeof(value_array[i]) == TYPE_INT:
			numbers += 1

	var output  # Formatted values of the parameters
	if numbers > 0 and  numbers == value_array.size():
		match value_array.size():
			1:
				output = value_array[0]
			2:
				output = Vector2(value_array[0], value_array[1])
			3:
				output = Vector3(value_array[0], value_array[1], value_array[2])
			4:
				output = Vector4(value_array[0], value_array[1], value_array[2], value_array[3])
			_:
				output = value_array
	else:
		value = (
					str(
						value_array
					).replace("[", "")
					.replace("]", "")
					.replace(", ", " |----| ")
					.replace("\"", "")
					.capitalize()
				)
		output = value

	if typeof(output) != TYPE_STRING:
		output = var_to_str(output)
	return output
