@tool
extends EditorScript

var memory: PackedByteArray

var program = ""

var instructions = ["AND", "ADD", "SUB", "MUL", "DIV", "INC", "DEC", "GOTO", "PRINT", "JMPIE", "SET"]

var registers = {"X": 0, "Y": 0, "Z": 0}

var tags = {}
var literals = {}

enum flags {
	FL_POS,
	FL_ZERO,
	FL_NEG
}


#math operation function template
func math_operation(line, line_count, token_count, dest, operand1, operand2, operation):
	if line[1] in registers:
		dest = line[1]
	else:
		print("NOT VALID DESTINATION. BREAK AT " + str(line_count) + ", " + str(token_count))
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
		"++":
			registers[dest] += 1
		"--":
			registers[dest] -= 1
		"=":
			registers[dest] = operand1

func tokenizer(input):
	var program_lines = Array(input.split("\n"))
	var index = 0
	
	var output = []
	
	for line in program_lines:
		#remove comments
		program_lines[index] = line.split(";", true, 1)[0]
		program_lines[index] = program_lines[index].replace(",", "")
		
		#string finder
		var buffer = ""
		var add_stuff = false
		for char in program_lines[index]:
			if char == "\"" and !add_stuff:
				add_stuff = true
			elif char == "\"" and add_stuff:
				add_stuff = false
			elif char != "\"" and add_stuff:
				buffer += char
				
		if buffer != "":
			literals[index] = buffer
			buffer = ""
		
		var operands = Array(program_lines[index].split(" ", false))
		
		#preprocessor
		for operand in operands:
			#find tags
			if operand.ends_with(":"):
				#adjust line count by making zero starting index
				tags[operand.replace(":", "")] = index
		
		output.append(operands)
			
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
					"GOTO":
						if line[1] in tags:
							#print("jumping to " + str(tags[line[1]]))
							line_count = int(tags[line[1]])
							token_count = 0
							lexer(tokenizer(program), int(tags[line[1]]))
							return
						else:
							print("NOT VALID TAG. BREAK AT " + str(line_count) + ", " + str(token_count))
							return
					"PRINT":
						if line[1] in registers:
							print(registers[line[1]])
						else:
							print(literals[line_count])
							
					"ADD":
						math_operation(line, line_count, token_count, dest, operand1,
						operand2, "+")
					"SUB":
						math_operation(line, line_count, token_count, dest, operand1,
						operand2, "-")
					"MUL":
						math_operation(line, line_count, token_count, dest, operand1,
						operand2, "*")
					"DIV":
						math_operation(line, line_count, token_count, dest, operand1,
						operand2, "/")
					"INC":
						math_operation(line, line_count, token_count, dest, operand1,
						operand2, "++")
					"DEC":
						math_operation(line, line_count, token_count, dest, operand1,
						operand2, "--")
					"SET":
						math_operation(line, line_count, token_count, dest, operand1,
						operand2, "=")
					"JMPIE":
						if line[1] in registers:
							dest = registers[line[1]]
						else:
							print("NOT VALID DESTINATION. BREAK AT " + str(line_count) + ", " + str(token_count))
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
								print("NOT VALID TAG. BREAK AT " + str(line_count) + ", " + str(token_count))
								return
					
			token_count += 1
		line_count += 1
						
# Called when the node enters the scene tree for the first time.
func _run():
	registers["COND"] = flags.FL_ZERO
	memory.resize(65535)
	
	var file = FileAccess.open("res://bvm/main.bvm.txt", FileAccess.READ)
	program = file.get_as_text()
	
	lexer(tokenizer(program), 0)
	print(registers)
