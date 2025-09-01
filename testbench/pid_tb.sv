`timescale 1ms/10ns

  function automatic signed [31:0] signmag_to_twos (
    input logic [31:0] signmag
  );
    logic sign;
    logic [30:0] magnitude;

    begin
      sign = signmag[31];
      magnitude = signmag[30:0];
      if (sign)
        signmag_to_twos = -$signed({1'b0, magnitude}); // negate magnitude
      else
        signmag_to_twos = $signed({1'b0, magnitude});  // positive
    end
  endfunction

module pid_tb;
  logic clk, en, nrst;
  logic start_calc;
  logic [31:0] error, Kp, Ki, Kd, delta_t, PID_out;
  logic done;

  logic [31:0] setpoint, position, position_new, error_new, p, i, d;
  int pid_out, err, sp, pos;
  assign pid_out = signmag_to_twos(PID_out);
  assign err = signmag_to_twos(error);
  assign sp = signmag_to_twos(setpoint);
  assign pos = signmag_to_twos(position);
  pid dut (
    .*
  );

  always begin
    #1;
    clk = ~clk;
  end
  add32 add0 (
    .num1(position), .num2({PID_out[31], PID_out[30:0] >> 5}),
    .sum(position_new), .overflow()
  );
  add32 add1 (
    .num1(setpoint), .num2({!position[31], position[30:0]}),
    .sum(error_new), .overflow()
  );
  initial begin
    // make sure to dump the signals so we can see them in the waveform
    $dumpfile("waves/pid.vcd"); //change the vcd vile name to your source file name
    $dumpvars(0, pid_tb);
    clk = 0;
    nrst = 0;
    start_calc = 0;
    en = 1;
    Kp = 10; Ki = 1; Kd = 1;
    delta_t = 1;
    position = 5000;
    setpoint = {1'b1, 31'd900000};
    #1
    error = error_new;
    
    #5
    nrst = 1;
    #5
    @(negedge clk);
    start_calc = 1;
    @(negedge clk);
    start_calc = 0;
    @(posedge done);
    for (int i = 0; i < 500; i ++) begin
      @(negedge clk);
      start_calc = 1;
      @(negedge clk);
      start_calc = 0;
      @(posedge done);
      position = position_new;
      error = error_new;
    end
    #500;
    // finish the simulation
    $finish;
  end
endmodule