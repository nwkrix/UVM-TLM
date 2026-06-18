interface ip_blk_if(
  input bit clk,
  input bit rst
);
  import sfifo_param_pkg::*;

  logic wr_en;
  logic [GLOBAL_WIDTH-1:0] wr_data;
  logic full;
  
  logic rd_en;
  logic [GLOBAL_WIDTH-1:0] rd_data;
  logic empty;
  
  // DRIVER CB: Outputs are driven slightly AFTER the clock edge
  clocking drv_cb @(posedge clk);
    default input #1ns output #1ns;
    output wr_en;
    output wr_data;
    output rd_en;
    input  full;  // Outputs from DUT are inputs to Driver
    input  empty; // Outputs from DUT are inputs to Driver
  endclocking

  // MONITOR CB: Inputs are sampled stable, slightly BEFORE the clock edge
  clocking mon_cb @(posedge clk);
    default input #1ns output #1ns;
    input wr_en;
    input wr_data;
    input rd_en;
    input rd_data;
    input empty;
    input full;
    input rst;
  endclocking

endinterface
