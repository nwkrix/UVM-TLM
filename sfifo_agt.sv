class sfifo_agt extends uvm_agent;
  `uvm_component_utils(sfifo_agt)
  
  sfifo_mon mon;
  sfifo_drv drv;
  sfifo_sqr sqr;
  
  function new(string name="sfifo_agt",uvm_component parent);
    super.new(name,parent);
    `uvm_info("sfifo_agt","constructor", UVM_MEDIUM)
  endfunction
  
  // create port for connection to scoreboard
  uvm_analysis_port #(sfifo_txn) agt_write_port;
  uvm_analysis_port #(sfifo_txn) agt_read_port;
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mon = sfifo_mon::type_id::create("mon",this);
    drv = sfifo_drv::type_id::create("drv",this);
    sqr = sfifo_sqr::type_id::create("sqr",this);
    
    agt_write_port = new("agt_write_port",this);
    agt_read_port = new("agt_read_port",this);
    
  endfunction
  
  
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    drv.seq_item_port.connect(sqr.seq_item_export);
    
    // points the agents boundary ports to the inner monitor pors
    agt_write_port = mon.mon_write_port;
    agt_read_port = mon.mon_read_port;
  endfunction
  
  
endclass