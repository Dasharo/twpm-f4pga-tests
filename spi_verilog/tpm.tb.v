`timescale 1ns/1ps

module tpm_tb ();

reg         clk_en = 0;
wire        clk;
wire        clk_ungated;
reg         cs_n = 1;
reg         mosi = 0;
wire        miso;
reg         reset_n = 1;

wire [15:0] spi2reg_addr;
wire [ 7:0] spi2reg_data;
wire        spi2reg_data_ready;

integer     n_writes = 'd0;

task tpm_write8 (
    input [24:0] addr,
    input [ 8:0] data
);
    reg [31:0] header;
    reg [31:0] r_data;
    reg        r_wait;
    begin
        header = {2'b00, 5'h0, addr};
        r_data = data;
        r_wait = 0;

        cs_n = 0;
        #5;
        repeat (32) @(negedge clk_ungated) begin
            clk_en = 1;
            mosi = header[31];
            header = {header[30:0], 1'b0};
            if (~miso) begin
                $display("ERROR: wait state must be inserted not before last header cycle");
                $finish;
            end
        end

        @(posedge clk) r_wait = ~miso;

        while (r_wait) begin
            @(negedge clk) clk_en = 0;
            mosi = 1;
            #166.64;
            @(negedge clk_ungated) clk_en = 1;

            repeat (7) @(posedge clk) begin
                if (miso) begin
                    $display("ERROR: wait state duration must be multiple of 8 clock cycles");
                    $finish;
                end
            end

            @(posedge clk) r_wait = ~miso;
        end

        repeat (8) @(negedge clk) begin
            mosi = r_data[7];
            r_data = {r_data[6:0], 1'b0};
        end

        repeat (2) @(posedge clk);
        @(negedge clk) clk_en = 0;

        #5 cs_n = 1;

        n_writes = n_writes + 1;
    end
endtask

initial begin
    $dumpfile("tpm.tb.vcd");
    $dumpvars(0, tpm_tb);
    $timeformat(-9, 0, " ns", 10);

    #10 reset_n = 0;
    #10 reset_n = 1;

    #166.64;
    // Change locality
    tpm_write8(24'h0000, 8'h02);
    if (tpm_regs.activeLocality != 0) begin
        $display("ERROR: could not change locality");
        $finish;
    end
    #166.64;
    // Configure interrupts
    tpm_write8(24'h8, 8'h83);

    #166.64;
    $finish;
end

clk_gen clk_generator (
    .en(clk_en),
    .clk(clk),
    .clk_ungated(clk_ungated)
);

tpm tpm_inst (
    .clk(clk),
    .clk_n(~clk),
    .mosi(mosi),
    .miso(miso),
    .cs_n(cs_n),
    .reset_n(reset_n),
    .data_o(spi2reg_data),
    .addr_o(spi2reg_addr),
    .data_wr_o(spi2reg_data_ready)
);

regs_module tpm_regs (
    .clk_i(clk),
    .data_i(spi2reg_data),
    .addr_i(spi2reg_addr),
    .data_wr(spi2reg_data_ready),
    .data_req(1'b0)
);

endmodule

module clk_gen (
    input  wire en,
    output wire clk,
    output wire clk_ungated
);

reg r_clk = 0;

initial begin
    forever #20.83 r_clk = ~r_clk;
end

assign clk = en ? r_clk : 0;
assign clk_ungated = r_clk;

endmodule

`include "../external/verilog-tpm-fifo-registers/regs_module.v"
