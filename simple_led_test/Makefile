all:
	@f4pga -vvv build --flow ./flow.json
	@f4pga -vvv build --flow ./flow.json -t iomux_openocd
	@python3 -m quicklogic_fasm.bitstream_to_openocd build/top.bit build/top.openocd
