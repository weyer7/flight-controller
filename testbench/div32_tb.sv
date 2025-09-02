`timescale 1ms/10ps
`default_nettype none

module div32_tb();

  initial begin
    $dumpfile("waves/div32.vcd");  // Specify your desired file path
    $dumpvars(0, div32_tb); // Dumps all signals in this module
  end
  // Testbench Signals
  logic clk;
  logic nrst, en;
  logic start;
  logic [31:0] dividend, divisor;
  logic [31:0] quotient; //, quotient_next;
  logic [31:0] remainder;
  logic done;
// 	logic [30:0] a, q, a_next, q_next;
//   logic [4:0] count, count_next;
//   logic [1:0] state, state_next;
// 	logic [30:0] apm, amm;
// 	logic q0T, q0F;
// 	logic [30:0] shift;

  // Clock generation
  localparam CLK_PERIOD = 10;
  always begin
    clk = 0;
    #(CLK_PERIOD / 2);
    clk = 1;
    #(CLK_PERIOD / 2);
  end

  always begin
    #10000;
    $finish;
  end

  // DUT instance
  div32 dut (
    .*
  );

  // Test sequence
  initial begin

    // Initialize inputs
    nrst = 0;
    start = 0;
    dividend = 0;
    divisor = 0;
		en = 1;
    #(CLK_PERIOD * 2);

    // Release reset
    nrst = 1;
    #(CLK_PERIOD);
    
    // Test case 0.5: 46/23
    dividend = 46;
    divisor = 23;
    start = 1;
    #(CLK_PERIOD);
    start = 0;
    wait (done);
    // Test case 1: 1000 / 25
    dividend = 1000;
    divisor = 25;
    @(negedge clk);
    @(negedge clk);
    $display("1000 / 25: Quotient = %0d, Remainder = %0d", quotient, remainder);
    start = 1;
    #(CLK_PERIOD);
    start = 0;
    #(CLK_PERIOD);
    wait (done);
    #(CLK_PERIOD);
    
    // Test case 2: 500 / 7
    dividend = 500;
    divisor = 7;
    start = 1;
    @(negedge clk);
    @(negedge clk);
    $display("1000 / 25: Quotient = %0d, Remainder = %0d", quotient, remainder);

    start = 0;
    #(CLK_PERIOD);
    wait (done);
    #(CLK_PERIOD);
    
    // Test case 3: 31-bit large number division
    dividend = 32'h3FFFFFFF;
    divisor = 12345;
    start = 1;
    @(negedge clk);
    @(negedge clk);
    $display("500 / 7: Quotient = %0d, Remainder = %0d", quotient, remainder);

    start = 0;
    #(CLK_PERIOD);
    wait (done);
    @(negedge clk);
    @(negedge clk)
    $display("(3FFFFFFF) / 12345: Quotient = %0d, Remainder = %0d", quotient, remainder);
    #(CLK_PERIOD);
    
    // End simulation
    $finish;
  end

  // initial begin
  //   $dumpfile("waves/div32_wave.vcd");  // Specify your desired file path
  //   $dumpvars(0, div32_tb); // Dumps all signals in this module
  // end

endmodule
