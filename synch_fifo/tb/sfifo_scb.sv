`uvm_analysis_imp_decl(_write)
`uvm_analysis_imp_decl(_read)

class sfifo_scb extends uvm_scoreboard;
  localparam WIDTH = GLOBAL_WIDTH;
  localparam DEPTH = GLOBAL_DEPTH;
  
  `uvm_component_utils(sfifo_scb)
  
  uvm_analysis_imp_write #(sfifo_txn, sfifo_scb) write_port;
  uvm_analysis_imp_read  #(sfifo_txn, sfifo_scb) read_port;
  
  // Golden reference model storage 
  protected bit [WIDTH-1:0] reference_queue [$];
  
  int match_count = 0;
  int error_count = 0;
  
  function new(string name="sfifo_scb", uvm_component parent);
    super.new(name, parent);
  endfunction
  
  virtual ip_blk_if vif;
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    write_port = new("write_port", this);
    read_port  = new("read_port", this);
    
    // let's access virtual interface here to grab rst state so we don't attempt writing when rst is high (Active Low state)
    if(!uvm_config_db #(virtual ip_blk_if)::get(this,"","vif",vif)) begin
      `uvm_fatal("NO-VIF", "vif not available for use at scb")
    end
  endfunction
  
  // 1. Handle Independent Writes from the Monitor
 virtual function void write_write( sfifo_txn txn );
    // Guard: Ignore any writes while the hardware is actively resetting
    // If your monitor tracks the reset pin, ensure you drop out here.
    
    if(txn.wr_en && !txn.full) begin
      if(reference_queue.size() >= DEPTH) begin
        `uvm_error("REF_MDL_ERR",$sformatf("Overwrite attempted in Ref Model!"))
      end else begin
        if(!vif.mon_cb.rst) begin
          reference_queue.push_back(txn.wr_data);
        `uvm_info("PREDICTOR",$sformatf("Predicted Write: Data = 0x%0h", txn.wr_data), UVM_HIGH)
        end
      end
    end
  endfunction
  
  // 2. Handle Independent Reads from the Monitor
  virtual function void write_read(sfifo_txn txn);
    if (txn.rd_en && !txn.empty) begin
      if (reference_queue.size() == 0) begin
        `uvm_error("SCB_MISMATCH", $sformatf("DUT read data = 0x%0h, but Ref Model is EMPTY", txn.rd_data))
        error_count++;
      end else begin
        bit [WIDTH-1:0] expected_data = reference_queue.pop_front();
        
        if (txn.rd_data === expected_data) begin
          `uvm_info("MATCH-OK", $sformatf("PASS! MATCH-OK: Data = 0x%0h", txn.rd_data), UVM_LOW)
          match_count++;
        end else begin
          `uvm_error("FAILED! MISMATCH", $sformatf("FAIL! Got: 0x%0h | Expected: 0x%0h", txn.rd_data, expected_data))
          error_count++;
        end
      end
    end
  endfunction
  
  function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    if (reference_queue.size() != 0) begin
      `uvm_error("CHECK_PHASE", $sformatf("End of Test, but Ref Model still contains %0d UNREAD PKTS!", reference_queue.size()))
    end
  endfunction
  
  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("FINAL_REPORT", $sformatf("\n======== SFIFO SCB REPORT =========\n Matches: %0d\n Errors: %0d\n==================================", match_count, error_count), UVM_LOW)
  endfunction
endclass