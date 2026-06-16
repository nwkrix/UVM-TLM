class sfifo_seq extends uvm_sequence # (sfifo_txn);
  `uvm_object_utils(sfifo_seq)
  
  function new(string name="sfifo_seq");
    super.new(name);
  endfunction
  
  task body();
    sfifo_txn tx;
    repeat (100) begin
      tx = sfifo_txn::type_id::create("tx");
      wait_for_grant();
      //assert(tx.randomize()); // to catch randomization failure
      // void'(tx.randomize()); // keeps going despite failure to randomize
      if (!tx.randomize()) begin
        `uvm_fatal("RAND_FAIL", "Transaction randomization failed! Check constraints.")
      end
      send_request(tx);
      wait_for_item_done();
    end
  endtask
endclass
