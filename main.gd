extends Control

var files: PackedStringArray
var indent: String = "  |"
var to_md = true
var to_json = false

class CLI:
	static var args_list := {
		["-v", "--version"]: [CLI.print_version, "Prints current parser version"],
		["-json"]: [CLI.set_json, "Outputs an md file (Disabled by default)"],
		["-md"]: [CLI.set_md, "Outputs an md file (Enabled by default)"],
		["-i", "-indent"]: [CLI.set_indent, "Sets the indent string"],
		["--help", "-h", "-?"]: [CLI.generate_help, "Displays this help page"]
	}

	static func generate_help(_next_arg: String, _option_node):
		var help := str(
			(
				"""
=========================================================================\n
Help for fleurparser's CLI.

Usage:
\t%s [SYSTEM OPTIONS] -- [USER OPTIONS] [FILES]...

Use -h in place of [SYSTEM OPTIONS] to see [SYSTEM OPTIONS].
Or use -h in place of [USER OPTIONS] to see [USER OPTIONS].

some useful [SYSTEM OPTIONS] are:
--headless     Run in headless mode.
--quit         Close pixelorama after current command.


[USER OPTIONS]:\n
(The terms in [ ] reflect the valid type for corresponding argument).

"""
				% OS.get_executable_path().get_file()
			)
		)
		for command_group: Array in args_list.keys():
			help += str(
				var_to_str(command_group).replace("[", "").replace("]", "").replace('"', ""),
				"\t\t".c_unescape(),
				args_list[command_group][1],
				"\n".c_unescape()
			)
		help += "========================================================================="
		print(help)

	## Dedicated place for command line args callables
	static func print_version(_next_arg: String, _option_node) -> void:
		print(ProjectSettings.get("application/config/version"))

	static func set_indent(next_arg: String, option_node) -> void:
		option_node.indent = next_arg

	static func set_json(next_arg: String, option_node) -> void:
		option_node.to_json = (next_arg.to_lower() == "true")

	static func set_md(next_arg: String, option_node) -> void:
		option_node.to_md = (next_arg.to_lower() == "true")



func _ready() -> void:
	var logo = (
"""
#       _____ _                 ____
#      |  ___| | ___ _   _ _ __|  _ \\ __ _ _ __ ___  ___ _ __
#      | |_  | |/ _ \\ | | | '__| |_) / _` | '__/ __|/ _ \\ '__|
#      |  _| | |  __/ |_| | |  |  __/ (_| | |  \\__ \\  __/ |
#      |_|   |_|\\___|\\__,_|_|  |_|   \\__,_|_|  |___/\\___|_|
""")
	_handle_cmdline_arguments()
	if not files.is_empty():
		print(logo.replace("#", ""))
		for file_path: String in files:
			print("Parsing: ", file_path)
			var parsed_data: Dictionary = Parser.parse_xml(file_path)
			var result = parsed_data["result"]
			var md_array = parsed_data["md_array"]
			if parsed_data.size() > 0:
				if to_json:
					var file = FileAccess.open(file_path.get_basename() + ".json", FileAccess.WRITE)
					if FileAccess.get_open_error() != OK:
						print("ERROR: ", error_string(FileAccess.get_open_error()))
					var json: String
					if parsed_data.size() == 1:  ## This is the option the code will follow most of the time
						json = JSON.stringify(parsed_data[0], indent, false)
					else:
						json = JSON.stringify(parsed_data, indent, false)
					file.store_string(logo + "\n" + json)
					file.close()
				if to_md:
					var file = FileAccess.open(file_path.get_basename() + ".md", FileAccess.WRITE)
					if FileAccess.get_open_error() != OK:
						print("ERROR: ", error_string(FileAccess.get_open_error()))
					var md_text: String = logo

					var indent: String = "#"
					for line in md_array:
						if line == "<indent>":
							indent += "#"
							continue
						elif line == "</indent>":
							md_text += "\n"
							md_text += "\n"
							indent = indent.erase(0)
							continue
						if "=" in line:
							md_text += "\t" + line + "\n"
						else:
							md_text += "\n" + indent + " " + line + "\n"

					file.store_string(md_text)
					file.close()
		print("\nJob Done!!!\n")
		print("=========================================================================")
	get_tree().quit()


func _handle_cmdline_arguments() -> void:
	var args := OS.get_cmdline_args()
	args.append_array(OS.get_cmdline_user_args())
	if args.is_empty():
		return
	# Load the files first
	for arg in args:
		var file_path := arg
		if file_path.is_relative_path():
			file_path = OS.get_executable_path().get_base_dir().path_join(arg)
		if file_path.ends_with(".xml"):
			if !FileAccess.file_exists(file_path):
				var output = []
				OS.execute("pwd", [], output)
				if output.size() > 0:
					file_path = str(output[0]).replace("\n", "").path_join(arg)
			if FileAccess.file_exists(file_path):
				files.append(file_path)

	var parse_dic := {}
	for command_group: Array in CLI.args_list.keys():
		for command: String in command_group:
			parse_dic[command] = CLI.args_list[command_group][0]
	for i in args.size():  # Handle the rest of the CLI arguments
		var arg := args[i]
		var next_argument := ""
		if i + 1 < args.size():
			next_argument = args[i + 1]
		if arg.begins_with("-") or arg.begins_with("--"):
			if arg in parse_dic.keys():
				var callable: Callable = parse_dic[arg]
				callable.call(next_argument, self)
			else:
				print("==========")
				print("Unknown option: %s" % arg)
				for compare_arg in parse_dic.keys():
					if arg.similarity(compare_arg) >= 0.4:
						print("Similar option: %s" % compare_arg)
				print("==========")
				get_tree().quit()
				break
