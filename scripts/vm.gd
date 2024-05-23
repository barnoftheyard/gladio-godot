@tool
extends EditorScript

var memory: PackedByteArray

var program = "
ADD Y 2
GOTO LOOP
ADD X 5
MUL Y 2
LOOP:
ADD X 100"

var instructions = ["AND", "ADD", "SUB", "MUL", "DIV", "INC", "DEC", "GOTO"]

var registers = {"X": 0, "Y": 0}

var tags = {}

enum flags {
	FL_POS,
	FL_ZERO,
	FL_NEG
}

func math_operation(line, line_count, token_count, dest, operand1, operand2, operation):
	if line[1] in registers:
		dest = line[1]
	else:
		print("NOT VALID DESTINATION. BREAK AT " + str(line_count) + ", " + str(token_count))
		return
		
	operand1 = registers[line[2]] if line[2] in registers else int(line[2])
	
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

func tokenizer(input):
	var program_lines = Array(input.split("\n"))
	var index = 0
	
	var output = []
	
	for line in program_lines:
		#remove comments
		program_lines[index] = line.split(";", true, 1)[0]
		program_lines[index] = program_lines[index].replace(",", "")
		
		var operands = Array(program_lines[index].split(" ", false, 0))
		
		output.append(operands)
			
		index += 1
		
	output.pop_front()
	return output
	
	
var line_count = 0
var token_count = 0
	
func lexer(input, branch_point):
	for line in input.slice(branch_point):
		for token in line:
			if token in instructions:
				var dest = null
				var operand1 = null
				var operand2 = null
				
				match token:
					"GOTO":
						if line[1] in tags:
							print(line[1])
							lexer(tokenizer(program), int(tags[line[1]]))
						else:
							print("NOT VALID TAG. BREAK AT " + str(line_count) + ", " + str(token_count))
							return
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
					
			token_count += 1
		line_count += 1
						
# Called when the node enters the scene tree for the first time.
func _run():
	registers["COND"] = flags.FL_ZERO
	memory.resize(65535)
	
	lexer(tokenizer(program), 0)
	print(registers)
