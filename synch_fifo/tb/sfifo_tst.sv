class sfifo_tst extends uvm_test;
  `uvm_component_utils(sfifo_tst)
  
  sfifo_env env;
  sfifo_seq seq;
  //sfifo_sqr sqr;
  
  function new(string name = "sfifo_tst", uvm_component parent);
    super.new(name,parent);
    `uvm_info("sfifo_tst","constructor", UVM_MEDIUM)
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = sfifo_env::type_id::create("env",this);
    //sqr = sfifo_sqr::type_id::create("sqr" this);
    seq = sfifo_seq::type_id::create("seq");
  endfunction
  
  virtual function void end_of_elaboration();
    super.end_of_elaboration();
    print();
  endfunction
  
  virtual task run_phase(uvm_phase phase);    
    // Lock the phase open
    phase.raise_objection(this);
    // Start the sequence on your agent's sequencer
    seq.start(env.agt.sqr);
    // Drop objection when sequence completes, allowing UVM to exit cleanly
    phase.drop_objection(this);
endtask
  
endclass