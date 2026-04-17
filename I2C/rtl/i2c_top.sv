`timescale 1ns / 1ps


module I2C_TOP (
    input logic clk,
    input logic rst,
    input logic [7:0] sw,
    output logic [7:0] led,
    output logic scl,
    inout  wire  sda
);

    // State machine for one I2C write transaction.
    typedef enum logic [3:0] {
        IDLE,
        START_REQ,
        START_WAIT,
        ADDR_REQ,
        ADDR_WAIT,
        WRITE_REQ,
        WRITE_WAIT,
        STOP_REQ,
        STOP_WAIT
    } i2c_state_e;
    i2c_state_e state;

    // 7-bit slave address + write bit.
    localparam logic [7:0] SLA_W = {7'h5, 1'b0};
    logic [7:0] master_tx_data, master_rx_data;
    logic [7:0] sw_sync1, sw_sync2, sw_prev;
    logic [7:0] write_data;
    logic cmd_start, cmd_write, cmd_read, cmd_stop, ack_in, done, ack_out, busy;
    logic transfer_ok;

    assign ack_in = 1'b1; // NACK for master read (not used in this write-only FSM)





    I2C_Master U_I2C_MASTER (
        .clk      (clk),
        .rst      (rst),
        .cmd_start(cmd_start),
        .cmd_write(cmd_write),
        .cmd_read (cmd_read),
        .cmd_stop (cmd_stop),
        .tx_data  (master_tx_data),
        .ack_in   (ack_in),
        .rx_data  (master_rx_data),
        .done     (done),
        .ack_out  (ack_out),
        .busy     (busy),
        .scl      (scl),
        .sda      (sda)
    );


    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            sw_sync1 <= 8'h00;
            sw_sync2 <= 8'h00;
        end else begin
            sw_sync1 <= sw;
            sw_sync2 <= sw_sync1;
        end
    end

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            state          <= IDLE;
            led            <= 8'h0;
            cmd_start      <= 1'b0;
            cmd_write      <= 1'b0;
            cmd_read       <= 1'b0;
            cmd_stop       <= 1'b0;
            master_tx_data <= 8'h0;
            write_data     <= 8'h0;
            sw_prev        <= 8'h0;
            transfer_ok    <= 1'b0;
        end else begin
            cmd_start <= 1'b0;
            cmd_write <= 1'b0;
            cmd_read  <= 1'b0;
            cmd_stop  <= 1'b0;
            case (state)
                IDLE: begin
                    if (sw_sync2 != sw_prev) begin
                        sw_prev        <= sw_sync2;
                        write_data     <= sw_sync2;
                        master_tx_data <= sw_sync2;
                        transfer_ok    <= 1'b0;
                        state          <= START_REQ;
                    end
                end

                START_REQ: begin
                    cmd_start <= 1'b1;
                    state     <= START_WAIT;
                end

                START_WAIT: begin
                    if (done) begin
                        state <= ADDR_REQ;
                    end
                end

                ADDR_REQ: begin
                    cmd_write      <= 1'b1;
                    master_tx_data <= SLA_W;
                    state          <= ADDR_WAIT;
                end

                ADDR_WAIT: begin
                    if (done) begin
                        if (!ack_out) begin
                            state <= WRITE_REQ;
                        end else begin
                            state <= STOP_REQ;
                        end
                    end
                end

                WRITE_REQ: begin
                    cmd_write      <= 1'b1;
                    master_tx_data <= write_data;
                    state          <= WRITE_WAIT;
                end

                WRITE_WAIT: begin
                    if (done) begin
                        transfer_ok <= ~ack_out;
                        state <= STOP_REQ;
                    end
                end

                STOP_REQ: begin
                    cmd_stop <= 1'b1;
                    state    <= STOP_WAIT;
                end

                STOP_WAIT: begin
                    if (done) begin
                        if (transfer_ok) begin
                            led <= write_data;
                        end
                        state <= IDLE;
                    end
                end
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end


endmodule
