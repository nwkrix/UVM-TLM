`timescale 1ns/1ps
`include "uvm_macros.svh"
import uvm_pkg::*;

`include "axi_lite_if.sv"
`include "axi_lite_txn.sv"
`include "axi_lite_seq.sv"
`include "axi_lite_mon.sv"
`include "axi_lite_drv.sv"
`include "axi_lite_sqr.sv"
`include "axi_lite_agt.sv"
`include "axi_lite_cov.sv"
`include "axi_lite_scb.sv"
`include "axi_lite_env.sv"
`include "axi_lite_tst.sv"

//`include "axi_lite_sva.sv" // Now in interface

module tb_top;

  localparam ADDR_WIDTH = 4;
  localparam DATA_WIDTH = 32;

  logic ACLK;
  logic ARESETn;

  //----------------------------------------------------
  // AXI Interface
  //----------------------------------------------------
  axi_lite_if #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
  ) axi_if(
    .ACLK(ACLK),
    .ARESETn(ARESETn)
  );
  
  //-------------------------------------------------------
  // BIND Assertions to the Interface  (NOW IN Interface)
  // Can bind to the DUT if DUT input arg. is of type axi_lite_if
  //-------------------------------------------------------
  //bind axi_lite_if axi_lite_assertions axi_lite_assertions_i (axi_if);
  
  // Direct instantiation
  // axi_lite_assertions sva_inst (.vif(axi_if)); 

  //----------------------------------------------------
  // DUT
  //----------------------------------------------------
  axi_lite_sub #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
  ) dut (

    .ACLK    (ACLK),
    .ARESETn (ARESETn),

    .AWADDR  (axi_if.AWADDR),
    .AWVALID (axi_if.AWVALID),
    .AWREADY (axi_if.AWREADY),

    .WDATA   (axi_if.WDATA),
    .WVALID  (axi_if.WVALID),
    .WREADY  (axi_if.WREADY),

    .BRESP   (axi_if.BRESP),
    .BVALID  (axi_if.BVALID),
    .BREADY  (axi_if.BREADY),

    .ARADDR  (axi_if.ARADDR),
    .ARVALID (axi_if.ARVALID),
    .ARREADY (axi_if.ARREADY),

    .RDATA   (axi_if.RDATA),
    .RRESP   (axi_if.RRESP),
    .RVALID  (axi_if.RVALID),
    .RREADY  (axi_if.RREADY)
  );

  //----------------------------------------------------
  // Clock Generation
  //----------------------------------------------------
  initial begin
    ACLK = 0;
    forever #5 ACLK = ~ACLK;
  end

  //----------------------------------------------------
  // Reset Generation
  //----------------------------------------------------
  initial begin
    ARESETn = 0;

    repeat(5) @(posedge ACLK);

    ARESETn = 1;
  end
  

  //----------------------------------------------------
  // UVM Configuration
  //----------------------------------------------------
  // Pass paramters to lower hierarchy where they're needed
  initial begin
    uvm_config_db#(int)::set(
      null,
      "*",
      "ADDR_WIDTH",
      ADDR_WIDTH
    );
    uvm_config_db#(int)::set(
      null,
      "*",
      "DATA_WIDTH",
      DATA_WIDTH
    );
  end
  
  // Hook virtual interface to UVM
  initial begin
    uvm_config_db#(virtual axi_lite_if)::set(
        null,
        "*",
        "vif",
        axi_if
    );
  end
  
  initial begin
    run_test("axi_lite_tst");
  end
  
  initial begin
    //$monitor($time,"ns,\ta-clk=%0d, rst=%0d",ACLK,ARESETn);
    $dumpfile("dump.vcd");
    $dumpvars;
  end
  
endmodule