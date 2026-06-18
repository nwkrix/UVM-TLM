//class sfifo_txn#(int WIDTH = 8) extends uvm_sequence_item;
import sfifo_param_pkg::*;
class  sfifo_txn extends uvm_sequence_item;
  rand bit rd_en;
  rand bit wr_en;
  rand bit[GLOBAL_WIDTH-1:0] wr_data; 
  
  // outputs
  bit [GLOBAL_WIDTH-1:0] rd_data;
  bit full;
  bit empty;
  
  constraint valid_ops { !(wr_en && rd_en); } // prevent simultaneous rd & wr
  constraint wr_when_not_full {}
  constraint rd_when_not_empty {}
  
  //`uvm_object_utils_begin(sfifo_txn#(WIDTH))
  `uvm_object_utils_begin(sfifo_txn)
  	`uvm_field_int(rd_en,UVM_ALL_ON)
  	`uvm_field_int(wr_en,UVM_ALL_ON)
  	`uvm_field_int(wr_data,UVM_ALL_ON)
  	`uvm_field_int(rd_data,UVM_ALL_ON)
  	`uvm_field_int(full,UVM_ALL_ON)
  	`uvm_field_int(empty,UVM_ALL_ON)
  `uvm_object_utils_end
  
  function new(string name = "sfifo_txn");
    super.new(name);
	`uvm_info("sfifo_txn","constructor",UVM_MEDIUM)
  endfunction
endclass