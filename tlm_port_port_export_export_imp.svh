 /*                                            |-----------------------------------------|
                                               |                ComponentB               |
    |--------------------------------|         |     |--------------------------------|  |
    |           ComponentA           |         |     |          subCompB1             |  |
    |   |-------------|              |         |     |           |------------------| |  |
    |   |  subcompA   []port-------->[]port--->()--->()Export--->()imp subcompB2    | |  |
    |   |-------------|              |       Export  |           |------------------| |  |
    |                                |         |     |                                |  |
    |--------------------------------|         |     |--------------------------------|  |   
                                               |                                         |
                                               |-----------------------------------------|
 */
`include "uvm_macros.svh"
import uvm_pkg::*;
module top;
    initial begin
        run_test("Env");
    end
endmodule
class Packet extends uvm_object;
    rand bit[7:0] addr;
    rand bit[7:0] data;
    //constraint c_const {addr > 10;}
    `uvm_object_utils(Packet)
    function new(string name = "Packet");
        super.new(name);
    endfunction
endclass

class SubCompA extends uvm_component;
    `uvm_component_utils(SubCompA)
    function new(string name = "SubCompA", uvm_component parent = null);
        super.new(name, parent);
    endfunction //new()
    uvm_blocking_put_port #(Packet) m_port_subc_a;
    int ntimes;

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        m_port_subc_a = new("m_port_subc_a",this);
    endfunction

    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        repeat(ntimes) begin
            Packet pkt = Packet::type_id::create("pkt");
            assert(pkt.randomize());
            `uvm_info(get_type_name(),"sent data",UVM_MEDIUM)
            pkt.print(uvm_default_line_printer);
            m_port_subc_a.put(pkt);
        end
        phase.drop_objection(this);
    endtask
endclass //SubCompA extends superClass

class ComponentA extends uvm_component;
    `uvm_component_utils(ComponentA)
    function new(string name = "ComponentA", uvm_component parent = null);
        super.new(name, parent);
    endfunction //new()

    SubCompA subCompA;
    uvm_blocking_put_port #(Packet) m_port_c_a;
    int iter_epochs;
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        subCompA = SubCompA::type_id::create("subCompA",this);
        m_port_c_a = new("m_port_c_a",this);
        subCompA.ntimes = iter_epochs;
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        subCompA.m_port_subc_a.connect(this.m_port_c_a);
    endfunction
endclass //ComponentA extends uvm_component

class SubCompB2 extends uvm_component;
    `uvm_component_utils(SubCompB2)

    function new (string name = "SubCompB2", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    uvm_blocking_put_imp #(Packet,SubCompB2) m_imp;

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        m_imp = new("m_imp",this);
    endfunction

    virtual task put(Packet pkt);
        `uvm_info(get_type_name(),"receives data",UVM_MEDIUM)
        pkt.print(uvm_default_line_printer);
    endtask
endclass // SubCompB2 

class SubCompB1 extends uvm_component;
   `uvm_component_utils(SubCompB1)

    function new (string name = "SubCompB1", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    SubCompB2 subCompB2;
    uvm_blocking_put_export #(Packet) m_export_scb1;

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        m_export_scb1 = new("m_export_scb1",this);
        subCompB2 = SubCompB2::type_id::create("subCompB2",this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        this.m_export_scb1.connect(subCompB2.m_imp);
        //subCompB2.m_imp.connect(this.m_export_scb1);
    endfunction
endclass //SubCompB1 extends superClass

class ComponentB extends uvm_component;
    `uvm_component_utils(ComponentB)
    function new(string name = "ComponentB", uvm_component parent = null);
        super.new(name, parent);
    endfunction //new()

    SubCompB1 subCompB1;
    uvm_blocking_put_export #(Packet) m_export_scb;

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        subCompB1 = SubCompB1::type_id::create("subCompB1",this);
        m_export_scb = new("m_export_scb",this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        subCompB1.m_export_scb1.connect(this.m_export_scb);
    endfunction    
endclass //ComponentB extends uvm_componestring name = ""nt

class Env extends uvm_component;
    `uvm_component_utils(Env)
    function new (string name = "Env", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    ComponentA compA;
    ComponentB compB;

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        compA = ComponentA::type_id::create("compA",this);
        compB = ComponentB::type_id::create("compB",this);
        compA.iter_epochs = 2;
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        compA.m_port_c_a.connect(compB.m_export_scb);
    endfunction
endclass