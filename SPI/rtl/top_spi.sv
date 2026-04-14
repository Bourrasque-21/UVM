`timescale 1ns / 1ps

module top_spi (
    input  logic       clk,
    input  logic       rst,
    input  logic       start,
    input  logic [7:0] sw,
    output logic [7:0] led,
    output logic       v_led

);

    logic w_sclk, w_mosi, w_cs;

    spi_master U_SPI_MASTER (
        .clk(clk),
        .rst(rst),

        // Control
        .start  (start),
        .tx_data(sw),
        .clk_div(8'h4),

        .rx_data(),
        .busy   (),
        .done   (),

        // SPI pins
        .sclk(w_sclk),
        .mosi(w_mosi),
        .miso(),
        .cs_n(w_cs)
    );

    spi_slave U_SPI_SLAVE (
        .clk(clk),
        .rst(rst),

        .rx_data(led),
        .valid  (v_led),

        .sclk(w_sclk),
        .mosi(w_mosi),
        .cs_n(w_cs)
    );

endmodule
