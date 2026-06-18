class axi_lite_seq extends uvm_sequence #(axi_lite_txn);
  `uvm_object_utils(axi_lite_seq)

  function new(string name = "axi_lite_seq");
    super.new(name);
  endfunction

  task body();
    axi_lite_txn tx;
    //uvm_phase phase = get_starting_phase();
    //if (phase != null) phase.raise_objection(this);
    
    repeat (100) begin
      tx = axi_lite_txn::type_id::create("tx");

      start_item(tx);
      if (!tx.randomize()) begin
        `uvm_fatal("RANDFAIL", "Failed randomization of axi_lite_txn")
      end
      finish_item(tx);
    end
    //if (phase != null) phase.drop_objection(this);
    // objections raised and dropped in test
  endtask
endclass

/*
// works but let's use the idiomatic approach
class axi_lite_seq extends uvm_sequence #(axi_lite_txn);
  `uvm_object_utils(axi_lite_seq)
  function new(string name = "axi_lite_seq");
    super.new(name);
  endfunction
  
  task body();
    axi_lite_txn tx;
    repeat (150) begin
      tx = axi_lite_txn::type_id::create("tx");
      wait_for_grant();
      if(!tx.randomize()) begin
        `uvm_fatal("Fail-Randomize","Failed randomization of txn")
      end
      send_request(tx);
      wait_for_item_done();
    end
  endtask
endclass*/