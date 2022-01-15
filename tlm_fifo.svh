`include "uvm_macros.svh"
import uvm_pkg::*;
`timescale 1ns/1ns
module tb;
    initial begin
        run_test("Top_Level");
    end
endmodule

class Packet extends uvm_object;
    rand bit [7:0] addr;
    rand bit [7:0] data;
    `uvm_object_utils_begin(Packet)
        `uvm_field_int(addr,UVM_ALL_ON)
        `uvm_field_int(data,UVM_ALL_ON)
    `uvm_object_utils_end
    function new(string name = "Packet");
        super.new(name);
    endfunction //new()
endclass //Packet extends uvm_object

class Sender extends uvm_component;
    `uvm_component_utils(Sender)
    function new (string name = "Sender", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    uvm_blocking_put_port #(Packet) sender_port;
    int ntimes;

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        sender_port = new("sender_port",this);
    endfunction

    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        repeat(ntimes) begin
            Packet pkt = Packet::type_id::create("pkt");
            assert(pkt.randomize());
            #50
            `uvm_info(get_type_name(),"'put' out a pkt",UVM_MEDIUM)
            pkt.print(uvm_default_line_printer);
            sender_port.put(pkt);
        end
        phase.drop_objection(this);        
    endtask
endclass

class Getter extends uvm_component;
    `uvm_component_utils(Getter)

    function new(string name="Getter",uvm_component parent=null);
        super.new(name,parent);
    endfunction //new()

    uvm_blocking_get_port #(Packet) getter_port;
    int ntimes;


    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        getter_port = new("getter_port",this);
    endfunction

    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        repeat(ntimes) begin
            Packet pkt;
            #100;
            getter_port.get(pkt);
            `uvm_info(get_type_name(),"'get' from Comp_A",UVM_MEDIUM)
            pkt.print(uvm_default_line_printer);
        end
        phase.drop_objection(this);
    endtask
endclass //Getter extends uvm_component

class Top_Level extends uvm_component;
    `uvm_component_utils(Top_Level)
    function new(string name = "Top_Level", uvm_component parent = null);
        super.new(name,parent);
    endfunction //new()
    
    uvm_tlm_fifo #(Packet) tlm_fifo_ports;
    Sender sender;
    Getter getter;
    int ntimes;

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        tlm_fifo_ports = new("tlm_fifo_ports",this,2); // 3rd arg is the FIFO's depth
        sender = Sender::type_id::create("sender",this);
        getter = Getter::type_id::create("getter",this);
        std::randomize(ntimes) with {ntimes inside {[4:10]}; };
        sender.ntimes = ntimes;
        getter.ntimes = ntimes;
    endfunction

    virtual function void connect_phase (uvm_phase phase);
        super.connect_phase(phase);
        sender.sender_port.connect(tlm_fifo_ports.put_export);
        getter.getter_port.connect(tlm_fifo_ports.get_export);
    endfunction

    /*Display FIFO state*/
    virtual task run_phase(uvm_phase phase);
        forever begin
            #10
            if(tlm_fifo_ports.is_full()) begin
                `uvm_info("","FIFO is full",UVM_MEDIUM)
            end
        end
    endtask;

endclass //Top_Level extends uvm_component