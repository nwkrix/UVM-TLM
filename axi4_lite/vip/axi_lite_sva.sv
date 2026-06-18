module axi_lite_assertions (
    axi_lite_if vif
);

  // ============================================================
  // WRITE CHANNEL ASSERTIONS
  // ============================================================

  // -----------------------------
  // AWADDR must remain stable while AWVALID && !AWREADY
  // -----------------------------
  property p_aw_stable;
    @(posedge vif.ACLK)
    disable iff(!vif.ARESETn)
      vif.AWVALID && !vif.AWREADY |=> $stable(vif.AWADDR);
  endproperty

  assert property(p_aw_stable)
    else $error("AXI-Lite ERROR: AWADDR changed while AWVALID && !AWREADY");


  // -----------------------------
  // WDATA must remain stable while WVALID && !WREADY
  // -----------------------------
  property p_w_stable;
    @(posedge vif.ACLK)
    disable iff(!vif.ARESETn)
      vif.WVALID && !vif.WREADY |=> $stable(vif.WDATA);
  endproperty

  assert property(p_w_stable)
    else $error("AXI-Lite ERROR: WDATA changed while WVALID && !WREADY");


  // -----------------------------
  // BVALID must remain asserted until BREADY
  // -----------------------------
  property p_bvalid_hold;
    @(posedge vif.ACLK)
    disable iff(!vif.ARESETn)
      vif.BVALID && !vif.BREADY |=> vif.BVALID;
  endproperty

  assert property(p_bvalid_hold)
    else $error("AXI-Lite ERROR: BVALID deasserted before BREADY handshake");


  // -----------------------------
  // BVALID must occur after AW and W handshakes
  // -----------------------------
  property p_bvalid_after_write;
    @(posedge vif.ACLK)
    disable iff(!vif.ARESETn)
      (vif.AWVALID && vif.AWREADY &&
       vif.WVALID  && vif.WREADY)
      |=> ##[1:5] vif.BVALID;
  endproperty

  assert property(p_bvalid_after_write)
    else $error("AXI-Lite ERROR: BVALID did not follow AW/W handshake");


  // -----------------------------
  // BRESP must be legal (OKAY or DECERR)
  // -----------------------------
  property p_bresp_valid;
    @(posedge vif.ACLK)
    disable iff(!vif.ARESETn)
      vif.BVALID |-> (vif.BRESP inside {2'b00, 2'b11});
  endproperty

  assert property(p_bresp_valid)
    else $error("AXI-Lite ERROR: Illegal BRESP value detected");


  // ============================================================
  // READ CHANNEL ASSERTIONS
  // ============================================================

  // -----------------------------
  // ARADDR must remain stable while ARVALID && !ARREADY
  // -----------------------------
  property p_araddr_stable;
    @(posedge vif.ACLK)
    disable iff(!vif.ARESETn)
      vif.ARVALID && !vif.ARREADY |=> $stable(vif.ARADDR);
  endproperty

  assert property(p_araddr_stable)
    else $error("AXI-Lite ERROR: ARADDR changed while ARVALID && !ARREADY");


  // -----------------------------
  // RDATA must remain stable while RVALID && !RREADY
  // -----------------------------
  property p_rdata_stable;
    @(posedge vif.ACLK)
    disable iff(!vif.ARESETn)
      vif.RVALID && !vif.RREADY |=> $stable(vif.RDATA);
  endproperty

  assert property(p_rdata_stable)
    else $error("AXI-Lite ERROR: RDATA changed while RVALID && !RREADY");


  // -----------------------------
  // RVALID must remain asserted until RREADY
  // -----------------------------
  property p_rvalid_hold;
    @(posedge vif.ACLK)
    disable iff(!vif.ARESETn)
      vif.RVALID && !vif.RREADY |=> vif.RVALID;
  endproperty

  assert property(p_rvalid_hold)
    else $error("AXI-Lite ERROR: RVALID deasserted before RREADY handshake");


  // -----------------------------
  // RVALID must follow AR handshake
  // -----------------------------
  property p_rvalid_after_read;
    @(posedge vif.ACLK)
    disable iff(!vif.ARESETn)
      (vif.ARVALID && vif.ARREADY)
      |=> ##[1:5] vif.RVALID;
  endproperty

  assert property(p_rvalid_after_read)
    else $error("AXI-Lite ERROR: RVALID did not follow AR handshake");


  // -----------------------------
  // RRESP must be legal (OKAY or DECERR)
  // -----------------------------
  property p_rresp_valid;
    @(posedge vif.ACLK)
    disable iff(!vif.ARESETn)
      vif.RVALID |-> (vif.RRESP inside {2'b00, 2'b11});
  endproperty

  assert property(p_rresp_valid)
    else $error("AXI-Lite ERROR: Illegal RRESP value detected");

endmodule