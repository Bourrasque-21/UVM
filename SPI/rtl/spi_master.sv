`timescale 1ns / 1ps

module spi_master (
    input logic clk,
    input logic rst,

    // Control
    input logic       start,
    input logic [7:0] tx_data,
    input logic [7:0] clk_div,

    output logic [7:0] rx_data,
    output logic       busy,
    output logic       done,

    // SPI pins
    output logic sclk,
    output logic mosi,
    input  logic miso,
    output logic cs_n
);

    typedef enum logic [1:0] {
        IDLE,
        START,
        DATA,
        STOP
    } spi_state_e;
    spi_state_e state;

    logic [7:0] div_cnt, tx_shift_reg, rx_shift_reg;
    logic [2:0] bit_cnt;
    logic half_tick;  // 1-cycle pulse for each SCLK half-period during DATA
    logic phase;  // 0: sample MISO half, 1: shift/prepare next MOSI half
    logic sclk_r;  // Internal SCLK level

    assign sclk = sclk_r;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            div_cnt   <= 0;
            half_tick <= 1'b0;
        end else begin
            if (state == DATA) begin
                if (div_cnt == clk_div) begin
                    div_cnt   <= 0;
                    half_tick <= 1'b1;
                end else begin
                    div_cnt   <= div_cnt + 1;
                    half_tick <= 1'b0;
                end
            end else begin
                div_cnt   <= 0;
                half_tick <= 0;
            end
        end
    end

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            state        <= IDLE;
            rx_data      <= 8'h0;
            busy         <= 1'b0;
            done         <= 1'b0;
            mosi         <= 1'b1;
            cs_n         <= 1'b1;
            tx_shift_reg <= 8'h0;
            rx_shift_reg <= 8'h0;
            bit_cnt      <= 3'd0;
            phase        <= 1'b0;
            sclk_r       <= 1'b0;
        end else begin
            done <= 1'b0;
            case (state)
                IDLE: begin
                    mosi   <= 1'b1;
                    cs_n   <= 1'b1;
                    sclk_r <= 1'b0;
                    if (start) begin
                        state        <= START;
                        tx_shift_reg <= tx_data;
                        bit_cnt      <= 3'd0;
                        phase        <= 1'b0;
                        busy         <= 1'b1;
                        cs_n         <= 1'b0;
                    end
                end

                START: begin
                    // Drive the first MOSI bit before SCLK starts toggling
                    mosi         <= tx_shift_reg[7];
                    tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                    state        <= DATA;
                end

                DATA: begin
                    if (half_tick) begin
                        // Advance SCLK on each half-period
                        sclk_r <= ~sclk_r;
                        if (phase == 0) begin
                            // Sample MISO
                            rx_shift_reg <= {rx_shift_reg[6:0], miso};
                            phase        <= 1'b1;
                        end else begin
                            // Shift out the next MOSI bit
                            phase <= 1'b0;
                            if (bit_cnt == 3'd7) begin
                                // Finish after the last bit
                                state   <= STOP;
                                rx_data <= rx_shift_reg;
                            end else begin
                                mosi         <= tx_shift_reg[7];
                                tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                                bit_cnt      <= bit_cnt + 1'b1;
                            end
                        end
                    end
                end

                STOP: begin
                    state  <= IDLE;
                    busy   <= 1'b0;
                    done   <= 1'b1;
                    cs_n   <= 1'b1;
                    mosi   <= 1'b1;
                    sclk_r <= 1'b0;
                end

                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
