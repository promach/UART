module sampling_strobe_generator(clk, reset, start_detected, sampling_strobe);  // produces sampling control signal for the incoming Rx

input clk, reset, start_detected;
output reg sampling_strobe;

`ifdef FORMAL
    parameter CLOCKS_PER_BIT = 8; // number of system clock in one UART bit, or equivalently 1/600kHz divided by 1/48MHz
`else
    parameter CLOCKS_PER_BIT = 5000; // number of system clock in one UART bit, or equivalently 1/9600Hz divided by 1/48MHz
`endif

reg [($clog2(CLOCKS_PER_BIT)-1) : 0] counter;

initial begin
    sampling_strobe = 0;
    counter = 0;
end

always @(posedge clk)
begin
	if(reset) begin
		counter <= 0;
	end

	else begin
		if(start_detected)
			counter <= (CLOCKS_PER_BIT >> 1) + 1;  // when start bit is detected, we only need to advance half an UART bit to sample at the middle of the UART start bit
			
		else begin
			if(counter == (CLOCKS_PER_BIT-1)) begin
				counter <= 0;
			end
		
			else begin
	   			counter <= counter + 1;  // to count number of system clock that had passed since midpoint-sampling of previous UART bit
	   		end
	   	end
	end
end

always @(posedge clk)
begin
	if(reset) begin
		sampling_strobe <= 0;
	end
	
	else begin
		if((counter == (CLOCKS_PER_BIT-1)) && (!start_detected))
			sampling_strobe <= 1;
		else
			sampling_strobe <= 0;
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
	assert(counter < CLOCKS_PER_BIT); // for induction
	
	if(first_clock_passed) begin

		assert((sampling_strobe & ($past(sampling_strobe))) == 0);  // sampling_strobe is only single pulse '1'
		
		if($past(reset)) begin
			assert(counter == 0);	
		end
		
		else begin
			if(!($past(start_detected))) begin
				
				assert((counter - $past(counter)) == 1'b1);  // to keep the increasing trend for	 induction test purpose such that sampling_strobe occurs at the correct period interval 
			end
		
			else begin
				assert(counter == (CLOCKS_PER_BIT >> 1) + 1);
			end
		end
	
	
		if($past(reset)) begin
			assert(!sampling_strobe);
		end
		
		else begin
			if((counter == 0) && ($past(counter) == (CLOCKS_PER_BIT-1))) begin
				assert(sampling_strobe); // sampling_strobe is HIGH at the right cycle, for induction check purpose
			end
			
			else begin
				assert(!sampling_strobe);
			end
		end
	end
end

`endif

endmodule
