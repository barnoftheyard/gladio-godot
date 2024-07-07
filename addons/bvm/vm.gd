extends Node3D

#empty global variable for the program
var program = ""

var debug_mode = true

var clock_speed = 0.0
var clock = 0.0

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
	"parse",	#godot expression function calling
	"node_set",
	"node_get"
]

#dictionary for variables
var variables = {"pc": 0, "delta": 0.0}

#the dictionary for tags
var tags = {}
#the dictionary for string literals
var literals = {}

@export var file_path : String = "res://bvm/fizzbuzz.txt"

#math operation function template
func math_operation(line, line_count, token_count, dest, operand1, operand2, operation):
	if line[1] in variables:
		dest = line[1]
	else:
		print("not valid variable. break at " + str(line_count) + ", " + str(token_count))
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
	
	for line in program_lines:
		#remove comments
		program_lines[index] = line.split(";", true, 1)[0]
		#remove any commas that we have
		program_lines[index] = program_lines[index].replace(",", "")
		#remove any tabs that we may have
		program_lines[index] = program_lines[index].replace("\t", "")
		
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
	await get_tree().process_frame
	
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
							#
							lexer(tokenizer(program), int(tags[line[1]]))
							return
						else:
							print("not valid tag. break at " + str(line_count) + ", " + str(token_count))
							return
					"print":
						if line[1] in variables:
							#print(variables[line[1]])
							$Label3D.text = str(variables[line[1]])
						else:
							#print(literals[line_count])
							$Label3D.text = str(literals[line_count])
							
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
								print("not valid destination. break at " + str(line_count) + ", " + str(token_count))
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
								"eq":
									if dest == operand1:
										if line[4] in tags:
											#print("compare jumping to " + str(tags[line[3]]))
											line_count = int(tags[line[4]])
											token_count = 0
											lexer(tokenizer(program), int(tags[line[4]]))
											return
										else:
											print("not valid tag. break at " + str(line_count) + ", " + str(token_count))
											return
								"neq":
									if dest != operand1:
										if line[4] in tags:
											#print("compare jumping to " + str(tags[line[3]]))
											line_count = int(tags[line[4]])
											token_count = 0
											lexer(tokenizer(program), int(tags[line[4]]))
											return
										else:
											print("not valid tag. break at " + str(line_count) + ", " + str(token_count))
											return
								"gt":
									if dest > operand1:
										if line[4] in tags:
											#print("compare jumping to " + str(tags[line[3]]))
											line_count = int(tags[line[4]])
											token_count = 0
											lexer(tokenizer(program), int(tags[line[4]]))
											return
										else:
											print("not valid tag. break at " + str(line_count) + ", " + str(token_count))
											return
								"lt":
									if dest < operand1:
										if line[4] in tags:
											#print("compare jumping to " + str(tags[line[3]]))
											line_count = int(tags[line[4]])
											token_count = 0
											lexer(tokenizer(program), int(tags[line[4]]))
											return
										else:
											print("not valid tag. break at " + str(line_count) + ", " + str(token_count))
											return
								"gte":
									if dest >= operand1:
										if line[4] in tags:
											#print("compare jumping to " + str(tags[line[3]]))
											line_count = int(tags[line[4]])
											token_count = 0
											lexer(tokenizer(program), int(tags[line[4]]))
											return
										else:
											print("not valid tag. break at " + str(line_count) + ", " + str(token_count))
											return
								"lte":
									if dest <= operand1:
										if line[4] in tags:
											#print("compare jumping to " + str(tags[line[3]]))
											line_count = int(tags[line[4]])
											token_count = 0
											lexer(tokenizer(program), int(tags[line[4]]))
											return
										else:
											print("not valid tag. break at " + str(line_count) + ", " + str(token_count))
											return
						else:
							print("invalid jump declaration. " +
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
											print("need valid type for variable. " +
											"break at " + str(line_count) + ", " + str(token_count))
											return
							else:
								print("variable already exists. " +
								"break at " + str(line_count) + ", " + str(token_count))
								return
						else:
							print("invalid variable declaration. " +
							"break at " + str(line_count) + ", " + str(token_count))
							return
					"parse":
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
							print("invalid parse declaration. " +
							"break at " + str(line_count) + ", " + str(token_count))
							return
					"node_set":
						if line.size() > 3:
							var node = get_node(line[1])
							if line[2] in node:
								node.set(line[2], variables[line[3]])
							else:
								print("property not found. " +
								"break at " + str(line_count) + ", " + str(token_count))
								return
						else:
							print("invalid node set declaration. " +
							"break at " + str(line_count) + ", " + str(token_count))
							return
					"node_get":
						if line.size() > 3:
							var node = get_node(line[1])
							if line[2] in node:
								variables[line[3]] = node.get(line[2])
							else:
								print("property not found. " +
								"break at " + str(line_count) + ", " + str(token_count))
								return
						else:
							print("invalid node set declaration. " +
							"break at " + str(line_count) + ", " + str(token_count))
							return
			token_count += 1
		line_count += 1
		#update the program counter
		variables["pc"] = line_count
		
func _process(delta):
	variables["delta"] = delta
	clock -= delta
	
	if clock < 0:
		clock = clock_speed
	
# Called when the node enters the scene tree for the first time.
func _on_tree_entered():
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		print("Unable to access file: " + str(file.get_open_error()))
		return
		
	program = file.get_as_text()
	
	lexer(tokenizer(program), 0)
	if debug_mode:
		print(variables)
	
	return
