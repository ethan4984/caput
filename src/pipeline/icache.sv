`include "pipeline/decode.svh"
`include "mmu/operation.svh"

module icache # (
	INSTR_SIZE = 32,
	CACHE_SIZE = 32
) (
	input logic CLK,
	input logic RSTN,
	input logic [31:0] IP,
	output logic [INSTR_SIZE-1:0] INSTR,
	output logic VALID,

	output logic [31:0] D1_ADDR,
	output logic [31:0] D1_WRITE_DATA,
	input logic [31:0] D1_READ_DATA,
	output logic D1_WRITE,
	output logic [2:0] D1_SIZE,
	output logic [2:0] D1_BURST,
	input logic D1_READYOUT,
	input logic D1_RESP,
	output logic D1_CLAIM
);

import mmu_pkg::*;

logic mmu_ready;
logic mmu_processing;
logic mmu_transfer_complete;

assign mmu_ready = D1_READYOUT && !D1_RESP;
assign mmu_processing = !D1_READYOUT && !D1_RESP;
assign mmu_transfer_complete = 1'b0;

logic [INSTR_SIZE-1:0] instr_cache [0:CACHE_SIZE-1];
logic [$clog2(INSTR_SIZE)-1:0] cache_index;

logic stage_flush;
logic stage_fetch;

logic [31:0] lower_bound;
logic [31:0] upper_bound;

assign stage_flush = !((lower_bound <= IP) && (upper_bound >= IP)) && mmu_ready && !RSTN;
assign stage_fetch = !stage_flush && mmu_processing && !RSTN;

always @(posedge CLK) begin
	if(stage_flush) begin
		lower_bound <= IP;
		upper_bound <= IP + CACHE_SIZE * INSTR_SIZE;
		cache_index <= 0;

		`MMU_READ(D1, 4, BURST_WRAP4, TRANSFER_SIZE_WORD);
	end 
end

always @(posedge CLK) begin
	if(stage_fetch) begin
		$display("%x", D1_READ_DATA);
		instr_cache[cache_index] <= D1_READ_DATA;
		cache_index <= cache_index + 1;
	end
end

always @(posedge CLK) begin
	if(RSTN) begin
		D1_ADDR <= 10000;
		lower_bound <= 32'b0;
		upper_bound <= 32'b0;
	end
end

endmodule
