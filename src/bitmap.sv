`include "bitmap.svh"

module bitmap # (
	parameter LIST_SIZE = 32
) (
	input logic CLK,
	input logic RSTN,
	input logic [$clog2(LIST_SIZE)-1:0] CLAIM,
	input logic [$clog2(LIST_SIZE)-1:0] FREE,
	output logic [$clog2(LIST_SIZE)-1:0] AVAILABLE,
	input logic [1:0] CONTROL,
	output logic VALID
);

logic [LIST_SIZE-1:0] list;
logic [$clog2(LIST_SIZE):0] free_items;

logic stage_claim;
logic stage_free;
logic stage_search;

assign stage_claim = !RSTN && (CONTROL & `FL_CLAIM_IDLE) != `FL_CLAIM_IDLE;
assign stage_free = !RSTN && (CONTROL & `FL_FREE_IDLE) != `FL_FREE_IDLE;
assign stage_search = !RSTN;

assign VALID = stage_search && free_items;

always_comb begin
	if(stage_search) begin
		for(integer i = 0; i < LIST_SIZE; i++) begin
			if(!list[i]) begin
				AVAILABLE = i;
			end
		end

		if(!list) begin
			AVAILABLE = 0;
		end
	end
end

always @(posedge CLK) begin
	if(stage_claim && CLAIM <= (LIST_SIZE - 1)) begin
		if(CLAIM <= (LIST_SIZE - 1) && !list[CLAIM]) begin
			free_items <= free_items - 1;
			list[CLAIM] <= 1'b1;
		end
	end
end

always @(posedge CLK) begin
	if(stage_free) begin
		if(FREE <= (LIST_SIZE - 1) && list[FREE]) begin
			free_items <= free_items + 1;
			list[FREE] <= 1'b0;
		end
	end
end

always @(posedge CLK) begin
	if(RSTN) begin
		free_items = LIST_SIZE;
		list = 0;

		AVAILABLE = 0;
	end
end

endmodule
