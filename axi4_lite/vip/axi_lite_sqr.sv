class axi_lite_sqr extends uvm_sequencer #(axi_lite_txn);
  `uvm_component_utils(axi_lite_sqr)

  function new(string name = "axi_lite_sqr", uvm_component parent);
    super.new(name,parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction
endclass