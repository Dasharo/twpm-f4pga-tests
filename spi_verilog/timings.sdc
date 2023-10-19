create_clock -period 20.83 clk
set_input_delay -max 0 -clock clk [get_ports {mosi}]
set_output_delay -max 0 -clock clk [get_ports {miso}]
