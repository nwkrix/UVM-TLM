/*
    |-----------|                    |------------|
    | componetA |[port]----->(imp)| ComponentB |
    |-----------|                    |------------|
    Randomizes pkt                    implement the put() method
    port.put(pkt)
*/

`include "uvm_macros.svh"
import uvm_pkg::*;

/* Top module to initiate the test bench */
module top;
  initial begin
    run_test("MyTest");
  end
endmodule

class Packet extends uvm_object; // Packet class
  `uvm_object_utils(Packet)
  rand bit[7:0] addr;
  rand bit[7:0] data;
  function new(string n = "Packet");
    super.new(n);
  endfunction
endclass
class ComponentA extends uvm_component; // Sender class
  `uvm_component_utils(ComponentA)
  function new(string n = "ComponentA", uvm_component p = null);
    super.new(n,p);
  endfunction
  uvm_blocking_put_port #(Packet) m_put_port;
  int ntimes;
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    m_put_port = new("m_put_port",this);
  endfunction
  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    repeat(ntimes) begin
      Packet pkt = Packet::type_id::create("pkt",this);
      assert(pkt.randomize());
      pkt.print(uvm_default_line_printer);
      `uvm_info(get_type_name(),"Sends to Adjacent Component",UVM_LOW)
      m_put_port.put(pkt);
    end
    phase.drop_objection(this);
  endtask
endclass
class ComponentB extends uvm_component; // Receiver class
  `uvm_component_utils(ComponentB)
  function new(string n = "ComponentB", uvm_component p = null);
    super.new(n,p);
  endfunction
  uvm_blocking_put_imp #(Packet,ComponentB) m_put_imp;
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    m_put_imp = new("m_put_imp",this);
  endfunction
  virtual task put(Packet pkt);
    pkt.print(uvm_default_line_printer);
    `uvm_info(get_type_name(),"receives data",UVM_LOW)
  endtask
endclass
// top level class to create and connect the sender & receiver classes
class MyTest extends uvm_component; 
  ComponentA CompA;
  ComponentB CompB;
  `uvm_component_utils(MyTest)
  function new(string n = "MyTest", uvm_component p = null);
    super.new(n,p);
  endfunction
  virtual function void build_phase(uvm_phase phase);
    CompA = ComponentA::type_id::create("CompA",this);
    CompB = ComponentB::type_id::create("CompB",this); 
    CompA.ntimes = 10;
  endfunction
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    CompA.m_put_port.connect(CompB.m_put_imp);
  endfunction
endclass