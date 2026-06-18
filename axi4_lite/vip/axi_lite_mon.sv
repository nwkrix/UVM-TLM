class axi_lite_mon extends uvm_component;
  //Protocol-aware cos:
  //1) waits for proper VALID/READY handshakes
  //2) captures BRESP & RRESP
  //3) Distinguishes read vs write txns

  `uvm_component_utils(axi_lite_mon)

  virtual axi_lite_if vif;
  uvm_analysis_port #(axi_lite_txn) mon_ap;

  function new(string name = "axi_lite_mon", uvm_component parent);
    super.new(name, parent);
    mon_ap = new("mon_ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual axi_lite_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("NOVIF", "axi_lite_mon: virtual interface not set")
    end
  endfunction

  task run_phase(uvm_phase phase);
    fork
      monitor_write();
      monitor_read();
    join
  endtask

  // -----------------------------
  // Write path: AW + W + BRESP
  // -----------------------------
  task monitor_write();
    axi_lite_txn tr;
    bit [3:0]   awaddr;
    bit [31:0]  wdata;
    bit [1:0]   bresp;

    forever begin
      // Wait for address handshake
      @(vif.mon_cb);
      wait (vif.mon_cb.AWVALID && vif.mon_cb.AWREADY);
      awaddr = vif.mon_cb.AWADDR;

      // Wait for data handshake
      @(vif.mon_cb);
      wait (vif.mon_cb.WVALID && vif.mon_cb.WREADY);
      wdata = vif.mon_cb.WDATA;

      // Wait for response handshake
      @(vif.mon_cb);
      wait (vif.mon_cb.BVALID);
      bresp = vif.mon_cb.BRESP;
      wait (vif.mon_cb.BVALID && vif.mon_cb.BREADY);

      // Build transaction
      tr = axi_lite_txn::type_id::create("wr_tr", this);
      tr.cmd   = axi_lite_txn::AXI_WRITE;
      tr.addr  = awaddr;
      tr.data  = wdata;
      tr.bresp = axi_lite_txn::axi_resp_e'(bresp);
      
      //log uvm_info
      `uvm_info(
  "MON",
  $sformatf(
    "cmd=%s addr=%0h bresp=%0d rresp=%0d",
    tr.cmd.name(),
    tr.addr,
    tr.bresp,
    tr.rresp
  ),
  UVM_LOW
)

      mon_ap.write(tr);
    end
  endtask

  // -----------------------------
  // Read path: AR + RDATA/RRESP
  // -----------------------------
  task monitor_read();
    axi_lite_txn tr;
    bit [3:0]   araddr;
    bit [31:0]  rdata;
    bit [1:0]   rresp;

    forever begin
      // Wait for address handshake
      @(vif.mon_cb);
      wait (vif.mon_cb.ARVALID && vif.mon_cb.ARREADY);
      araddr = vif.mon_cb.ARADDR;

      // Wait for data/response handshake
      @(vif.mon_cb);
      wait (vif.mon_cb.RVALID);
      rdata = vif.mon_cb.RDATA;
      rresp = vif.mon_cb.RRESP;
      wait (vif.mon_cb.RVALID && vif.mon_cb.RREADY);

      // Build transaction
      tr = axi_lite_txn::type_id::create("rd_tr", this);
      tr.cmd   = axi_lite_txn::AXI_READ;
      tr.addr  = araddr;
      tr.data  = rdata;
      tr.rresp = axi_lite_txn::axi_resp_e'(rresp);

      mon_ap.write(tr);
    end
  endtask
endclass