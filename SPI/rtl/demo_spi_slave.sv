`timescale 1ns / 1ps

module demo_spi_slave (
    input  logic       clk,
    input  logic       rst,
    // input  logic       start,
    // input  logic [7:0] sw,
    input logic w_sclk,
    input logic w_mosi,
    input logic w_cs,

    output logic [7:0] led,
    output logic       v_led

);

    // logic w_sclk, w_mosi, w_cs;

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
