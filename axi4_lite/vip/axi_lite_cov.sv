class axi_lite_cov extends uvm_component;

  `uvm_component_utils(axi_lite_cov)

  uvm_analysis_imp #(axi_lite_txn, axi_lite_cov) cov_aimp;

  axi_lite_txn tr_last;

  //covergroup cg @(vif.mon_cb);
  covergroup cg;
    option.per_instance = 1;

    // Command type
    cmd_cp : coverpoint tr_last.cmd {
      bins read  = {axi_lite_txn::AXI_READ};
      bins write = {axi_lite_txn::AXI_WRITE};
    }

    // Address legality
    legal_cp : coverpoint (tr_last.addr inside {4'h0,4'h4,4'h8,4'hC}) {
      bins legal   = {1'b1};
      bins illegal = {1'b0};
    }

    // Write response
    bresp_cp : coverpoint tr_last.bresp iff (tr_last.cmd == axi_lite_txn::AXI_WRITE) {
      bins okay   = {axi_lite_txn::AXI_OKAY};
      bins decerr = {axi_lite_txn::AXI_DECERR};
      illegal_bins bad = default; // SLVERR & EXOKAY should never occur
    }

    // Read response
    rresp_cp : coverpoint tr_last.rresp iff (tr_last.cmd == axi_lite_txn::AXI_READ) {
      bins okay   = {axi_lite_txn::AXI_OKAY};
      bins decerr = {axi_lite_txn::AXI_DECERR};
      illegal_bins bad = default; // SLVERR & EXOKAY should never occur
    }
    
    // are all registers exercised? Add address coverage
    addr_cp : coverpoint tr_last.addr {
      bins reg0 = {4'h0};
      bins reg1 = {4'h4};
      bins reg2 = {4'h8};
      bins reg3 = {4'hC};

      /*bins illegal[] =
          {4'h1,4'h2,4'h3,
           4'h5,4'h6,4'h7,
           4'h9,4'hA,4'hB,
           4'hD,4'hE,4'hF};*/
    }
    
    cmd_addr_x : cross cmd_cp, addr_cp;

    // Cross coverage
    //cmd_legal_bresp_x : cross cmd_cp, legal_cp, bresp_cp;
    //cmd_legal_rresp_x : cross cmd_cp, legal_cp, rresp_cp;
    
    
    //---------------------------------------------
    // ignore_bins: ignore impossible combinations
    //---------------------------------------------
    //1. For write response coverage:
    cmd_legal_bresp_x : cross cmd_cp, legal_cp, bresp_cp {
      ignore_bins read_ops = binsof(cmd_cp.read);

      ignore_bins legal_decerr =
          binsof(cmd_cp.write) &&
          binsof(legal_cp.legal) &&
          binsof(bresp_cp.decerr);

      ignore_bins illegal_okay =
          binsof(cmd_cp.write) &&
          binsof(legal_cp.illegal) &&
          binsof(bresp_cp.okay);
    }
    //2. For read response ccoverage
    cmd_legal_rresp_x : cross cmd_cp, legal_cp, rresp_cp {

      ignore_bins write_ops =
          binsof(cmd_cp.write);

      ignore_bins legal_decerr =
          binsof(cmd_cp.read) &&
          binsof(legal_cp.legal) &&
          binsof(rresp_cp.decerr);

      ignore_bins illegal_okay =
          binsof(cmd_cp.read) &&
          binsof(legal_cp.illegal) &&
          binsof(rresp_cp.okay);
    }

  endgroup

  virtual axi_lite_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    cov_aimp = new("cov_aimp", this);
    // Instantiate the covergroup to allocate memory for coverage collection
    cg = new();
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual axi_lite_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "axi_lite_cov: vif not set");
  endfunction

  function void write(axi_lite_txn tr);
    tr_last = tr;
    cg.sample();
  endfunction
  
  function void report_phase(uvm_phase phase);

    `uvm_info("COVERAGE",
      $sformatf("Coverage = %0.2f%%",
                cg.get_inst_coverage()),
      UVM_LOW)

      $display("cmd_cp coverage   = %0.2f%%", cg.cmd_cp.get_coverage());
      $display("legal_cp coverage = %0.2f%%", cg.legal_cp.get_coverage());
      $display("bresp_cp coverage = %0.2f%%", cg.bresp_cp.get_coverage());
      $display("rresp_cp coverage = %0.2f%%", cg.rresp_cp.get_coverage());
      $display("addr_cp coverage = %0.2f%%", cg.addr_cp.get_coverage());
      $display("cmd_addr_x coverage = %0.2f%%", cg.cmd_addr_x.get_coverage());
  endfunction

endclass
