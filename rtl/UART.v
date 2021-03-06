module UART(tx_clk, rx_clk, reset_tx, reset_rx, serial_out, enable, i_data, o_busy, serial_in, received_data, data_is_valid, rx_error
`ifdef FORMAL
	, state, baud_clk, shift_reg, serial_in_synced, start_detected, sampling_strobe, data_is_available
`endif
);

parameter INPUT_DATA_WIDTH = 8;
parameter PARITY_ENABLED = 1;

input tx_clk, rx_clk;
input reset_tx, reset_rx; 

// transmitter signals
input enable;
input [(INPUT_DATA_WIDTH-1):0] i_data;
output o_busy;
output serial_out;

`ifdef FORMAL
output baud_clk;
`endif

// receiver signals
input serial_in;
output data_is_valid;
output rx_error;
output [(INPUT_DATA_WIDTH-1):0] received_data;

`ifdef FORMAL
localparam NUMBER_OF_BITS = INPUT_DATA_WIDTH + 3;   // 1 start bit, 8 data bits, 1 parity bit, 1 stop bit
output [($clog2(NUMBER_OF_BITS)-1) : 0] state;
output [(INPUT_DATA_WIDTH+PARITY_ENABLED+1):0] shift_reg;  // Tx internal PISO
output serial_in_synced;
output start_detected;
output sampling_strobe;
output data_is_available;
`endif

// UART transmitter
Tx_top tx (.clk(tx_clk), .reset(reset_tx), .enable(enable), .i_data(i_data), .o_busy(o_busy), .serial_out(serial_out)
`ifdef FORMAL
	, .baud_clk(baud_clk), .shift_reg(shift_reg)
`endif
);

// UART receiver
Rx_top rx (.clk(rx_clk), .reset(reset_rx), .serial_in(serial_in), .received_data(received_data), .rx_error(rx_error), .data_is_valid(data_is_valid)
`ifdef FORMAL
	, .state(state), .serial_in_synced(serial_in_synced), .start_detected(start_detected), .sampling_strobe(sampling_strobe), .data_is_available(data_is_available)
`endif
);

endmodule
