class axi_lite_agt extends uvm_agent;
  `uvm_component_utils(axi_lite_agt)

  axi_lite_sqr sqr;
  axi_lite_drv drv;
  axi_lite_mon mon;

  uvm_analysis_port #(axi_lite_txn) agt_aport;

  function new(string name = "axi_lite_agt", uvm_component parent);
    super.new(name,parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    sqr = axi_lite_sqr::type_id::create("sqr",this);
    drv = axi_lite_drv::type_id::create("drv",this);
    mon = axi_lite_mon::type_id::create("mon",this);
    agt_aport = new("agt_aport",this);
  endfunction
  
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    drv.seq_item_port.connect(sqr.seq_item_export);
   
    // Connect monitor to the external port of agt
    agt_aport = mon.mon_ap;
    
  endfunction
endclass