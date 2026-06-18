import sfifo_param_pkg::*;
class sfifo_mon extends uvm_monitor;  
  `uvm_component_utils(sfifo_mon)
  
  uvm_analysis_port #(sfifo_txn) mon_write_port;
  uvm_analysis_port #(sfifo_txn) mon_read_port;
  virtual ip_blk_if vif;
  	
  function new(string name="sfifo_mon", uvm_component parent);
    super.new(name, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mon_write_port = new("mon_write_port", this);
    mon_read_port  = new("mon_read_port", this);
    
    if(!uvm_config_db#(virtual ip_blk_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("NO_VIF", "Failed to get virtual interface (vif) from config_db")
    end
  endfunction	
  
  
  bit rd_valid_d;
  bit pending_read;
  
  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    
    // Synchronize cleanly past the raw global reset release
    //@(negedge vif.mon_cb.rst);
    
    
    forever begin
      // Sample exactly on the clocking block event structure
      @(vif.mon_cb);
      
    
      
      // Safety bypass if reset occurs mid-simulation
      //if (vif.rst) continue; 

      // --- 1. SAMPLE WRITE CHANNEL ---
      if (vif.mon_cb.wr_en && !vif.mon_cb.full) begin  
        sfifo_txn write_txn;
        write_txn = sfifo_txn::type_id::create("write_txn");
        
        write_txn.wr_en   = vif.mon_cb.wr_en;
        write_txn.wr_data = vif.mon_cb.wr_data;
        write_txn.full    = vif.mon_cb.full;
        write_txn.empty   = vif.mon_cb.empty;
        
        mon_write_port.write(write_txn);
      end

      // --- 2. SAMPLE READ CHANNEL ---
      if (rd_valid_d) begin
        sfifo_txn read_txn;
        read_txn = sfifo_txn::type_id::create("read_txn");
        
        //read_txn.rd_en   = vif.mon_cb.rd_en;
        read_txn.rd_en   = 1;
        read_txn.rd_data = vif.mon_cb.rd_data;
        
        // NEVER re-write the full/empty txn states: spoils timing sync
        //read_txn.full    = vif.mon_cb.full;
        //read_txn.empty   = vif.mon_cb.empty;
        
        mon_read_port.write(read_txn);
      end
      
      // Checks AFTER the first cycle; checking pending reading 1 cycle later. 
      
      if(vif.mon_cb.rd_en && !vif.mon_cb.empty) begin
        rd_valid_d = 1;
      end else begin 
        rd_valid_d = 0;
      end
      
      
      
      // First capture data from previous read
    /*
      if(pending_read) begin
        sfifo_txn read_txn;

        read_txn = sfifo_txn::type_id::create("read_txn");

        read_txn.rd_en   = 1;
        read_txn.rd_data = vif.mon_cb.rd_data;
        
        mon_read_port.write(read_txn);
      end
      // Then schedule next read capture
      pending_read = (vif.mon_cb.rd_en && !vif.mon_cb.empty);
    */
      
      
    end
  endtask
endclass