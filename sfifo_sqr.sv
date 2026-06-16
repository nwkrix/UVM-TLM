class sfifo_sqr extends uvm_sequencer #(sfifo_txn);
  `uvm_component_utils(sfifo_sqr)
  
  function new(string name="sfifo_sqr", uvm_component parent);
    super.new(name, parent);
    `uvm_info("sfifo_sqr","constructor",UVM_MEDIUM)
  endfunction
endclass