class sfifo_env extends uvm_env;  
  `uvm_component_utils(sfifo_env)
  
  // agent in env, scb in env
  sfifo_scb scb;
  sfifo_agt agt;
  
  sfifo_cov cov;
  
  function new(string name="sfifo_env",uvm_component parent);
    super.new(name,parent);
    `uvm_info("sfifo_env","constructor", UVM_MEDIUM)
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    scb = sfifo_scb::type_id::create("scb",this);
    agt = sfifo_agt::type_id::create("agt",this); 
    cov = sfifo_cov::type_id::create("cov",this);
  endfunction
  
  //structural wiring step
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    // Connect the Producer Analysis Port -> Consumer's Analysis Imp
   //1a. connect agent write monitor stream to scoreboard write predictor
    agt.agt_write_port.connect(scb.write_port);
    
    //1b. Connect Agent's read port (from monitor read port) to scb read comparator 
    agt.agt_read_port.connect(scb.read_port);
    
    
    // 2. Connect the same Monitor (broadcast) port to your Coverage Collector imps
    // Assuming your sfifo_cov class has matching analysis_export ports:
    agt.mon.mon_write_port.connect(cov.write_export); 
    agt.mon.mon_read_port.connect(cov.read_export);
    
    `uvm_info("ENV_CONNECT","SCB Analysis Imps successfully connected to Agent Monitors", UVM_LOW)
  endfunction
  
endclass