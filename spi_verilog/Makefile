synth:
	f4pga -vvv build -f flow.json
	f4pga -vvv build -f flow.json -t bitstream_openocd

sim:
	iverilog -s tpm_tb -o tpm.o tpm.tb.v tpm.v -I ../external/verilog-tpm-fifo-registers
	vvp tpm.o
