class axi_lite_tst extends uvm_test;
  `uvm_component_utils(axi_lite_tst)
  
  axi_lite_env env;
  axi_lite_seq seq;
  
  function new(string name = "axi_lite_tst", uvm_component parent);
    super.new(name,parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    env = axi_lite_env::type_id::create("env",this);
    seq = axi_lite_seq::type_id::create("seq");
  endfunction
  
  virtual function void end_of_elaboration();
    super.end_of_elaboration();
    print(); 
  endfunction
  
  task run_phase(uvm_phase phase);
    //phase.raise_objection(this, "Starting AXI-Lite stimulus sequence");
    phase.raise_objection(this);
    seq.start(env.agt.sqr); // Starts the sequence on the agent's sequencer
  	phase.drop_objection(this);
    //phase.drop_objection(this, "Finished AXI-Lite stimulus sequence");
endtask
  
endclass