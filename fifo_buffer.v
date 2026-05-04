// ============================================================
// FIFO Buffer - Synchronous First-In First-Out Memory
// Depth: 8 locations, Width: 8 bits
// Features: Full flag, Empty flag, Push (write), Pop (read)
// ============================================================

module fifo_buffer #(
    parameter DATA_WIDTH = 8,   // Width of each data word
    parameter FIFO_DEPTH = 8,   // Number of storage locations
    parameter ADDR_WIDTH = 3    // log2(FIFO_DEPTH)
)(
    input  wire                  clk,     // Clock signal
    input  wire                  rst,     // Synchronous reset (active high)
    input  wire                  wr_en,   // Write enable (push)
    input  wire                  rd_en,   // Read enable (pop)
    input  wire [DATA_WIDTH-1:0] din,     // Data input
    output reg  [DATA_WIDTH-1:0] dout,    // Data output
    output wire                  full,    // FIFO full flag
    output wire                  empty    // FIFO empty flag
);

    // Internal memory array
    reg [DATA_WIDTH-1:0] mem [0:FIFO_DEPTH-1];

    // Read and write pointers
    reg [ADDR_WIDTH:0] wr_ptr;  // Extra bit for full/empty detection
    reg [ADDR_WIDTH:0] rd_ptr;

    // Full and Empty flag logic
    // Full:  pointers differ only in MSB (wrapped around)
    // Empty: pointers are equal
    assign full  = (wr_ptr[ADDR_WIDTH-1:0] == rd_ptr[ADDR_WIDTH-1:0]) &&
                   (wr_ptr[ADDR_WIDTH] != rd_ptr[ADDR_WIDTH]);
    assign empty = (wr_ptr == rd_ptr);

    // Write operation
    always @(posedge clk) begin
        if (rst) begin
            wr_ptr <= 0;
        end else if (wr_en && !full) begin
            mem[wr_ptr[ADDR_WIDTH-1:0]] <= din;
            wr_ptr <= wr_ptr + 1;
        end
    end

    // Read operation
    always @(posedge clk) begin
        if (rst) begin
            rd_ptr <= 0;
            dout   <= 0;
        end else if (rd_en && !empty) begin
            dout   <= mem[rd_ptr[ADDR_WIDTH-1:0]];
            rd_ptr <= rd_ptr + 1;
        end
    end

endmodule
