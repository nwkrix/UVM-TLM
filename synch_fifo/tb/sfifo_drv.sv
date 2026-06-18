import sfifo_param_pkg::*;
class sfifo_drv extends uvm_driver #(sfifo_txn);
  `uvm_component_utils(sfifo_drv)
  
  virtual ip_blk_if vif;

  function new(string name = "sfifo_drv", uvm_component parent);
    super.new(name, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db #(virtual ip_blk_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("Virt-intf", "Virt-intf not available")
    end
  endfunction
  
  task run_phase(uvm_phase phase);
    sfifo_txn tx;
    // Set initial clean idle states on the bus before running
    vif.wr_en   <= 0;
    vif.rd_en   <= 0;
    vif.wr_data <= 0;

    forever begin
      seq_item_port.get_next_item(tx);
      drive_txn(tx);
      seq_item_port.item_done();
    end
  endtask
  
  // Clean synchronous pin wiggling
  task drive_txn(sfifo_txn tx);
    // 1. Synchronize to the clocking block edge first
    @(vif.drv_cb);
    
    // 2. Drive signals through the clocking block handle using synchronous assignment
    vif.drv_cb.wr_en   <= tx.wr_en;
    vif.drv_cb.wr_data <= tx.wr_data;
    vif.drv_cb.rd_en   <= tx.rd_en;
    
    // 3. Hold for 1 clock cycle to let the RTL capture it cleanly
    @(vif.drv_cb);
    
    // 4. Return control pins to safe idle defaults immediately following the active cycle
    vif.drv_cb.wr_en   <= 0;
    vif.drv_cb.rd_en   <= 0;
  endtask
endclass
