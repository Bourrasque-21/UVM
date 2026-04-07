`include "uvm_macros.svh"
import uvm_pkg::*;


interface ram_if (
    input logic clk
);
    logic        we;
    logic [ 7:0] addr;
    logic [15:0] wdata;
    logic [15:0] rdata;
endinterface  //ram_if


class ram_seq_item extends uvm_sequence_item;
    rand bit        we;
    rand bit [ 7:0] addr;
    rand bit [15:0] wdata;
    logic    [15:0] rdata;

    constraint c_we {
        we dist {
            1 := 1,
            0 := 0
        };
    }
    constraint c_addr {addr inside {[0 : 9]};}
    // constraint c_wdata

    `uvm_object_utils_begin(ram_seq_item)
        `uvm_field_int(we, UVM_ALL_ON)
        `uvm_field_int(addr, UVM_ALL_ON)
        `uvm_field_int(wdata, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "ram_seq_item");
        super.new(name);
    endfunction  //new()
endclass  //ram_seq_item extends uvm_sequence_item


class ram_seq extends uvm_sequence #(ram_seq_item);
    `uvm_object_utils(ram_seq)

    function new(string name = "ram_seq");
        super.new(name);
    endfunction  //new()

    virtual task body();
        ram_seq_item item;
        repeat (100) begin
            item = ram_seq_item::type_id::create("item");
            start_item(item);
            assert (item.randomize());
            finish_item(item);
        end
    endtask  //body
endclass  //ram_seq extends uvm_sequence


class ram_driver extends uvm_driver #(ram_seq_item);
    `uvm_component_utils(ram_driver)

    virtual ram_if r_if;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction  //new()

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual ram_if)::get(this, "", "r_if", r_if))
            `uvm_fatal(get_type_name(), "cannnot found r_if!")
        `uvm_info(get_type_name(), "build phase executed", UVM_HIGH);
    endfunction

    virtual task run_phase(uvm_phase phase);
        ram_seq_item item;
        forever begin
            seq_item_port.get_next_item(item);
            @(negedge r_if.clk);
            r_if.we    <= item.we;
            r_if.addr  <= item.addr;
            r_if.wdata <= item.wdata;
            seq_item_port.item_done();
        end
    endtask  //run_phase
endclass  //ram_driver extends uvm_driver


class ram_monitor extends uvm_monitor;
    `uvm_component_utils(ram_monitor)

    uvm_analysis_port #(ram_seq_item) send;

    virtual ram_if r_if;
    ram_seq_item r_seq_item;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        send = new("WRITE", this);
    endfunction  //new()

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual ram_if)::get(this, "", "r_if", r_if))
            `uvm_fatal(get_type_name(), "cannot found r_if!")
        `uvm_info(get_type_name(), "build phase executed", UVM_HIGH);
    endfunction

    virtual task run_phase(uvm_phase phase);
        forever begin
            @(posedge r_if.clk);
            #1;
            r_seq_item = ram_seq_item::type_id::create("item", this);
            r_seq_item.we    = r_if.we;
            r_seq_item.addr  = r_if.addr;
            r_seq_item.wdata = r_if.wdata;
            r_seq_item.rdata = r_if.rdata;
            `uvm_info(get_type_name(), "sampled RAM transaction", UVM_HIGH);
            send.write(r_seq_item);
        end
    endtask  //run_phase
endclass  //ram_monitor extends uvm_monitor


class ram_scb extends uvm_scoreboard;
    `uvm_component_utils(ram_scb)

    uvm_analysis_imp #(ram_seq_item, ram_scb) recv;

    logic [15:0] ref_mem[0:255];
    logic [15:0] exp_rdata;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        recv = new("READ", this);
    endfunction  //new()

    virtual function void write(ram_seq_item data);
        exp_rdata = ref_mem[data.addr];
        if (data.rdata === exp_rdata) begin
            `uvm_info(
                get_type_name(),
                $sformatf(
                    "[PASS] we = %0b, addr: %0h, wdata: %0h, exp_rdata: %0h == rdata: %0h",
                    data.we, data.addr, data.wdata, exp_rdata, data.rdata),
                UVM_LOW)
        end else begin
            `uvm_error(get_type_name(), $sformatf(
                       "[FAIL] we = %0b, addr: %0h, wdata: %0h, exp_rdata: %0h != rdata: %0h",
                       data.we,
                       data.addr,
                       data.wdata,
                       exp_rdata,
                       data.rdata
                       ))
        end
        if (data.we) begin
            ref_mem[data.addr] = data.wdata;
        end
    endfunction
endclass  //ram_scb extends uvm_scoreboard


class ram_agent extends uvm_agent;
    `uvm_component_utils(ram_agent)

    uvm_sequencer #(ram_seq_item) sqr;
    ram_driver drv;
    ram_monitor mon;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction  //new()

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        sqr = uvm_sequencer#(ram_seq_item)::type_id::create("sqr", this);
        drv = ram_driver::type_id::create("drv", this);
        mon = ram_monitor::type_id::create("mon", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        drv.seq_item_port.connect(sqr.seq_item_export);
    endfunction
endclass  //ram_agent extends uvm_agent


class ram_env extends uvm_env;
    `uvm_component_utils(ram_env)

    ram_agent agt;
    ram_scb   scb;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction  //new()

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agt = ram_agent::type_id::create("agt", this);
        scb = ram_scb::type_id::create("scb", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agt.mon.send.connect(scb.recv);
    endfunction
endclass  //ram_env extends uvm_env


class ram_test extends uvm_test;
    `uvm_component_utils(ram_test)

    ram_env env;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction  //new()

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = ram_env::type_id::create("env", this);
    endfunction

    virtual task run_phase(uvm_phase phase);
        ram_seq seq;
        phase.raise_objection(this);
        seq = ram_seq::type_id::create("seq");
        seq.start(env.agt.sqr);
        phase.drop_objection(this);
    endtask

    virtual function void report_phase(uvm_phase phase);
        uvm_report_server svr = uvm_report_server::get_server();
        if (svr.get_severity_count(UVM_ERROR) == 0)
            `uvm_info(get_type_name(), "===== TEST PASS! =====", UVM_LOW)
        else `uvm_info(get_type_name(), "===== TEST FAIL! =====", UVM_LOW)
    endfunction
endclass  //ram_test extends uvm_test


module tb_ram ();
    logic clk;

    always #5 clk = ~clk;

    ram_if r_if (clk);

    RAM dut (
        .clk  (clk),
        .we   (r_if.we),
        .addr (r_if.addr),
        .wdata(r_if.wdata),
        .rdata(r_if.rdata)
    );

    initial begin
        clk = 0;
        uvm_config_db#(virtual ram_if)::set(null, "*", "r_if", r_if);
        run_test("ram_test");
    end
endmodule
