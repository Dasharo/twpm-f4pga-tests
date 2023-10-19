module top (
    input  wire        clk,
    input  wire        mosi,
    output wire        miso,
    input  wire        cs_n,
    input  wire        reset_n,
    output wire [ 3:0] led
);

wire [ 7:0] spi2reg_data;
wire [15:0] spi2reg_addr;
wire        spi2reg_data_ready;
wire        t_miso;

tpm tpm_inst (
    .clk(clk),
    .clk_n(~clk),
    .mosi(mosi),
    .miso(t_miso),
    .cs_n(cs_n),
    .reset_n(reset_n),
    .data_o(spi2reg_data),
    .addr_o(spi2reg_addr),
    .data_wr_o(spi2reg_data_ready)
);

assign miso = t_miso == 1'bz ? 0 : t_miso;

regs_module tpm_regs (
    .clk_i(clk),
    .data_i(spi2reg_data),
    .addr_i(spi2reg_addr),
    .data_wr(spi2reg_data_ready),
    .data_req(1'b0)
);

assign led[0] = tpm_regs.activeLocality == 0;
assign led[1] = tpm_regs.dataAvailIntEnable && tpm_regs.stsValidIntEnable && commandReadyEnable;

endmodule
