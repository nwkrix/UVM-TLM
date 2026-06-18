module axi_lite_sub #(
// prototocol-aware axi4-lite
    parameter ADDR_WIDTH = 4,
    parameter DATA_WIDTH = 32
)(
    input  logic                     ACLK,
    input  logic                     ARESETn,

    // Write Address Channel (AW*)
    input  logic [ADDR_WIDTH-1:0]    AWADDR,  // addr to be written to
    input  logic                     AWVALID, // manager asserts when AWADDR is valid/stable
    output logic                     AWREADY, // sub asserts when ready to accept AWADDR

    // Write Data Channel (W*)
    input  logic [DATA_WIDTH-1:0]    WDATA,  // write-data to be sent by manager to sub
    input  logic                     WVALID, // write-valid, manager asserts
    output logic                     WREADY, // write-ready, sub asserts

    // Write Response (B*)
    output logic [1:0]               BRESP,   // protocol-aware response
    output logic                     BVALID,  // sub asserts after successful write
    input  logic                     BREADY,  // manager asserts when ready to receive BVALID
    // after BVALID && BREADY === 1, sub clear BVALID

    // Read Address Channel (AR*)
    input  logic [ADDR_WIDTH-1:0]    ARADDR,   // addr the manager wants to read from
    input  logic                     ARVALID,  // manager asserts ARVALID when ARADDR is valid
    output logic                     ARREADY,  // sub asserts ARREADY when ready to accept ARADDR and ARVALID=1

    // Read Data Channel (R*)
    output logic [DATA_WIDTH-1:0]    RDATA,   // read-data returned by sub
  	output logic [1:0]               RRESP,   // protocol-aware response
    output logic                     RVALID, // read-valid asserted by sub when RDATA is valid
    input  logic                     RREADY  // read-ready asserted by manager when ready to accept RDATA
);

    // Simple 4-entry register file
    logic [DATA_WIDTH-1:0] regfile [0:3];

    // Internal storage for write handshake
    logic [ADDR_WIDTH-1:0] awaddr_reg;
    logic                  aw_captured;
    logic [DATA_WIDTH-1:0] wdata_reg;
    logic                  w_captured;

    // Internal storage for read handshake
    logic [ADDR_WIDTH-1:0] araddr_reg;
    logic                  ar_captured;

    // Optional: response enum for readability
    typedef enum bit [1:0] {
      AXI_OKAY   = 2'b00,
      AXI_EXOKAY = 2'b01,
      AXI_SLVERR = 2'b10,
      AXI_DECERR = 2'b11
    } axi_resp_e;

    // -----------------------------
    // WRITE LOGIC
    // -----------------------------
    always_ff @(posedge ACLK) begin
        if (!ARESETn) begin
            AWREADY     <= 1'b0;
            WREADY      <= 1'b0;
            BVALID      <= 1'b0;
            BRESP       <= AXI_OKAY;
            aw_captured <= 1'b0;
            w_captured  <= 1'b0;
            awaddr_reg  <= '0;
            wdata_reg   <= '0;
        end
        else begin
            // Ready to accept new address/data when nothing captured
            AWREADY <= !aw_captured;
            WREADY  <= !w_captured;

            // Address handshake
            if (AWVALID && AWREADY) begin
                awaddr_reg  <= AWADDR;
                aw_captured <= 1'b1;
            end

            // Data handshake
            if (WVALID && WREADY) begin
                wdata_reg  <= WDATA;
                w_captured <= 1'b1;
            end

            // Execute write once both address and data are captured
            if (aw_captured && w_captured && !BVALID) begin
                // Address decode: only allow 0x0, 0x4, 0x8, 0xC
                if (awaddr_reg inside {4'h0, 4'h4, 4'h8, 4'hC}) begin
                    regfile[awaddr_reg[3:2]] <= wdata_reg;
                    BRESP <= AXI_OKAY;
                end
                else begin
                    // Invalid address: no write, report DECERR
                    BRESP <= AXI_DECERR;
                end

                BVALID <= 1'b1;
            end

            // Response handshake: manager accepts BRESP
            if (BVALID && BREADY) begin
                BVALID      <= 1'b0;
                aw_captured <= 1'b0;
                w_captured  <= 1'b0;
            end
        end
    end

    // -----------------------------
    // READ LOGIC
    // -----------------------------
    always_ff @(posedge ACLK) begin
        if (!ARESETn) begin
            ARREADY     <= 1'b0;
            RVALID      <= 1'b0;
            RDATA       <= '0;
            RRESP       <= AXI_OKAY;
            ar_captured <= 1'b0;
            araddr_reg  <= '0;
        end
        else begin
            // Ready for new read request when nothing captured and no pending data
            ARREADY <= !ar_captured && !RVALID;

            // Capture read address
            if (ARVALID && ARREADY) begin
                araddr_reg  <= ARADDR;
                ar_captured <= 1'b1;
            end

            // Perform read once address captured and no data pending
            if (ar_captured && !RVALID) begin
                if (araddr_reg inside {4'h0, 4'h4, 4'h8, 4'hC}) begin
                    RDATA <= regfile[araddr_reg[3:2]];
                    RRESP <= AXI_OKAY;
                end
                else begin
                    // Invalid address: return zero and DECERR
                    RDATA <= '0;
                    RRESP <= AXI_DECERR;
                end

                RVALID <= 1'b1;
            end

            // Read response handshake
            if (RVALID && RREADY) begin
                RVALID      <= 1'b0;
                ar_captured <= 1'b0;
            end
        end
    end

endmodule