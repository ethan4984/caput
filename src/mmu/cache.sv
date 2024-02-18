module cache # (
	parameter LINE_SIZE = 32,
	parameter LINE_CNT = 32
) (
	input logic CLK,
	input logic RSTN,
	input logic FLUSH,
	input logic [31:0] LOWERBOUND_DOMAIN,
	input logic [31:0] ADDR,
	input logic WRITE,
	input logic REQ_VALID,
	output logic [LINE_SIZE-1:0] DATA,
	output logic RESP_VALID,

	output logic [31:0] DX_ADDR,
	output logic [31:0] DX_WRITE_DATA,
	input logic [31:0] DX_READ_DATA,
	output logic DX_WRITE,
	output logic [2:0] DX_SIZE,
	output logic [2:0] DX_BURST,
	input logic DX_READYOUT,
	input logic DX_RESP,
	input logic DX_TRANSFER_COMPLETE,
	output logic DX_CLAIM
);

import mmu_pkg::*;

logic mmu_transfer_request;
logic mmu_transfer_processing;
logic mmu_transfer_current_index;

logic [31:0] mmu_req_addr;
logic [2:0] mmu_req_burst;
logic [2:0] mmu_req_size;

assign mmu_transfer_request = DX_READYOUT && !DX_RESP;
assign mmu_transfer_processing = !DX_READYOUT && !DX_RESP;

logic [LINE_SIZE-1:0] lines [0:LINE_CNT-1];
logic [LINE_CNT-1:0] line_status;
logic line_index;

logic stage_address;
logic stage_flush;
logic stage_fetch;

assign line_index = (ADDR - LOWERBOUND_DOMAIN) >> $clog2(LINE_SIZE / 8);

`define STAGE_NEXT(FROM, TO) \
	stage_``FROM <= 1'b0; \
	stage_``TO <= 1'b1;

task calculate_transfer_parameters;
	input logic [31:0] address;
	input logic [31:0] size;

	begin
		mmu_req_addr <= address;
		mmu_req_burst <= BURST_INCR;
		mmu_req_size <= TRANSFER_SIZE_WORD;
	end
endtask

always @(posedge CLK) begin
	if(!RSTN && stage_address && REQ_VALID && FLUSH) begin
		calculate_transfer_parameters(LOWERBOUND_DOMAIN, LINE_SIZE * LINE_CNT);	
		`STAGE_NEXT(address, flush);
	end
end

always @(posedge CLK) begin
	if(!RSTN && stage_address && REQ_VALID && !FLUSH) begin
		if(line_status[line_index]) begin // cache miss
			calculate_transfer_parameters(LOWERBOUND_DOMAIN + (line_index << $clog2(LINE_SIZE / 8)), LINE_SIZE);
			`STAGE_NEXT(address, flush);
		end else begin // cache hit
			`STAGE_NEXT(address, fetch);
		end
	end
end

always @(posedge CLK) begin
	if(!RSTN && stage_flush) begin
		if(mmu_transfer_request) begin
			`MMU_READ(DX, mmu_req_addr, mmu_req_burst, mmu_req_size);
		end else if(mmu_transfer_processing) begin
			lines[mmu_transfer_current_index] <= DX_READ_DATA;
			line_status[line_index] <= 1'b0;
			mmu_transfer_current_index <= mmu_transfer_current_index + 1;
		end

		if(DX_TRANSFER_COMPLETE) begin
			`MMU_RELEASE(DX);
			`STAGE_NEXT(flush, fetch);
		end
	end
end

always @(posedge CLK) begin
	if(stage_fetch) begin
		DATA <= lines[line_index];
		`STAGE_NEXT(fetch, address);
	end
end

always @(posedge CLK) begin
	if(RSTN) begin
	end
end

endmodule
