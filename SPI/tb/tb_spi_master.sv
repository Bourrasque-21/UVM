`timescale 1ns / 1ps

module tb_spi_master ();
    logic       clk;
    logic       rst;
    logic       start;
    logic [7:0] tx_data;
    logic [7:0] clk_div;

    logic [7:0] rx_data;
    logic       done;
    logic       busy;

    logic       sclk;
    logic       mosi;
    logic       miso;
    logic       cs_n;

    spi_master dut (.*);

    always #5 clk = ~clk;

    assign miso = mosi;

    initial begin
        clk = 0;
        rst = 1;
        start = 0;
        clk_div = 0;
        repeat (3) @(posedge clk);
        rst = 0;

        @(posedge clk);
        clk_div = 4;
        // miso = 1'b0;
        @(posedge clk);
        tx_data = 8'haa;
        start   = 1'b1;
        @(posedge clk);
        start = 1'b0;
        @(posedge clk);
        wait (done);
        @(posedge clk);

        #20;
        $stop;
    end
endmodule
