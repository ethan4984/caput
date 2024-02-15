package mmu_pkg;
	localparam BUS_SIZE = 32;

	localparam TRANSFER_IDLE = 2'b00;
	localparam TRANSFER_BUSY = 2'b01;
	localparam TRANSFER_NONSEQ = 2'b10;
	localparam TRANSFER_SEQ = 2'b11;

	localparam BURST_SINGLE = 3'b000;
	localparam BURST_INCR = 3'b001;
	localparam BURST_WRAP4 = 3'b010;
	localparam BURST_INCR4 = 3'b011;
	localparam BURST_WRAP8 = 3'b100;
	localparam BURST_INCR8 = 3'b101;
	localparam BURST_WRAP16 = 3'b110;
	localparam BURST_INCR16 = 3'b111;

	localparam TRANSFER_SIZE_BYTE = 3'b000;
	localparam TRANSFER_SIZE_HALFWORD = 3'b001;
	localparam TRANSFER_SIZE_WORD = 3'b010;
	localparam TRANSFER_SIZE_DOUBLEWORD = 3'b011;
	localparam TRANSFER_SIZE_4WORDLINE = 3'b100;
	localparam TRANSFER_SIZE_8WORDLINE = 3'b101;
	localparam TRANSFER_SIZE_16WORDLINE = 3'b110;
	localparam TRANSFER_SIZE_32WORDLINE = 3'b111;
endpackage
