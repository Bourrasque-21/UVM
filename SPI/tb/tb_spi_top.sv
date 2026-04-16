`timescale 1ns / 1ps

module tb_spi_top ();

    logic clk, rst, start, v_led;
    // logic cpol, cpha;
    logic [7:0] sw, led;

    top_spi dut (.*);

    always #5 clk = ~clk;
    /*
    task spi_set_mode(logic [1:0] mode);
        {cpol, cpha} = mode;
        @(posedge clk);
    endtask  //spi_set_mode
*/
    task spi_send_data(logic [7:0] data);
        sw = data;
        start = 1'b1;
        @(posedge clk);
        start = 1'b0;
        @(posedge clk);
        wait (v_led);
        @(posedge clk);
    endtask  //spi_send


    initial begin
        clk = 0;
        rst = 1;
        sw  = 8'h0;
        repeat (3) @(posedge clk);
        rst = 0;
        @(posedge clk);
        // clk_div = 4;  // sclk = 10MHz : (100MHz / (10MHz * 2)) - 1
        //miso = 1'b0;
        @(posedge clk);

        // spi_set_mode(0);
        spi_send_data(8'haa);

        // spi_set_mode(1);
        spi_send_data(8'h55);

        // spi_set_mode(2);
        spi_send_data(8'haa);

        // spi_set_mode(3);
        spi_send_data(8'h55);

        @(posedge clk);
        #20;
        $stop;
    end
endmodule
