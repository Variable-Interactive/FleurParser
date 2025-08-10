class_name Parser
extends Node


static func parse_xml(file_path: String) -> Dictionary:
	var md_array = PackedStringArray()
	var parser = XMLParser.new()
	parser.open(file_path)
	var tree_array = []
	var text_added_last_node := false

	while parser.read() != ERR_FILE_EOF:
		if parser.get_node_type() == XMLParser.NODE_ELEMENT:  # A new section is detected
			var node_name = parser.get_node_name().capitalize()
			var attributes_dict = {}
			md_array.append(node_name)  # new entry
			for idx in range(parser.get_attribute_count()):
				var prop_name: String = parser.get_attribute_name(idx).capitalize()
				var value: String = parse_attribute(parser.get_attribute_value(idx))
				attributes_dict[prop_name] = value
				md_array.append(prop_name + " = " + value )  # new value
			tree_array.append({node_name: attributes_dict})

		elif parser.get_node_type() == XMLParser.NODE_TEXT:  # Text (child of above node)
			var value = parse_attribute(parser.get_node_data())
			if not value.is_empty():
				text_added_last_node = true
				var last_node_name = tree_array[-1].keys()[0]
				tree_array[-1][last_node_name]["value"] = value
				md_array.append("value = " + value )  # new value

		elif parser.get_node_type() == XMLParser.NODE_ELEMENT_END:  # A section has ended (it may contain children)
			var parent_name = parser.get_node_name().capitalize()
			if text_added_last_node:
				text_added_last_node = false
				continue
			var children_dict_array := []
			var parent_pos = md_array.rfind(parent_name)
			if tree_array[-1].keys()[0] == parent_name:  # Empty section
				tree_array.remove_at(tree_array.size() - 1)
				md_array.resize(md_array.size() - 1)
				continue
			while true and tree_array.size() > 0:
				var child_dict: Dictionary = tree_array.pop_back()
				var keys = child_dict.keys()
				var child_name = keys[0]
				if child_name != parent_name:
					children_dict_array.append(child_dict)
				else:
					if not children_dict_array.is_empty():
						children_dict_array.reverse()
						child_dict[parent_name]["sub-properties"] = children_dict_array
						tree_array.append(child_dict)

						# md indentation
						md_array.insert(parent_pos + 1, "<indent>")
						md_array.append("</indent>")
					break
	return {
		"result": str_to_var(var_to_str(tree_array).replace("\"sub-properties\": [],", "")),
		"md_array": md_array
		}


## This function just converts the values into a more suitable form
static func parse_attribute(value: String) -> String:
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
