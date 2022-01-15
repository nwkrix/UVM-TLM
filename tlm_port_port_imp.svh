 /*
    |--------------------------------|              |--------------------------------|
    |           ComponentA           |              |                                |
    |   |-------------|              |              |                                |
    |   |  subcompA   []port-------->[]port------->()         ComponentB             |
    |   |-------------|              |              imp                              |
    |                                |              |                                |
    |--------------------------------|              |--------------------------------|
 
 */
`include "uvm_macros.svh"
import uvm_pkg::*;

module top();
    initial begin
        run_test("Env");
    end
endmodule

class Packet extends uvm_object;
    function new(string name = "Packet");
        super.new(name);
    endfunction //new()
    `uvm_object_utils(Packet)
    rand bit[4:0] addr;
    rand bit[7:0] data;
    constraint c_data {1 < data; data < 500;}
endclass //Packet extends uvm_object

class SubComponentA extends uvm_component;
    `uvm_component_utils(SubComponentA)
    uvm_blocking_put_port #(Packet) a_put_port;
    function new(string name = "SubComponentA",
                    uvm_component parent = null);
        super.new(name, parent);        
    endfunction
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        a_put_port = new("a_put_port",this);        
    endfunction
    int ntimes;
    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        repeat(ntimes) begin
            Packet pkt = Packet::type_id::create(
                "pkt",this);
            assert(pkt.randomize());
            a_put_port.put(pkt);
            `uvm_info(get_type_name(),"sends out data", 
                UVM_MEDIUM)
            pkt.print(uvm_default_line_printer);
        end
        phase.drop_objection(this);
    endtask
endclass

class ComponentA extends uvm_component;
    `uvm_component_utils(ComponentA)
    function new(string name = "ComponentA",
                    uvm_component parent = null);
        super.new(name, parent);        
    endfunction
    SubComponentA SubCompA;
    int from_top_mod;
    uvm_blocking_put_port #(Packet) m_put_port;
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        SubCompA = SubComponentA::type_id::create("SubCompA", this);
        m_put_port = new("m_put_port", this);
      SubCompA.ntimes = from_top_mod;
    endfunction
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
         SubCompA.a_put_port.connect(this.m_put_port);   
    endfunction
endclass

class ComponentB extends uvm_component;
    `uvm_component_utils(ComponentB)
    function new(string name = "ComponentB",
            uvm_component parent = null);
        super.new(name, parent);        
    endfunction
    uvm_blocking_put_imp #(Packet,ComponentB) imp_port;
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        imp_port = new("imp_port", this);
    endfunction
    virtual task put(Packet pkt);
        pkt.print(uvm_default_line_printer);
        `uvm_info(get_type_name(),"receives data",
        UVM_MEDIUM)
    endtask
endclass

class Env extends uvm_component;
    `uvm_component_utils(Env)
    function new(string name = "Env", 
            uvm_component parent = null );
        super.new(name, parent);
    endfunction //new()
    ComponentA CompA;
    ComponentB CompB;
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        CompA = ComponentA::type_id::create("CompA",this);
        CompB = ComponentB::type_id::create("CompB",this); 
        CompA.from_top_mod = 4;
    endfunction
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        CompA.m_put_port.connect(CompB.imp_port);
    endfunction
endclass //Env extends uvm_component