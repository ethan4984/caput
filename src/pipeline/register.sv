`include "bitmap.svh"

typedef struct packed {
	logic [4:0] backing_reg;
	logic [7:0] renamed_reg;
} rf_entry;

module register_bank # (
	parameter REG_CNT = 32,
	parameter REG_SIZE = 32
) (
	input logic CLK,
	input logic RSTN
);

rf_entry rf_entries [(REG_CNT/8)-1:0];

logic [$clog2(REG_CNT)-1:0] available;
logic [$clog2(REG_CNT)-1:0] free;
logic [$clog2(REG_CNT)-1:0] claim;
logic [1:0] control;
logic valid;

bitmap # (
	.LIST_SIZE(REG_CNT)
) list (
	.CLK(CLK), .RSTN(RSTN), .CLAIM(claim), .FREE(free), .AVAILABLE(available), .CONTROL(control), .VALID(valid)
);

endmodule
