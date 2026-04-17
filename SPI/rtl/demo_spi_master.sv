`timescale 1ns / 1ps

module demo_spi_master (

    input  logic       clk,
    input  logic       rst,
    input  logic       start,
    input  logic [7:0] sw,
    // output logic [7:0] led,
    // output logic       v_led
    output logic       w_sclk,
    output logic       w_mosi,
    output logic       w_cs
);

    // logic w_sclk, w_mosi, w_cs;

    spi_master U_SPI_MASTER (
        .clk(clk),
        .rst(rst),

        // Control
        .start  (start),
        .tx_data(sw),
        .clk_div(8'h49),

        .rx_data(),
        .busy   (),
        .done   (),

        .cpol(1'b0),
        .cpha(1'b0),
        // SPI pins
        .sclk(w_sclk),
        .mosi(w_mosi),
        .miso(),
        .cs_n(w_cs)
    );
endmodule
