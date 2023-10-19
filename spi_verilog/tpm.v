module tpm (
    input  wire        clk,
    input  wire        clk_n,
    input  wire        mosi,
    output wire        miso,
    input  wire        cs_n,
    input  wire        reset_n,
    output wire [ 7:0] data_o,
    output wire [15:0] addr_o,
    output reg         data_wr_o
);

`define SPI_HEADER_RECV_0  4'b0000
`define SPI_HEADER_RECV_1  4'b0001
`define SPI_HEADER_RECV_2  4'b0010
`define SPI_HEADER_RECV_3  4'b0011
`define SPI_WRITE_WAIT     4'b0100
`define SPI_WRITE          4'b0101
`define SPI_READ_WAIT      4'b0110
`define SPI_READ           4'b0111
`define SPI_WRITE_COMPLETE 4'b1000
`define SPI_READ_COMPLETE  4'b1001
`define SPI_ABORT          4'b1010

wire        cs_or_reset;
reg  [ 2:0] counter;
reg  [ 3:0] current_fsm_state;
reg  [ 3:0] next_fsm_state;
reg  [31:0] tpm_header;
reg         r_miso;
reg         r2_miso;
reg  [ 7:0] temp;
reg         r_data_wr;

assign cs_or_reset = cs_n | ~reset_n;
assign miso = cs_n ? 1'bz : r2_miso;
assign addr_o = tpm_header[15:0];
assign data_o = temp;

always @(posedge clk_n) begin
    // Change MISO on negative edge.
    r2_miso <= r_miso;
    data_wr_o <= r_data_wr;
end

always @* begin : fsm_comb
    next_fsm_state = current_fsm_state;

    r_miso = 1;
    r_data_wr = 0;

    case (current_fsm_state)
        `SPI_HEADER_RECV_0,
        `SPI_HEADER_RECV_1,
        `SPI_HEADER_RECV_2,
        `SPI_HEADER_RECV_3: begin
            if (counter == 0) begin
                if (current_fsm_state == `SPI_HEADER_RECV_3)
                    r_miso = 0;

                if (current_fsm_state == `SPI_HEADER_RECV_3)
                    next_fsm_state = tpm_header[30] ? `SPI_READ_WAIT : `SPI_WRITE_WAIT;
                else
                    next_fsm_state = current_fsm_state + 1;
            end
        end
        `SPI_WRITE_WAIT: begin
            r_miso = 0;
            if (counter == 0) begin
                r_miso = 1;
                next_fsm_state = `SPI_WRITE;
            end
        end
        `SPI_WRITE: begin
            r_miso = 1;
            if (counter == 0) begin
                next_fsm_state = `SPI_WRITE_COMPLETE;
                // We lack logic for checking remaining transfer size (assume transfer size is 1 byte).
            end
        end
        `SPI_WRITE_COMPLETE: begin
            r_miso = 1;
            next_fsm_state = `SPI_ABORT;
            r_data_wr = 1;
            $display("write complete");
        end
    endcase
end

always @(posedge clk or posedge cs_n) begin : fsm_seq
    if (~cs_n) begin
        current_fsm_state <= next_fsm_state;

        case (current_fsm_state)
            `SPI_HEADER_RECV_0,
            `SPI_HEADER_RECV_1,
            `SPI_HEADER_RECV_2,
            `SPI_HEADER_RECV_3: begin
                tpm_header <= {tpm_header[30:0], mosi};
                counter <= counter - 1;
            end
            `SPI_WRITE_WAIT: counter <= counter - 1;
            `SPI_WRITE: begin
                temp <= {temp[7:0], mosi};
                counter <= counter - 1;
            end
        endcase
    end else begin
        current_fsm_state <= `SPI_HEADER_RECV_0;
        counter <= 7;
    end
end

endmodule
