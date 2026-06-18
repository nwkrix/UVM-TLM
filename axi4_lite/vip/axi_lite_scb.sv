class axi_lite_scb extends uvm_component;
/*
Protocol-aware cos:
1) Knows the legal address map
2) expects OKAY for legal accesses & DECERR for illegal ones
3) Checks read data only when the access id legal
*/

  `uvm_component_utils(axi_lite_scb)

  // TLM input from monitor
  uvm_analysis_imp #(axi_lite_txn, axi_lite_scb) scb_aimp;

  // Reference model: 4 registers
  bit [31:0] reg_model [0:3];

  function new(string name, uvm_component parent);
    super.new(name, parent);
    scb_aimp = new("scb_aimp", this);
  endfunction

  // Called whenever monitor publishes a transaction
  function void write(axi_lite_txn tr);
    case (tr.cmd)
      axi_lite_txn::AXI_WRITE: check_write(tr);
      axi_lite_txn::AXI_READ : check_read(tr);
      default: `uvm_error("SCOREBOARD", "Unknown command in transaction")
    endcase
  endfunction

  // -----------------------------
  // Write checking
  // -----------------------------
  function void check_write(axi_lite_txn tr);
    bit legal_addr;

    legal_addr = (tr.addr inside {4'h0,4'h4,4'h8,4'hC});

    if (legal_addr) begin
      // Model update
      reg_model[tr.addr[3:2]] = tr.data;

      // Response must be OKAY
      if (tr.bresp != axi_lite_txn::AXI_OKAY) begin
        `uvm_error("AXI_WRITE_RESP",
          $sformatf("Expected AXI_OKAY for legal write addr %0h, got %0d",
                    tr.addr, tr.bresp))
      end
    end
    else begin
      // No model update; response must be DECERR
      if (tr.bresp != axi_lite_txn::AXI_DECERR) begin
        `uvm_error("AXI_WRITE_RESP",
          $sformatf("Expected AXI_DECERR for illegal write addr %0h, got %0d",
                    tr.addr, tr.bresp))
      end
    end
  endfunction

  // -----------------------------
  // Read checking
  // -----------------------------
  function void check_read(axi_lite_txn tr);
    bit legal_addr;
    bit [31:0] expected;

    legal_addr = (tr.addr inside {4'h0,4'h4,4'h8,4'hC});

    if (legal_addr) begin
      expected = reg_model[tr.addr[3:2]];

      // Response must be OKAY
      if (tr.rresp != axi_lite_txn::AXI_OKAY) begin
        `uvm_error("AXI_READ_RESP",
          $sformatf("Expected AXI_OKAY for legal read addr %0h, got %0d",
                    tr.addr, tr.rresp))
      end

      // Data must match model
      if (tr.data !== expected) begin
        `uvm_error("AXI_READ_DATA",
          $sformatf("Data mismatch at addr %0h: expected %0h, got %0h",
                    tr.addr, expected, tr.data))
      end
    end
    else begin
      // Response must be DECERR; data is don't-care (you chose zero)
      if (tr.rresp != axi_lite_txn::AXI_DECERR) begin
        `uvm_error("AXI_READ_RESP",
          $sformatf("Expected AXI_DECERR for illegal read addr %0h, got %0d",
                    tr.addr, tr.rresp))
      end
    end
  endfunction

endclass