// Credit: Adapted from http://hamsterworks.co.nz/mediawiki/index.php/TinyTx or https://electronics.stackexchange.com/questions/342921/uart-hdl-question

module TxUART(clk, reset, baud_clk, enable, i_data, o_busy, serial_out
`ifdef FORMAL
	, shift_reg
`endif
);

parameter INPUT_DATA_WIDTH = 8;
parameter PARITY_ENABLED = 1;

input clk, reset, baud_clk, enable;
input[(INPUT_DATA_WIDTH+PARITY_ENABLED-1):0] i_data;  // {parity_bit , data}
output reg o_busy;      // busy signal for data source that Tx cannot accept data 
output reg serial_out;  // serialized data

`ifdef FORMAL
	output [(INPUT_DATA_WIDTH+PARITY_ENABLED+1):0] shift_reg;
`endif

reg [(INPUT_DATA_WIDTH+PARITY_ENABLED+1):0] shift_reg;  // PISO shift reg, start+data+parity+stop

initial 
begin
    o_busy = 0;
    serial_out = 1;
    shift_reg = ~0;
end

always @(posedge clk)   
begin
    if (reset) begin
        shift_reg <= ~0;  // set all bits to 1
    end

    else begin
        if (enable & !o_busy) begin
            shift_reg <= {1'b1, i_data, 1'b0};   // transmit LSB first: 1 = stop bit, 0 = start bit 
        end

        if (baud_clk) begin
            if (o_busy) begin
                shift_reg <= {1'b0, shift_reg[(INPUT_DATA_WIDTH+PARITY_ENABLED+1):1]};  // puts 0 for stop bit detection, see o_busy signal
            end
        end
    end
end 

always @(posedge clk) 
begin
    if(reset) begin 
    	serial_out <= 1;
    end

    else begin
        if (baud_clk) begin
            if (o_busy && (shift_reg != 0)) begin
	            serial_out <= shift_reg[0]; 
            end	    
        end        
    end
end

always @(posedge clk) 
begin
    if(reset) begin 
    	o_busy <= 0;
    end

	else if(enable && !o_busy) begin
		o_busy <= 1; // (Tx is about to transmit)
	end

    else if(baud_clk) begin
		o_busy <= ((shift_reg != 0) && !(&shift_reg));   // if not reset, ((Tx is busy transmitting when there is pending stop bit) AND (Tx does not just get reset))
    end
end


`ifdef FORMAL

reg first_clock_passed;
initial first_clock_passed = 0;

always @(posedge clk)
begin
	first_clock_passed <= 1;
end

always @(posedge clk) 
begin
	if(first_clock_passed && ($past(first_clock_passed) == 0)) begin    // for induction check purpose
		assert($past(o_busy) == 0);  // initially not busy
		assert(&($past(shift_reg)) == 1);  // initially all ones, transmitting ones
	end
end

always @(posedge clk) 
begin
	if(first_clock_passed) begin
		if($past(reset)) assert(o_busy == 0);

		else if($past(enable) && !$past(o_busy)) assert(o_busy);

		else if($past(baud_clk)) assert(o_busy == (($past(shift_reg) != 0) && !(&$past(shift_reg))));
	end
end
	
always @(posedge clk)   
begin
	if(first_clock_passed) begin
		if ($past(reset)) begin
		    assert(shift_reg == ~0);  // set all bits to 1
		end

		else begin
		    if ($past(enable) & !$past((o_busy))) begin
		        assert(shift_reg == {1'b1, $past(i_data), 1'b0});   // transmit LSB first: 1 = stop bit, 0 = start bit 
		    end

		    if ($past(baud_clk)) begin
		        if ($past(o_busy)) begin
		            assert(shift_reg == {1'b0, $past(shift_reg[(INPUT_DATA_WIDTH+PARITY_ENABLED+1):1])});  // puts 0 for stop bit detection, see o_busy signal
		        end
		    end
		end
	end
end 	

`endif

endmodule

