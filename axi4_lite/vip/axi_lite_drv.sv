class axi_lite_drv extends uvm_driver #(axi_lite_txn);
  `uvm_component_utils(axi_lite_drv)

  virtual axi_lite_if vif;

  function new(string name = "axi_lite_drv", uvm_component parent);
    super.new(name,parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual axi_lite_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("NOVIF", "axi_lite_drv: virtual interface not set")
    end
  endfunction

  task run_phase(uvm_phase phase);
    axi_lite_txn tx;
    // Initialize outputs
    vif.drv_cb.AWVALID <= 0;
    vif.drv_cb.WVALID  <= 0;
    vif.drv_cb.BREADY  <= 0;
    vif.drv_cb.ARVALID <= 0;
    vif.drv_cb.RREADY  <= 0;

    forever begin
      seq_item_port.get_next_item(tx);

      case (tx.cmd)
        axi_lite_txn::AXI_WRITE: drive_write(tx);
        axi_lite_txn::AXI_READ : drive_read(tx);
        default: `uvm_error("DRV", "Unknown cmd in axi_lite_txn")
      endcase

      seq_item_port.item_done();
    end
  endtask

  // -----------------------------
  // Drive a WRITE transaction
  // -----------------------------
  // wait in monitor, do-while in drv to avoid exit code 137
  
  task drive_write(axi_lite_txn tx);
    // Drive Address
    repeat (tx.aw_delay) @(vif.drv_cb);
    vif.drv_cb.AWADDR  <= tx.addr;
    vif.drv_cb.AWVALID <= 1'b1;

    // Wait for AW handshake using clocking block loop
    do begin
      @(vif.drv_cb);
    end while (!vif.drv_cb.AWREADY);
    vif.drv_cb.AWVALID <= 1'b0;

    // Drive Data
    repeat (tx.w_delay) @(vif.drv_cb);
    vif.drv_cb.WDATA   <= tx.data;
    vif.drv_cb.WVALID  <= 1'b1;

    // Wait for W handshake using clocking block loop
    do begin
      @(vif.drv_cb);
    end while (!vif.drv_cb.WREADY);
    vif.drv_cb.WVALID <= 1'b0;

    // Handle Response
    repeat (tx.bready_delay) @(vif.drv_cb);
    vif.drv_cb.BREADY <= 1'b1;

    do begin
      @(vif.drv_cb);
    end while (!vif.drv_cb.BVALID);
    vif.drv_cb.BREADY <= 1'b0;
  endtask

task drive_read(axi_lite_txn tx);
  // Drive Address
  repeat (tx.ar_delay) @(vif.drv_cb);
  vif.drv_cb.ARADDR  <= tx.addr;
  vif.drv_cb.ARVALID <= 1'b1;

  // Wait for AR handshake safely
  do begin
    @(vif.drv_cb);
  end while (!vif.drv_cb.ARREADY);
  vif.drv_cb.ARVALID <= 1'b0;

  // Ready for Response
  repeat (tx.rready_delay) @(vif.drv_cb);
  vif.drv_cb.RREADY <= 1'b1;

  do begin
    @(vif.drv_cb);
  end while (!vif.drv_cb.RVALID);
  vif.drv_cb.RREADY <= 1'b0;
endtask
endclass