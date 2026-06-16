// Synchronous FIFO Memory IP Block
module sfifo_ip #(
  parameter DEPTH = 16,
  parameter WIDTH = 8
)(
  input logic clk,
  input logic rst, // active-high reset for simplicity
  
  // Write side
  input logic wr_en,
  input logic [WIDTH-1:0] wr_data, // write is input
  output logic full,
  
  // Read side
  input logic rd_en,
  output logic [WIDTH-1:0] rd_data,// read is output
  output logic empty
);
  
  logic [$clog2(DEPTH)-1:0] wr_ptr, rd_ptr;
  logic [WIDTH-1:0] mem [0:DEPTH-1];
  
  // write pointer and memory
  always_ff @(posedge clk or posedge rst) begin
    if(rst) begin
      wr_ptr <= '0;
    end else if(wr_en && !full) begin
      mem[wr_ptr] <= wr_data;
      wr_ptr <= wr_ptr + 1; // to be used to set status flag
    end
  end
  
  // read pointer and output
  always_ff @(posedge clk or posedge rst) begin
    if(rst) begin 
     rd_ptr <= '0;
     rd_data <= '0; // clear previously read output
    end else if(rd_en && !empty) begin
      rd_data <= mem[rd_ptr];
      rd_ptr <= rd_ptr + 1;
    end
  end
  
  //status flag
  assign full = (wr_ptr == (rd_ptr -1) % DEPTH) || (DEPTH == 1 && wr_ptr == rd_ptr && wr_en); // may adjust for edge cases
  assign empty = (wr_ptr == rd_ptr);
endmodule
