`uvm_analysis_imp_decl(_write_cov)
`uvm_analysis_imp_decl(_read_cov)

class sfifo_cov extends uvm_component;
  `uvm_component_utils(sfifo_cov)
  
  uvm_analysis_imp_write_cov #(sfifo_txn, sfifo_cov) write_export;
  uvm_analysis_imp_read_cov  #(sfifo_txn, sfifo_cov) read_export;
  
  sfifo_txn txn;
  localparam DEPTH = GLOBAL_DEPTH;

  // FIFO occupancy (sampled from scoreboard or monitor)
  int fifo_level;
 
  covergroup fifo_cg;
  //covergroup fifo_cg @(posedge vif.clk);
    option.per_instance = 1;
    
    // Write enable
    wr_en_cp : coverpoint txn.wr_en;
    // Read enable
    rd_en_cp : coverpoint txn.rd_en;
    
    op_cp : coverpoint {txn.wr_en, txn.rd_en}
    {
      bins idle = {2'b00};
      bins write = {2'b10};
      bins read = {2'b01};
      bins readwrite = {2'b11};
    }

    // Full/Empty flags
    full_cp  : coverpoint txn.full;
    empty_cp : coverpoint txn.empty;

    // Data coverage
    wr_data_cp : coverpoint txn.wr_data {
      bins zero = {0};
      bins all_ones = {'1};
      bins others[] = {[1:$]};
      bins alternating1 = {'hAA};
      bins alternating2 = {'h55};
    }
  

    //rd_data_cp : coverpoint txn.rd_data;
    rd_data_cp : coverpoint txn.rd_data {
      bins zero = {0};
      bins all_ones = {'1};
      bins others[] = {[1:$]};
    }

    // FIFO occupancy
    level_cp : coverpoint fifo_level {
      bins empty = {0};
      bins low = {[1:3]};
      bins mid = {[4:11]};
      //bins near_full = {[12:14]};
      bins near_full = {[DEPTH-4:DEPTH-2]};
      //bins full = {15};
      bins full = {DEPTH-1};
    }
    
    // Cross coverage
    /*wr_full_cross : cross wr_en_cp, full_cp;
    rd_empty_cross : cross rd_en_cp, empty_cp;*/
    
    //cross coverage
    op_full_cross : cross op_cp, full_cp;
    op_empty_cross : cross op_cp, empty_cp;
    
    //Occupancy Cross
    op_level_cross : cross op_cp, level_cp;

  endgroup
  
    
  function new(string name="sfifo_cov", uvm_component parent);
    super.new(name, parent);
    // Instantiate your covergroup here
    fifo_cg = new();
  endfunction
  
   virtual ip_blk_if vif;
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    write_export = new("write_export", this);
    read_export  = new("read_export", this);
    
    //uvm_config_db to get the rst from tb_top
    if(!uvm_config_db #(virtual ip_blk_if )::get(this,"","vif",vif)) begin
      `uvm_fatal("no-vif","fails to get vif in cov collector")
    end
  endfunction

    // Callback functions mapped from the macros
  virtual function void write_write_cov(sfifo_txn t);
    // Sample your write coverpoint configurations here
    txn = t;
    
      if(vif.mon_cb.rst) begin
        fifo_level = 0;
      end
    
    if(t.wr_en && !t.full)
      fifo_level++;
    fifo_cg.sample();
  endfunction
    
  virtual function void write_read_cov(sfifo_txn t);
    // Sample your read coverpoint configurations here
    txn = t;
    
    if(vif.mon_cb.rst) begin
        fifo_level = 0;
      end
    
    if(t.rd_en && !t.empty && fifo_level > 0)
      fifo_level--;
    fifo_cg.sample();
  endfunction
  
  //Report phase
  
/*function void report_phase(uvm_phase phase);

  `uvm_info(
    "COVERAGE",
    $sformatf(
      "Total Coverage = %0.2f%%",
      fifo_cg.get_inst_coverage()
    ),
    UVM_LOW
  );

endfunction*/
  function void report_phase(uvm_phase phase);

  real cov_pct;

  cov_pct = fifo_cg.get_inst_coverage();

  `uvm_info(
    "COVERAGE",
    $sformatf(
      "\n===== FIFO COVERAGE REPORT =====\nCoverage = %0.2f%%\n===============================",
      cov_pct
    ),
    UVM_LOW
  );

endfunction
  
endclass
