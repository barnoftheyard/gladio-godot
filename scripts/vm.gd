@tool
extends EditorScript

var memory: PackedByteArray

#empty global variable for the program
var program = ""

var debug_mode = true

#the instruction list
var instructions = ["and", "add", "sub", "mul", "div", "inc", "dec", "goto", "print", "jmpie", 
	"set", "mod", "jmpine"]

var registers = {"a": 0, "b": 0, "c": 0, "d": 0, "e": 0, "f": 0, "pc": 0}

#the dictionary for tags
var tags = {}
#the dictionary for string literals
var literals = {}


#math operation function template
func math_operation(line, line_count, token_count, dest, operand1, operand2, operation):
	if line[1] in registers:
		dest = line[1]
	else:
		print("not valid destination. break at " + str(line_count) + ", " + str(token_count))
		return
	
	if line.size() > 2:
		if line[2] in registers:
			operand1 = registers[line[2]]  
		elif line[2].is_valid_int():
			operand1 = int(line[2])
	
	match operation:
		"+":
			registers[dest] += operand1
		"-":
			registers[dest] -= operand1
		"*":
			registers[dest] *= operand1
		"/":
			registers[dest] /= operand1
		"%":
			registers[dest] %= operand1
		"++":
			registers[dest] += 1
		"--":
			registers[dest] -= 1
		"=":
			registers[dest] = operand1

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
		
		#string finder
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
						if line[1] in registers:
							print(registers[line[1]])
						else:
							print(literals[line_count])
							
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
					"jmpie":
						if line[1] in registers:
							dest = registers[line[1]]
						else:
							print("not valid destination. break at " + str(line_count) + ", " + str(token_count))
							return
							
						if line[2] in registers:
							operand1 = registers[line[2]]  
						else:
							operand1 = int(line[2])
						
						if int(dest) == int(operand1):
							if line[3] in tags:
								#print("compare jumping to " + str(tags[line[3]]))
								line_count = int(tags[line[3]])
								token_count = 0
								lexer(tokenizer(program), int(tags[line[3]]))
								return
							else:
								print("not valid tag. break at " + str(line_count) + ", " + str(token_count))
								return
					
			token_count += 1
		line_count += 1
		#update the program counter
		registers["pc"] = line_count
						
# Called when the node enters the scene tree for the first time.
func _run():
	memory.resize(65535)
	
	var file = FileAccess.open("res://bvm/fizzbuzz.bvm", FileAccess.READ)
	program = file.get_as_text()
	
	lexer(tokenizer(program), 0)
	if debug_mode:
		print(registers)
	
	return
