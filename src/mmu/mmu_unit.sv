//	READYOUT    RESP
//	0           0       PROCESSING
//	1			0       READY
//	0           1       ERROR FIRST CYCLE
//	1           1       ERROR SECOND CYCLE

module mmu_unit # (
	parameter MEM_SIZE = 13'h80
) (
	input logic CLK,
	input logic RSTN,
	input logic SELX,
	input logic [31:0] ADDR,
	input logic [31:0] WRITE_DATA,
	output logic [31:0] READ_DATA,
	input logic WRITE,
	input logic [2:0] SIZE,
	input logic [2:0] BURST,
	input logic [2:0] TRANS,
	output logic TRANSFER_COMPLETE,
	output logic READYOUT,
	output logic RESP
);

import mmu_pkg::*;

logic [31:0] mem [0:(MEM_SIZE / 4)-1];

initial begin
	$readmemh("mem.dat", mem);
end

logic [4:0] burst_depth;
logic [4:0] burst_beats;
logic [9:0] burst_transfer_size;
logic [13:0] burst_transfer_total;
logic wrapping_transfer;

logic [31:0] wrap_lowerbound;
logic [31:0] wrap_upperbound;
logic [31:0] next_addr;
logic [31:0] addr_index;

assign burst_transfer_size = 32'b1 << SIZE;
assign burst_beats = ((BURST >> 1) == 2'b00) ? 8'd1 :
	((BURST >> 1) == 2'b01) ? 8'd4 :
	((BURST >> 1) == 2'b10) ? 8'd8 :
	((BURST >> 1) == 2'b11) ? 5'd16 : 5'd0;
assign burst_transfer_total = burst_transfer_size * burst_beats;
assign wrapping_transfer = !(BURST & 3'b001);

assign wrap_lowerbound = ADDR & -burst_transfer_total;
assign wrap_upperbound = (ADDR + burst_transfer_total) & -burst_transfer_total;

assign addr_index = next_addr >> 2;

task stage_transfer;
	input logic [(MEM_SIZE / 4)-1:0] index;

	begin
		if(!WRITE) begin
			READ_DATA <= mem[index];
		end else begin
			mem[index] <= WRITE_DATA;
		end
	end
endtask

task stage_address;
	input logic [31:0] address;
	input logic [4:0] burst;

	begin
		if(wrapping_transfer && wrap_upperbound <= next_addr) begin
			next_addr <= wrap_lowerbound;
		end else begin
			next_addr <= address + burst_transfer_size;
		end

		burst_depth <= burst + 1;
	end
endtask

always @(posedge CLK) begin
	if(!RSTN && SELX) begin
		if(TRANS == TRANSFER_NONSEQ) begin
			stage_transfer(ADDR >> 2);
			stage_address(ADDR, 0);

			TRANSFER_COMPLETE <= 0;
			READYOUT <= 1 >= (burst_transfer_total);
			RESP <= 1'b0;
		end else if(TRANS == TRANSFER_SEQ && !TRANSFER_COMPLETE) begin
			stage_transfer(addr_index);
			stage_address(next_addr, burst_depth);

			TRANSFER_COMPLETE <= ((burst_depth + 1) >= burst_transfer_total);
			READYOUT <= burst_depth >= burst_transfer_total;
			RESP <= 1'b0;
		end else if(TRANS == TRANSFER_SEQ && TRANSFER_COMPLETE) begin
			READYOUT <= 1'b1;
			RESP <= 1'b0;
		end if(TRANS == TRANSFER_IDLE) begin
			READYOUT <= 1'b1;
			RESP <= 1'b0;
		end
	end
end

always @(posedge CLK) begin
	if(RSTN) begin
		burst_depth <= 0;

		READ_DATA <= 0;
		READYOUT <= 1'b1;
		RESP <= 1'b0;
	end
end

endmodule
