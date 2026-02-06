extends Node3D
class_name SmplscriptInterpreter

#empty global variable for the program
var program = ""

@export var debug_mode = false

var clock_speed = 0.0
var clock = 0.0

var stdout = ""

var sprite = null
var label = null

#the instruction list
const instructions = [
	"add", 		#numerical addition
	"sub", 		#numerical subtraction
	"mul", 		#numerical multiplication
	"div", 		#numerical division
	"inc", 		#numerical incrementation
	"dec", 		#numerical decrementation
	"mod", 		#moduluo
	"print", 	#prints string literals
	"goto", 	#jump to tag
	"if", 		#compare and jump
	"set", 		#variable adjustment
	"let",		#variable declaration
	"free",		#variable freeing
	"parse",	#godot expression function calling
	"node_set",	#godot node setting
	"node_get"	#node node getting
]

#dictionary for variables
var variables = {"pc": 0, "delta": 0.0}

#the dictionary for tags
var tags = {}
#the dictionary for string literals
var literals = {}

@export_file("*.smpl") var file_path = ""
@export var show_label = true
@export var show_icon = true
@export var quiet = false

func error_print(string):
	print(string)
	label.modulate = Color(1, 0, 0)
	sprite.modulate = Color(1, 0, 0)
	label.text = string
	label = null

#math operation function template
func math_operation(line, line_count, token_count, dest, operand1, operand2, operation):
	if line[1] in variables:
		dest = line[1]
	else:
		error_print("not valid variable. break at " + str(line_count) + ", " + str(token_count))
		return
	
	if line.size() > 2:
		if line[2] in variables:
			operand1 = variables[line[2]]  
		elif line[2].is_valid_int():
			operand1 = int(line[2])
		elif line[2].is_valid_float():
			operand1 = float(line[2])
	
	match operation:
		"+":
			variables[dest] += operand1
		"-":
			variables[dest] -= operand1
		"*":
			variables[dest] *= operand1
		"/":
			variables[dest] /= operand1
		"%":
			#moduluo operator only works on ints so we have to use fmod on floats
			if operand1 is int:
				variables[dest] %= operand1
			elif operand1 is float:
				variables[dest] = fmod(variables[dest], variables[dest])
		"++":
			variables[dest] += 1
		"--":
			variables[dest] -= 1
		"=":
			variables[dest] = operand1

func tokenizer(input):
	#split the program by lines
	var program_lines = Array(input.split("\n"))
	var index = 0
	
	var output = []
	var delimiters = [";", ",", "\t"]
	
	for line in program_lines:
		#remove semi-colon and the comment following it
		program_lines[index] = line.split(";", true, 1)[0]
		
		#remove any unwanted characters
		for character in delimiters:
			program_lines[index] = program_lines[index].replace(character, "")
		
		#string literal finder
		var buffer = ""
		var add_stuff = false
		
		#for every character in the line that we are processing
		for char in program_lines[index]:
			#when we find our first "
			if char == "\"" and !add_stuff:
				add_stuff = true
			#when we find the last "
			elif char == "\"" and add_stuff:
				add_stuff = false
			#when we're adding all the characters in between the " "
			elif char != "\"" and add_stuff:
				buffer += char
		
		#if our buffer is not empty, create a key in our literal dictionary with the name
		#of the line in the program we found it in and set the value to our string
		#then clear the buffer	
		if buffer != "":
			literals[index] = buffer
			buffer = ""
		
		#split all the operands by whitespace
		var operands = Array(program_lines[index].split(" ", false))
		
		#the tag finder
		for operand in operands:
			#find tags
			if operand.ends_with(":"):
				#adjust line count by making zero starting index
				tags[operand.replace(":", "")] = index
		
		#append our the tokens to our program
		output.append(operands)
		
		#incrementing the index, our line count, by one
		index += 1
		
	return output
	
	
