class axi_lite_env extends uvm_env;
  `uvm_component_utils(axi_lite_env)

  axi_lite_scb scb;
  axi_lite_agt agt;
  axi_lite_cov cov;
  
  function new(string name="axi_lite_env", uvm_component parent);
    super.new(name,parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    scb = axi_lite_scb::type_id::create("scb",this);
    agt = axi_lite_agt::type_id::create("agt",this);
    cov = axi_lite_cov::type_id::create("cov",this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agt.agt_aport.connect(scb.scb_aimp); // connect agent & scb
    agt.agt_aport.connect(cov.cov_aimp);  // connect agent analysis port to cov
  endfunction
  
  virtual function void write(axi_lite_txn tx);
    
  endfunction
endclass