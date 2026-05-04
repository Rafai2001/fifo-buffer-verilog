// ============================================================
// Testbench for FIFO Buffer
// Tests: Reset, Write, Read, Full condition, Empty condition,
//        Simultaneous Read/Write, Overflow protection,
//        Underflow protection
// ============================================================

`timescale 1ns/1ps

module fifo_buffer_tb;

    // Parameters
    parameter DATA_WIDTH = 8;
    parameter FIFO_DEPTH = 8;
    parameter ADDR_WIDTH = 3;

    // DUT signals
    reg                  clk;
    reg                  rst;
    reg                  wr_en;
    reg                  rd_en;
    reg  [DATA_WIDTH-1:0] din;
    wire [DATA_WIDTH-1:0] dout;
    wire                  full;
    wire                  empty;

    // Test tracking
    integer pass_count = 0;
    integer fail_count = 0;

    // Instantiate Device Under Test (DUT)
    fifo_buffer #(
        .DATA_WIDTH(DATA_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .clk   (clk),
        .rst   (rst),
        .wr_en (wr_en),
        .rd_en (rd_en),
        .din   (din),
        .dout  (dout),
        .full  (full),
        .empty (empty)
    );

    // Clock generation: 10ns period (100 MHz)
    initial clk = 0;
    always #5 clk = ~clk;

    // Task: Write a value into FIFO
    task fifo_write;
        input [DATA_WIDTH-1:0] data;
        begin
            @(negedge clk);
            wr_en = 1;
            rd_en = 0;
            din   = data;
            @(posedge clk);
            #1;
            $display("[WRITE] din=%0d | full=%b empty=%b", data, full, empty);
            wr_en = 0;
        end
    endtask

    // Task: Read a value from FIFO
    task fifo_read;
        begin
            @(negedge clk);
            rd_en = 1;
            wr_en = 0;
            @(posedge clk);
            #1;
            $display("[READ ] dout=%0d | full=%b empty=%b", dout, full, empty);
            rd_en = 0;
        end
    endtask

    // Main test sequence
    initial begin
        // Setup waveform dump for GtkWave
        $dumpfile("fifo_buffer.vcd");
        $dumpvars(0, fifo_buffer_tb);

        // Initialize signals
        rst   = 1;
        wr_en = 0;
        rd_en = 0;
        din   = 0;

        // ----------------------------------------
        // TEST 1: Reset
        // ----------------------------------------
        $display("\n=== TEST 1: Reset ===");
        @(posedge clk); #1;
        @(posedge clk); #1;
        rst = 0;
        @(posedge clk); #1;
        if (empty == 1 && full == 0)
            $display("PASS: After reset, FIFO is empty");
        else
            $display("FAIL: Reset state incorrect");

        // ----------------------------------------
        // TEST 2: Write 4 values (partial fill)
        // ----------------------------------------
        $display("\n=== TEST 2: Write 4 Values ===");
        fifo_write(8'hAA);  // 170
        fifo_write(8'hBB);  // 187
        fifo_write(8'hCC);  // 204
        fifo_write(8'hDD);  // 221
        if (empty == 0 && full == 0)
            $display("PASS: FIFO partially filled (not empty, not full)");
        else
            $display("FAIL: Partial fill flag error");

        // ----------------------------------------
        // TEST 3: Fill FIFO completely
        // ----------------------------------------
        $display("\n=== TEST 3: Fill FIFO to Full ===");
        fifo_write(8'h11);
        fifo_write(8'h22);
        fifo_write(8'h33);
        fifo_write(8'h44);
        if (full == 1)
            $display("PASS: FIFO is full after 8 writes");
        else
            $display("FAIL: Full flag not set");

        // ----------------------------------------
        // TEST 4: Overflow protection
        // ----------------------------------------
        $display("\n=== TEST 4: Overflow Protection ===");
        fifo_write(8'hFF); // Should be ignored (FIFO full)
        if (full == 1)
            $display("PASS: Overflow protected, FIFO still full");
        else
            $display("FAIL: Overflow caused data corruption");

        // ----------------------------------------
        // TEST 5: Read all values (check FIFO order)
        // ----------------------------------------
        $display("\n=== TEST 5: Read All Values (FIFO Order) ===");
        fifo_read(); // Expect AA
        fifo_read(); // Expect BB
        fifo_read(); // Expect CC
        fifo_read(); // Expect DD
        fifo_read(); // Expect 11
        fifo_read(); // Expect 22
        fifo_read(); // Expect 33
        fifo_read(); // Expect 44

        // ----------------------------------------
        // TEST 6: Empty flag after draining
        // ----------------------------------------
        $display("\n=== TEST 6: Empty Flag After Drain ===");
        if (empty == 1)
            $display("PASS: FIFO is empty after reading all data");
        else
            $display("FAIL: Empty flag not set");

        // ----------------------------------------
        // TEST 7: Underflow protection
        // ----------------------------------------
        $display("\n=== TEST 7: Underflow Protection ===");
        fifo_read(); // Should be ignored (FIFO empty)
        if (empty == 1)
            $display("PASS: Underflow protected, FIFO still empty");
        else
            $display("FAIL: Underflow caused issue");

        // ----------------------------------------
        // TEST 8: Simultaneous Read and Write
        // ----------------------------------------
        $display("\n=== TEST 8: Simultaneous Read/Write ===");
        fifo_write(8'h55);
        fifo_write(8'h66);
        @(negedge clk);
        wr_en = 1;
        rd_en = 1;
        din   = 8'h77;
        @(posedge clk); #1;
        $display("[SIM R/W] din=%0d dout=%0d full=%b empty=%b", din, dout, full, empty);
        wr_en = 0;
        rd_en = 0;

        // ----------------------------------------
        // TEST 9: Reset mid-operation
        // ----------------------------------------
        $display("\n=== TEST 9: Reset Mid-Operation ===");
        fifo_write(8'hAB);
        fifo_write(8'hCD);
        rst = 1;
        @(posedge clk); #1;
        rst = 0;
        @(posedge clk); #1;
        if (empty == 1 && full == 0)
            $display("PASS: FIFO correctly reset mid-operation");
        else
            $display("FAIL: Reset mid-operation failed");

        $display("\n=== ALL TESTS COMPLETE ===\n");
        #20;
        $finish;
    end

endmodule