var line_count = 0
var token_count = 0

	
func lexer(input, branch_point):
	#makes the script fire at clock rate
	if is_inside_tree():
		await get_tree().process_frame
	else:
		return
	
	#process line starting at the branch point (the line specified to start from)
	for line in input.slice(int(branch_point)):
		
		for token in line:
			if token in instructions:
				var dest = null
				var operand1 = null
				var operand2 = null
				
				match token:
					"goto":
						if line[1] in tags:
							#print("jumping to " + str(tags[line[1]]))
							#set the line count to our point that we're jumping to, and set the token
							#count to zero
							line_count = int(tags[line[1]])
							token_count = 0
							#branch out to a new tag
							lexer(tokenizer(program), int(tags[line[1]]))
							return
						else:
							error_print("not valid tag. break at " + str(line_count) + ", " + str(token_count))
							return
					"print":
						if line[1] in variables:
							stdout = str(variables[line[1]])
							if !quiet:
								print(str(variables[line[1]]))
						
						#ho lee phuk this took way too much time to fix	
						elif literals.find_key(line[1].replace("\"", "")) != null:
							stdout = literals[line_count]
							if !quiet:
								print(literals[line_count])
								
						else:
							error_print("invalid print input. " + str(line_count) + ", " + str(token_count))
							return
							
					"add":
						math_operation(line, line_count, token_count, dest, operand1,
						operand2, "+")
					"sub":
						math_operation(line, line_count, token_count, dest, operand1,
						operand2, "-")
					"mul":
						math_operation(line, line_count, token_count, dest, operand1,
						operand2, "*")
					"div":
						math_operation(line, line_count, token_count, dest, operand1,
						operand2, "/")
					"inc":
						math_operation(line, line_count, token_count, dest, operand1,
						operand2, "++")
					"dec":
						math_operation(line, line_count, token_count, dest, operand1,
						operand2, "--")
					"set":
						math_operation(line, line_count, token_count, dest, operand1,
						operand2, "=")
					"mod":
						math_operation(line, line_count, token_count, dest, operand1,
						operand2, "%")
					"if":
						if line.size() > 4:
							if line[2] in variables:
								dest = variables[line[2]]
							else:
								error_print("not valid destination. break at " + str(line_count) + ", " + str(token_count))
								return
								
							if line[3] in variables:
								operand1 = variables[line[3]]  
							elif line[3].is_valid_int():
								operand1 = int(line[3])
							elif line[3].is_valid_float():
								operand1 = float(line[3])
								
							#this code is messy due to it not working when put into a function,
							#likes to recurse infinitely for some reason
							match line[1]:
								"==":
									if dest == operand1:
										if line[4] in tags:
											#print("compare jumping to " + str(tags[line[3]]))
											line_count = int(tags[line[4]])
											token_count = 0
											#branch out to a tag
											lexer(tokenizer(program), int(tags[line[4]]))
											return
										else:
											error_print("not valid tag. break at " + str(line_count) + ", " + str(token_count))
											return
								"!=":
									if dest != operand1:
										if line[4] in tags:
											#print("compare jumping to " + str(tags[line[3]]))
											line_count = int(tags[line[4]])
											token_count = 0
											#branch out to a tag
											lexer(tokenizer(program), int(tags[line[4]]))
											return
										else:
											error_print("not valid tag. break at " + str(line_count) + ", " + str(token_count))
											return
								">":
									if dest > operand1:
										if line[4] in tags:
											#print("compare jumping to " + str(tags[line[3]]))
											line_count = int(tags[line[4]])
											token_count = 0
											#branch out to a tag
											lexer(tokenizer(program), int(tags[line[4]]))
											return
										else:
											error_print("not valid tag. break at " + str(line_count) + ", " + str(token_count))
											return
								"<":
									if dest < operand1:
										if line[4] in tags:
											#print("compare jumping to " + str(tags[line[3]]))
											line_count = int(tags[line[4]])
											token_count = 0
											#branch out to a tag
											lexer(tokenizer(program), int(tags[line[4]]))
											return
										else:
											error_print("not valid tag. break at " + str(line_count) + ", " + str(token_count))
											return
								">=":
									if dest >= operand1:
										if line[4] in tags:
											#print("compare jumping to " + str(tags[line[3]]))
											line_count = int(tags[line[4]])
											token_count = 0
											#branch out to a tag
											lexer(tokenizer(program), int(tags[line[4]]))
											return
										else:
											error_print("not valid tag. break at " + str(line_count) + ", " + str(token_count))
											return
								"<=":
									if dest <= operand1:
										if line[4] in tags:
											#print("compare jumping to " + str(tags[line[3]]))
											line_count = int(tags[line[4]])
											token_count = 0
											#branch out to a tag
											lexer(tokenizer(program), int(tags[line[4]]))
											return
										else:
											error_print("not valid tag. break at " + str(line_count) + ", " + str(token_count))
											return
						else:
							error_print("invalid jump declaration. " +
							"break at " + str(line_count) + ", " + str(token_count))
							return
					"let":
						#see if we have three operands to our function
						if line.size() > 3:
							#see if we dont already have an existing variable
							if !line[2] in variables:
								if line[3] != null:
									match line[1]:
										"int":
											variables[line[2]] = int(line[3])
										"float":
											variables[line[2]] = float(line[3])
										"string":
											variables[line[2]] = literals[line_count]
										"vec3":
											variables[line[2]] = Vector3(float(line[3]), float(line[4]), float(line[5]))
										_:
											error_print("need valid type for variable. " +
											"break at " + str(line_count) + ", " + str(token_count))
											return
							else:
								error_print("variable already exists. " +
								"break at " + str(line_count) + ", " + str(token_count))
								return
						else:
							error_print("invalid variable declaration. " +
							"break at " + str(line_count) + ", " + str(token_count))
							return
					"free":
						if line.size() > 1:
							if line[1] in variables:
								variables.erase(line[1])
						else:
							error_print("invalid variable free. " +
							"break at " + str(line_count) + ", " + str(token_count))
							return
					"parse":
						#the first part of the line is the operation itself
						if line.size() > 1:
							var expression = Expression.new()
							
							#arguments is the name of the variables that we'll be using whilst the
							#values is the array of the values of those specific variables
							var arguments = []
							var values = []
							
							#get all tokens after the string literal and see if they're in the
							#variable list
							for value in line.slice(2):
								if value in variables:
									arguments.append(value)
									values.append(variables[value])
							
							expression.parse(literals[line_count], arguments)
							expression.execute([values], Node3D)
						else:
							error_print("invalid parse declaration. " +
							"break at " + str(line_count) + ", " + str(token_count))
							return
					"node_set":
						if line.size() > 3:
							var node = get_node(line[1])
							if line[2] in node:
								node.set(line[2], variables[line[3]])
							else:
								error_print("property not found. " +
								"break at " + str(line_count) + ", " + str(token_count))
								return
						else:
							error_print("invalid node set declaration. " +
							"break at " + str(line_count) + ", " + str(token_count))
							return
					"node_get":
						if line.size() > 3:
							var node = get_node(line[1])
							if line[2] in node:
								variables[line[3]] = node.get(line[2])
							else:
								error_print("property not found. " +
								"break at " + str(line_count) + ", " + str(token_count))
								return
						else:
							error_print("invalid node set declaration. " +
							"break at " + str(line_count) + ", " + str(token_count))
							return
			token_count += 1
		line_count += 1
		#update the program counter
		variables["pc"] = line_count
		
func _process(delta):
	#both pc(int) and delta(float) are always present within the variables
	variables["delta"] = delta
	clock -= delta
	
	if clock < 0:
		clock = clock_speed
	
	if label != null:
		label.text = stdout
	
# Called when the node enters the scene tree for the first time.
func _enter_tree():
	
	#create the little icon and label
	sprite = Sprite3D.new()
	label = Label3D.new()
	
	add_child(sprite)
	add_child(label)
	
	sprite.set_billboard_mode(BaseMaterial3D.BILLBOARD_ENABLED)
	sprite.position.y += 1
	sprite.texture = load("res://addons/smplscript/icon.png")
		
	label.set_billboard_mode(BaseMaterial3D.BILLBOARD_ENABLED)
	label.double_sided = false
	
	
	#show the icons/labels through the options
	if !show_icon:
		sprite.hide()
	else:
		sprite.show()
		
	if !show_label:
		label.hide()
	else:
		label.show()
	
	#if it can't access the file path
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null and file_path != "":
		error_print("Unable to access file: " + str(file.get_open_error()))
		return
		
	program = file.get_as_text()
	
	#the big finale!
	lexer(tokenizer(program), 0)
	
	if debug_mode:
		print(variables)
	
	return
