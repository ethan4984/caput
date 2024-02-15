`include "bitmap.svh"

module main;

logic CLK;
logic RSTN;

initial CLK <= 1'b0;
initial RSTN <= 1'b1;

always #10 CLK = ~CLK;

import mmu_pkg::*;

logic [31:0] ADDR1;
logic [31:0] WRITE_DATA1;
logic [31:0] READ_DATA1;
logic WRITE1;
logic [2:0] SIZE1;
logic [2:0] BURST1;
logic READYOUT1;
logic RESP1;
logic CLAIM1;

logic [31:0] ADDR2;
logic [31:0] WRITE_DATA2;
logic [31:0] READ_DATA2;
logic WRITE2;
logic [2:0] SIZE2;
logic [2:0] BURST2;
logic READYOUT2;
logic RESP2;
logic CLAIM2;

logic [31:0] IP;
logic [31:0] INSTR;
logic VALID;

icache cache (
	.CLK(CLK), .RSTN(RSTN),

	.IP(IP), .INSTR(INSTR), .VALID(VALID),
	.D1_ADDR(ADDR1), .D1_WRITE_DATA(WRITE_DATA1), .D1_READ_DATA(READ_DATA1),
	.D1_WRITE(WRITE1), .D1_SIZE(SIZE1), .D1_BURST(BURST1),
	.D1_READYOUT(READYOUT1), .D1_RESP(RESP1), .D1_CLAIM(CLAIM1)
);

mmu mmu (
	.CLK(CLK), .RSTN(RSTN),

	.D1_ADDR(ADDR1), .D1_WRITE_DATA(WRITE_DATA1), .D1_READ_DATA(READ_DATA1),
	.D1_WRITE(WRITE1), .D1_SIZE(SIZE1), .D1_BURST(BURST1),
	.D1_READYOUT(READYOUT1), .D1_RESP(RESP1), .D1_CLAIM(CLAIM1),

	.D2_ADDR(ADDR2), .D2_WRITE_DATA(WRITE_DATA2), .D2_READ_DATA(READ_DATA2),
	.D2_WRITE(WRITE2), .D2_SIZE(SIZE2), .D2_BURST(BURST2),
	.D2_READYOUT(READYOUT2), .D2_RESP(RESP2), .D2_CLAIM(CLAIM2)
);

initial begin
	$dumpfile("caput.vcd");
	$dumpvars(0, main);
	
	CLAIM2 <= 0;
	IP <= 4;

	# 20

	RSTN <= 1'b0;

	# 640

	$finish;
end

endmodule
