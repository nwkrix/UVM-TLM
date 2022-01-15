 /*
    |--------------------------------|              |--------------------------------|
    |           ComponentA           |              |          ComponentB            |
    |   |-------------|              |              |           |------------------| |
    |   |  subcompA   []port-------->[]port------->()Export---->()imp SubcompB     | |
    |   |-------------|              |              |           |------------------| |
    |                                |              |                                |
    |--------------------------------|              |--------------------------------|
 
 */
`include "uvm_macros.svh"
import uvm_pkg::*;
module tb;
  initial begin
    run_test("my_test");
  end
endmodule
/* A class declaring random data (or packets) for transmission */
class Packet extends uvm_object;
  rand bit[7:0] addr;
  rand bit[7:0] data;
  `uvm_object_utils(Packet)
  function new(string name = "Packet");
    super.new(name);
  endfunction
endclass // end of Packet class

/* A sub component class contained in a top class ComponentA. This class is the source of the 
   of the packet. It contains (or builds) the uvm_blocking_put_port #(PacketClass) portName
*/
class SubComponentA extends uvm_component;
  `uvm_component_utils(SubComponentA)
  function new(string name = "SubComponentA", uvm_component parent = null);
    super.new(name,parent);
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
        Packet pkt = Packet::type_id::create("pkt");
        assert(pkt.randomize());
        pkt.print(uvm_default_line_printer);
        `uvm_info(get_type_name(),"sends data to higher Component A",UVM_MEDIUM)
        m_put_port.put(pkt);
    end
    phase.drop_objection(this);
  endtask
endclass // end of SubComponentA class

/* This class is one level higher in hierachy to the previous SubComponentA class.
    Hence, it builds the SubComponentA class and any other attributes (e.g. ntimes) in SubComponentA
    that needs to be passed down from the current class  */
class ComponentA extends uvm_component;
  `uvm_component_utils(ComponentA)
  SubComponentA SubCompA;
  int ntimes_from_top_cls;
  uvm_blocking_put_port #(Packet) m_put_port;
  function new(string name = "ComponentA", uvm_component parent = null);
    super.new(name,parent);
  endfunction
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    SubCompA = SubComponentA::type_id::create("SubCompA",this); 
    SubCompA.ntimes = ntimes_from_top_cls;  
    m_put_port = new("m_put_port",this);
  endfunction
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    // connecting SubComponentA's port to the port of the current class
    SubCompA.m_put_port.connect(this.m_put_port); 
  endfunction
endclass // end of ComponentA class

/* A sub component class contained in a top class ComponentB. This class is the destination of the 
   of the packet. It contains (or builds) the uvm_blocking_put_imp #(PacketClass, CurrentClass) portName.
   It implements the 'put' method which was called in the SubComponentA class 
   */
class SubComponentB extends uvm_component;
  `uvm_component_utils(SubComponentB)
  uvm_blocking_put_imp #(Packet,SubComponentB) m_put_imp;

  function new (string name = "SubComponentB", uvm_component parent = null);
    super.new(name,parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    m_put_imp = new("m_put_imp",this); // creating the uvm_blocking_put_imp port
  endfunction

  virtual task put(Packet pkt);
      pkt.print(uvm_default_line_printer);
      `uvm_info(get_type_name(),"Receives from EX-port",UVM_MEDIUM)
  endtask
endclass // end of SubComponentB class

/* Parent of sub class SubComponentB. Hence, it builds he class SubComponentB, it also builds the export
   Note, packet must flow from export to the imp in the connection phase, but not the other way round */
class ComponentB extends uvm_component;
  `uvm_component_utils(ComponentB)
  uvm_blocking_put_export #(Packet) m_put_export;
  SubComponentB subCompB;
  function new(string name = "ComponentB", uvm_component parent = null);
    super.new(name,parent);
  endfunction
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    m_put_export = new("m_put_export",this);
    subCompB = SubComponentB::type_id::create("subCompB",this);
  endfunction
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    m_put_export.connect(subCompB.m_put_imp);
    /*BELOW: [Connection Error] Cannot call an imp port's connect method. An imp is connected only to the 
       component passed in its constructor.*/
    // subCompB.m_put_imp.connect(this.m_put_export);
  endfunction
endclass // end of ComponentB class

/* A top level component to connect classes ComponentA and ComponentB. Hence, it creates both components.
   It also creates attributes (if any) that need to be passed down to lower classes, e.g. ntimes_from_top_cls
*/
class my_test extends uvm_component;
  `uvm_component_utils(my_test)
  ComponentA CompA;
  ComponentB CompB;
  function new (string name = "my_test", uvm_component parent = null);
    super.new(name,parent);
  endfunction
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    CompA = ComponentA::type_id::create("CompA",this);
    CompB = ComponentB::type_id::create("CompB",this);
    CompA.ntimes_from_top_cls = 2;
  endfunction
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    // connection of CompA port to CompB export
    CompA.m_put_port.connect(CompB.m_put_export); 
  endfunction
endclass