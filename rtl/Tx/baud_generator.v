// credit: Adapted from http://zipcpu.com/blog/2017/06/02/generating-timing.html

module baud_generator(clk, baud_clk);     // we are obtaining baud_out = 9600bps = clk/5000 where clk = 48MHz

input clk;
output baud_clk;

reg ck_stb;

`ifdef FORMAL
    parameter CLOCKS_PER_BIT = 8;   // CLOCKS_PER_BIT is similar in concept to clock divide factor
`else
    parameter CLOCKS_PER_BIT = 5000;
`endif

reg[($clog2(CLOCKS_PER_BIT)-1) : 0] cnt;

initial ck_stb = 0;
initial cnt = 0;

always @(posedge clk)
begin
    ck_stb <= (cnt == (CLOCKS_PER_BIT - 1)); 
    cnt <= cnt + 1;
end

assign baud_clk = ck_stb;

`ifdef FORMAL

reg first_clock_passed;

initial first_clock_passed = 0;

always @(posedge clk)
begin
	first_clock_passed <= 1;
end

always @(posedge clk)
begin
	if(first_clock_passed) begin
		assert((baud_clk && $past(baud_clk)) == 0);  // asserts that baud_clk is only single pulse HIGH
	end
end

`endif

endmodule
