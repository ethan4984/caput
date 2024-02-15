`ifndef DECODE_SVH_
`define DECODE_SVH_

`define OPCODE_B 7'b1100011

`define IS_BRANCH(INSTR) \
	((INSTR & `OPCODE_B) == `OPCODE_B)

`endif
