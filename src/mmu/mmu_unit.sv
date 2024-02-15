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
logic [9:0] burst_transf_size;
logic [13:0] burst_transf_total;
logic wrapping_transf;

logic [31:0] wrap_lowerbound;
logic [31:0] wrap_upperbound;
logic [31:0] next_addr;
logic [31:0] addr_index;

assign burst_transf_size = 32'b1 << SIZE;
assign burst_beats = ((BURST >> 1) == 2'b00) ? 8'd1 :
	((BURST >> 1) == 2'b01) ? 8'd4 :
	((BURST >> 1) == 2'b10) ? 8'd8 :
	((BURST >> 1) == 2'b11) ? 5'd16 : 5'd0;
assign burst_transf_total = burst_transf_size * burst_beats;
assign wrapping_transf = BURST & 3'b001;

assign wrap_lowerbound = ADDR & -burst_transf_total;
assign wrap_upperbound = (ADDR + burst_transf_total) & -burst_transf_total;

assign addr_index = next_addr >> 2;

task data;
	input int index;

	begin
		if(!WRITE) begin
			READ_DATA <= mem[index];
		end else begin
			mem[index] <= WRITE_DATA;
		end
	end
endtask

always @(posedge CLK) begin
	if(!RSTN && SELX) begin
		if(TRANS == TRANSFER_NONSEQ) begin
			data(ADDR >> 2);

			next_addr <= ADDR + burst_transf_size;
			burst_depth <= 1;

			READYOUT <= 1 >= (burst_transf_total);
			RESP <= 1'b0;
		end else if(TRANS == TRANSFER_SEQ) begin
			data(addr_index);

			next_addr <= next_addr + burst_transf_size;
			burst_depth <= burst_depth + 1;

			READYOUT <= burst_depth >= (burst_transf_total);
			RESP <= 1'b0;
		end else if(TRANS == TRANSFER_IDLE) begin
			READYOUT <= 1'b1;
			RESP <= 1'b0;
		end
	end
end

always @(posedge CLK) begin
	if(RSTN) begin
		READYOUT <= 1'b1;
		RESP <= 1'b0;
	end
end

endmodule
