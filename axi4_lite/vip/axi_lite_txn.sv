class axi_lite_txn extends uvm_sequence_item;
/* REUSABLE VIP
axi_lite_txn is purely abstract: it does not know about pins, only about for e.g., 
“do a write to this address with this data” and “this is the response I saw.”*/

  `uvm_object_utils(axi_lite_txn)

  // Command type: abstract (read vs write)
  typedef enum {
    AXI_READ,
    AXI_WRITE
  } axi_cmd_e;

  // Protocol response type: matches DUT BRESP/RRESP
  typedef enum bit[1:0] {
    AXI_OKAY   = 2'b00,
    AXI_EXOKAY = 2'b01,
    AXI_SLVERR = 2'b10,
    AXI_DECERR = 2'b11
  } axi_resp_e;

  //------------------------------------
  // Transaction Fields (abstract layer)
  //------------------------------------

  rand axi_cmd_e   cmd;          // read or write
  rand bit [3:0]   addr;         // byte address (4 regs: 0,4,8,C)
  rand bit [31:0]  data;         // write data or expected read data (for scb)

  // Observed protocol responses (filled by monitor)
  axi_resp_e       bresp;        // write response from DUT
  axi_resp_e       rresp;        // read response from DUT

  //------------------------------------
  // Timing Controls (VIP knobs)
  //------------------------------------

  rand int unsigned aw_delay;     // cycles before AWVALID
  rand int unsigned w_delay;      // cycles before WVALID
  rand int unsigned ar_delay;     // cycles before ARVALID

  rand int unsigned bready_delay; // cycles before BREADY
  rand int unsigned rready_delay; // cycles before RREADY

  //------------------------------------
  // Debug / bookkeeping
  //------------------------------------

  int txn_id;

  //------------------------------------
  // Constraints
  //------------------------------------

  // For now, generate only legal addresses; you can relax this later
  //constraint legal_addr_c {addr inside {4'h0,4'h4,4'h8,4'hC};}
  rand bit legal_addr;
  constraint addr_c {
    if (legal_addr)
      addr inside {4'h0,4'h4,4'h8,4'hC};
    else
      !(addr inside {4'h0,4'h4,4'h8,4'hC});
  }
  
  constraint legal_bias_c { // add bias 90% legal_addr, 10 % illegal_addr
    legal_addr dist {
      1 := 90,
      0 := 10
    };
  }

  constraint delay_c {
    aw_delay     inside {[0:10]};
    w_delay      inside {[0:10]};
    ar_delay     inside {[0:10]};
    bready_delay inside {[0:10]};
    rready_delay inside {[0:10]};
  }

  //------------------------------------
  // Constructor
  //------------------------------------

  function new(string name = "axi_lite_txn");
    super.new(name);
  endfunction

endclass