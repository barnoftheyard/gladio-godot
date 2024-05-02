@tool
extends EditorScript

var memory: PackedByteArray

var program = "
AND R0, R0, 0                      ; clear R0
LOOP                               ; label at the top of our loop
ADD R0, R0, 1                      ; add 1 to R0 and store back in R0
ADD R1, R0, -10                    ; subtract 10 from R0 and store back in R1
BRn LOOP                           ; go back to LOOP if the result was negative"

var registers = {
	R0 = null,
	R1 = null,
	R2 = null,
	R3 = null,
	R4 = null,
	R5 = null,
	R6 = null,
	R7 = null,
	PC = null,
	COND = null
}

enum flags {
	FL_POS,
	FL_ZERO,
	FL_NEG
}

func instruction_and(op1, op2, op3):
	pass

# Called when the node enters the scene tree for the first time.
func _run():
	registers["COND"] = flags.FL_ZERO
	memory.resize(65535)
	
	var program_lines = Array(program.split("\n"))
	var index = 0
	
	for line in program_lines:
		#remove comments
		program_lines[index] = line.split(";", true, 1)[0]
		
		var operands = Array(program_lines[index].split(" ", false, 0))
			
		
		#match operands[0]:
			#"AND":
				#print("AND FOUND")
		
		#print(operands)
		index += 1
	
	program_lines.pop_front()
	print(program_lines)

