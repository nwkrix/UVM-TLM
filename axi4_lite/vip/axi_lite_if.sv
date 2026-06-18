interface axi_lite_if
#(
  parameter ADDR_WIDTH = 4,
  parameter DATA_WIDTH = 32
)
(
  input logic ACLK,
  input logic ARESETn
);

  // ==========================================
  // Signal Declarations
  // ==========================================
  logic [ADDR_WIDTH-1:0] AWADDR;
  logic                  AWVALID;
  logic                  AWREADY;

  logic [DATA_WIDTH-1:0] WDATA;
  logic                  WVALID;
  logic                  WREADY;

  logic [1:0]            BRESP;   // Added protocol-aware write response
  logic                  BVALID;
  logic                  BREADY;

  logic [ADDR_WIDTH-1:0] ARADDR;
  logic                  ARVALID;
  logic                  ARREADY;

  logic [DATA_WIDTH-1:0] RDATA;
  logic [1:0]            RRESP;   // Added protocol-aware read response
  logic                  RVALID;
  logic                  RREADY;


  // ==========================================
  // Driver Clocking Block (Master Role)
  // ==========================================
  clocking drv_cb @(posedge ACLK);
    // Change these from 'output' to 'inout' so the driver can read them back
    inout AWADDR;
    inout AWVALID;
    inout WDATA;
    inout WVALID;
    inout BREADY;
    inout ARADDR;
    inout ARVALID;
    inout RREADY;

    // DUT Handshakes & Responses (Keep as input)
    input  AWREADY;
    input  WREADY;
    input  BRESP;   
    input  BVALID;
    input  ARREADY;
    input  RDATA;
    input  RRESP;   
    input  RVALID;
  endclocking

  // ==========================================
  // Monitor Clocking Block (Passive Observer)
  // ==========================================
  // all readable for the monitor
  clocking mon_cb @(posedge ACLK);
    input AWADDR;
    input AWVALID;
    input AWREADY;

    input WDATA;
    input WVALID;
    input WREADY;

    input BRESP;   // Added as input to the monitor
    input BVALID;
    input BREADY;

    input ARADDR;
    input ARVALID;
    input ARREADY;

    input RDATA;
    input RRESP;   // Added as input to the monitor
    input RVALID;
    input RREADY;
  endclocking
  
  // ============================================================
  // SYSTEMVERILOG ASSERTIONS
  // ============================================================

  // ============================================================
  // 1. WRITE CHANNEL ASSERTIONS
  // ============================================================

  // -----------------------------
  // AWADDR must remain stable while AWVALID && !AWREADY
  // -----------------------------
  property p_aw_stable;
    @(posedge ACLK)
    disable iff(!ARESETn)
      AWVALID && !AWREADY |=> $stable(AWADDR);
  endproperty

  assert property(p_aw_stable)
    else $error("AXI-Lite ERROR: AWADDR changed while AWVALID && !AWREADY");


  // -----------------------------
  // WDATA must remain stable while WVALID && !WREADY
  // -----------------------------
  property p_w_stable;
    @(posedge ACLK)
    disable iff(!ARESETn)
      WVALID && !WREADY |=> $stable(WDATA);
  endproperty

  assert property(p_w_stable)
    else $error("AXI-Lite ERROR: WDATA changed while WVALID && !WREADY");


  // -----------------------------
  // BVALID must remain asserted until BREADY
  // -----------------------------
  property p_bvalid_hold;
    @(posedge ACLK)
    disable iff(!ARESETn)
      BVALID && !BREADY |=> BVALID;
  endproperty

  assert property(p_bvalid_hold)
    else $error("AXI-Lite ERROR: BVALID deasserted before BREADY handshake");


  // -----------------------------
  // BVALID must occur after AW and W handshakes
  // -----------------------------
  property p_bvalid_after_write;
    @(posedge ACLK)
    disable iff(!ARESETn)
      (AWVALID && AWREADY &&
       WVALID  && WREADY)
      |=> ##[1:5] BVALID;
  endproperty

  assert property(p_bvalid_after_write)
    else $error("AXI-Lite ERROR: BVALID did not follow AW/W handshake");


  // -----------------------------
  // BRESP must be legal (OKAY or DECERR)
  // -----------------------------
  property p_bresp_valid;
    @(posedge ACLK)
    disable iff(!ARESETn)
      BVALID |-> (BRESP inside {2'b00, 2'b11});
  endproperty

  assert property(p_bresp_valid)
    else $error("AXI-Lite ERROR: Illegal BRESP value detected");


  // ============================================================
  // 2. READ CHANNEL ASSERTIONS
  // ============================================================

  // -----------------------------
  // ARADDR must remain stable while ARVALID && !ARREADY
  // -----------------------------
  property p_araddr_stable;
    @(posedge ACLK)
    disable iff(!ARESETn)
      ARVALID && !ARREADY |=> $stable(ARADDR);
  endproperty

  assert property(p_araddr_stable)
    else $error("AXI-Lite ERROR: ARADDR changed while ARVALID && !ARREADY");


  // -----------------------------
  // RDATA must remain stable while RVALID && !RREADY
  // -----------------------------
  property p_rdata_stable;
    @(posedge ACLK)
    disable iff(!ARESETn)
      RVALID && !RREADY |=> $stable(RDATA);
  endproperty

  assert property(p_rdata_stable)
    else $error("AXI-Lite ERROR: RDATA changed while RVALID && !RREADY");


  // -----------------------------
  // RVALID must remain asserted until RREADY
  // -----------------------------
  property p_rvalid_hold;
    @(posedge ACLK)
    disable iff(!ARESETn)
      RVALID && !RREADY |=> RVALID;
  endproperty

  assert property(p_rvalid_hold)
    else $error("AXI-Lite ERROR: RVALID deasserted before RREADY handshake");


  // -----------------------------
  // RVALID must follow AR handshake
  // -----------------------------
  property p_rvalid_after_read;
    @(posedge ACLK)
    disable iff(!ARESETn)
      (ARVALID && ARREADY)
      |=> ##[1:5] RVALID;
  endproperty

  assert property(p_rvalid_after_read)
    else $error("AXI-Lite ERROR: RVALID did not follow AR handshake");


  // -----------------------------
  // RRESP must be legal (OKAY or DECERR)
  // -----------------------------
  property p_rresp_valid;
    @(posedge ACLK)
    disable iff(!ARESETn)
      RVALID |-> (RRESP inside {2'b00, 2'b11});
  endproperty

  assert property(p_rresp_valid)
    else $error("AXI-Lite ERROR: Illegal RRESP value detected");

endinterface