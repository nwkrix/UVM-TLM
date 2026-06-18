`timescale 1ns/1ns
`include "uvm_macros.svh"
import uvm_pkg::*;

//import parameter package
`include "sfifo_pkg.sv" 
import sfifo_param_pkg::*;

`include "ip_if.sv"
`include "sfifo_txn.sv"
`include "sfifo_seq.sv"
`include "sfifo_sqr.sv"
`include "sfifo_mon.sv"
`include "sfifo_drv.sv"
`include "sfifo_agt.sv"
`include "sfifo_cov.sv"
`include "sfifo_scb.sv"
`include "sfifo_env.sv"
`include "sfifo_tst.sv"

module tb_top;
  
  // clock signal generation
  logic clk;
  initial begin
    clk = 1'b0;
    forever begin
      #10 clk = ~clk;
    end
  end
  // reset signal
  logic rst;
  initial begin
    rst = 1'b1;
    #40 rst = 1'b0;
  end

  
  ip_blk_if intf(
    .clk(clk),
    .rst(rst)
  );
  
  sfifo_ip # (
    .DEPTH(GLOBAL_DEPTH),
    .WIDTH(GLOBAL_WIDTH)
  )
  dut (
    .clk(clk),
    .rst(rst),
    .wr_en(intf.wr_en),
    .wr_data(intf.wr_data),
    .full(intf.full),
    .rd_en(intf.rd_en),
    .rd_data(intf.rd_data),
    .empty(intf.empty)
  );
  
  
  initial begin
  	// make dut interfaces virtually accessible down ...
    //the uvm hierarchy using config_db
    uvm_config_db#(virtual ip_blk_if)::set(null, "*", "vif", intf);
  end
  
  initial begin
     // start uvm_verification
    run_test("sfifo_tst");
  end
  
  initial begin
    $monitor($time,"ns,\tclk=%0d, rst=%0d",clk,rst);
    $dumpfile("dump.vcd");
    $dumpvars;
  end
endmodule