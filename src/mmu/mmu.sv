//	Operations:
//		TRANSFER:
//			Cycle 1:
//				Driver sets WRITE, ADDR, SIZE, BURST, CLAIM, and if applicable
//				WRITE_DATA
//
//				Arbiter sets TRANS=TRANSFER_NONSEQ and schedules the current
//				drivers control over the bus, READYOUT=1 and RESP=0 indicates
//				a unit is ready to begin a transfer
//
//			Cycle 2:
//				Unit recognises that a non-sequential transfer has begun, performs the
//				data transfer, and sets next_addr=ADDR+BURST_TRANSFER_SIZE, burst_depth=1
//				in preparation for the possibility of a burst transfer. Sets
//				READYOUT and RESP according to burst depth and the total
//				calculated bursts.
//
//				Arbiter sets TRANS=TRANSFER_SEQ
//
//			Cycle 3:
//				Unit recognises that a non-sequential transfer has begun, it
//				is going to set burst_depth=burst_depth+1 and
//				next_addr=next_addr+BURST_TRANSFER_SIZE in preparation for the
//				next transfer. Sets READYOUT and RESP according to burst depth
//				and the total calculated bursts. 
//
//				A sequential burst transfer terminated when READYOUT=1 and
//				RESP=0, a burst transfer continues when READYOUT=0 and RESP=0

module mmu # (
	localparam DRIVER_CNT = 2
) ( 
	input logic CLK,
	input logic RSTN,

	// Driver 1
	input logic [31:0] D1_ADDR,
	input logic [31:0] D1_WRITE_DATA,
	output logic [31:0] D1_READ_DATA,
	input logic D1_WRITE,
	input logic [2:0] D1_SIZE,
	input logic [2:0] D1_BURST,
	output logic D1_READYOUT,
	output logic D1_RESP,
	input logic D1_CLAIM,

	// Driver 2
	input logic [31:0] D2_ADDR,
	input logic [31:0] D2_WRITE_DATA,
	output logic [31:0] D2_READ_DATA,
	input logic D2_WRITE,
	input logic [2:0] D2_SIZE,
	input logic [2:0] D2_BURST,
	output logic D2_READYOUT,
	output logic D2_RESP,
	input logic D2_CLAIM
);

import mmu_pkg::*;

logic [DRIVER_CNT-1:0] waiters;
logic [DRIVER_CNT-1:0] current_driver;

logic [DRIVER_CNT-1] index;
logic found;

logic selx;
logic seldef;

logic [31:0] addr;
logic [31:0] write_data;
logic [31:0] read_data;
logic write;
logic [2:0] size;
logic [2:0] burst;
logic [2:0] trans;
logic readyout;
logic resp;

`define MMU_DRIVE_SIGNAL(DRIVER) (current_driver == (DRIVER) && waiters[(DRIVER) - 1])

assign addr = `MMU_DRIVE_SIGNAL(2'b01) ? D1_ADDR :
	(`MMU_DRIVE_SIGNAL(2'b10) ? D2_ADDR : 32'd0);
assign write_data = (`MMU_DRIVE_SIGNAL(2'b01)) ? D1_WRITE_DATA :
	(`MMU_DRIVE_SIGNAL(2'b10) ? D2_WRITE_DATA : 32'd0);

assign D1_READ_DATA = `MMU_DRIVE_SIGNAL(2'b01) ? read_data : D1_READ_DATA;
assign D2_READ_DATA = `MMU_DRIVE_SIGNAL(2'b10) ? read_data : D2_READ_DATA;

assign write = `MMU_DRIVE_SIGNAL(2'b01) ? D1_WRITE :
	(`MMU_DRIVE_SIGNAL(2'b10) ? D2_WRITE : 1'd0);
assign size = `MMU_DRIVE_SIGNAL(2'b01) ? D1_SIZE :
	(`MMU_DRIVE_SIGNAL(2'b10) ? D2_SIZE : 3'd0);
assign burst = `MMU_DRIVE_SIGNAL(2'b01) ? D1_BURST :
	(`MMU_DRIVE_SIGNAL(2'b10) ? D2_BURST : 3'd0);

assign D1_READYOUT = `MMU_DRIVE_SIGNAL(2'b01) ? readyout : 1'b1;
assign D2_READYOUT = `MMU_DRIVE_SIGNAL(2'b10) ? readyout : 1'b1;

assign D1_RESP = `MMU_DRIVE_SIGNAL(2'b01) ? resp : 1'b0;
assign D2_RESP = `MMU_DRIVE_SIGNAL(2'b10) ? resp : 1'b0;

assign selx = addr < 32'h100;
assign seldef = addr > 32'h100;

assign waiters = (D1_CLAIM << 0) | (D2_CLAIM << 1);

always_comb begin
	if(!RSTN) begin
		if(readyout && !resp) begin
			trans = (!waiters) ? TRANSFER_IDLE : TRANSFER_NONSEQ;
		end else if(!readyout && !resp) begin
			trans = (!waiters) ? TRANSFER_IDLE : TRANSFER_SEQ;
		end else begin
			trans = TRANSFER_IDLE;
		end 
	end else begin
		trans = TRANSFER_IDLE;
	end
end

always @(posedge CLK) begin
	if(!RSTN && readyout && !resp) begin
		for(integer i = DRIVER_CNT - 1; i >= 0; i--) begin
			if(waiters[i]) begin
				current_driver <= i + 1;
			end
		end

		if(!waiters) begin
			current_driver <= 2'b0;
		end
	end
end

mmu_unit unit (
	.CLK(CLK), .RSTN(RSTN), .SELX(selx), .ADDR(addr), .WRITE_DATA(write_data),
	.READ_DATA(read_data), .WRITE(write), .SIZE(size), .BURST(burst),
	.TRANS(trans), .READYOUT(readyout), .RESP(resp)
);

endmodule
