module pid (
  input logic clk, en, nrst, //clock, enable, negative edge reset
  input logic [31:0] error, //difference between setpoint and process variable (cleaned)
  input logic [31:0] Kp, Ki, Kd, //proportional, integral, and derivative constants
  input logic start_calc, //begin single frame PID calculation
  input logic [31:0] delta_t, //time between current and previous start signal
  output logic [31:0] PID_out, //control output
  output logic done //PID calculation done
);
  logic [31:0] proportional, integral, derivative, //P,I,D results
    quotient_d, acc_out, rate, sum_i, sum1, sum1_q, sum1_d, sum2, sum2_d, sum2_q; //intermediate signals
  logic overflow_p, overflow_i, overflow_d; //overflow signals
  logic pid_done, done_p, done_i, done_d, //P,I,D done signals
    div_done_d, acc_done, delayed_pid_done; //intermediate done signals
  logic [31:0] error_last; //last error value
  logic [1:0]delayed_start; //single clock speed behind start

  always_ff @(posedge clk, nrst) begin
    if (~nrst) begin
      delayed_start <= '0;
    end else if (en) begin
      delayed_start <= {delayed_start[0], start_calc};
    end
  end

  //proportional (P)
  mult32 mult0 (
    .clk(clk), .en(en), .nrst(nrst),
    .num1(Kp), .num2(error),
    .start(start_calc), .done(done_p), .overflow(overflow_p), .product(proportional)
  );

  //integral (I)
  // add32 add0 (
  //   .num1(error), .num2(acc_out),
  //   .sum(sum_i), .overflow()
  // );
  acc32 acc0 (
    .clk(clk), .en(en), .nrst(nrst),
    .in(error), .accumulate(start_calc),
    .out(acc_out), .overflow()
  );
  mult32 mult1(
    .clk(clk), .en(en), .nrst(nrst),
    .num1(acc_out), .num2(Ki),
    .start(delayed_start[1]), .done(done_i), .overflow(overflow_i), .product(integral)
  );
  
  //derivative (D)
  always_ff @(posedge clk, negedge nrst) begin
    if (~nrst) begin
      error_last <= '0;
    end else if (en && start_calc) begin
      error_last <= error;
    end
  end
  add32 add1(
    .num1(error), .num2({error_last[31], error_last[30:0]}), //current-last
    .sum(rate), .overflow()
  );
  div32 div0 (
    .clk(clk), .en(en), .nrst(nrst), 
    .start(start_calc),
    .dividend(rate), .divisor(delta_t),
    .quotient(quotient_d), .remainder(), .done(div_done_d)
  );
  mult32 mult2 (
    .clk(clk), .en(en), .nrst(nrst),
    .num1(Kd), .num2(quotient_d),
    .start(div_done_d), .done(done_d), .overflow(overflow_d), .product(derivative)
  );

  //Adding together

  add32 add2 (
    .num1(proportional), .num2(integral),
    .sum(sum1), .overflow()
  );
  add32 add3 (
    .num1(sum1), .num2(derivative),
    .sum(sum2), .overflow()
  );
  //pipeline reg
  assign pid_done = done_p && done_i && done_d;
  logic [2:0] fin_d, fin_q;
  always_ff @(posedge clk, negedge nrst) begin
    if (~nrst) begin
      fin_q <= '0;
      sum1_q <= '0;
      sum2_q <= '0;
      delayed_pid_done <= 0;
    end else if (en) begin
      fin_q <= fin_d;
      sum1_q <= sum1_d;
      sum2_q <= sum2_d;
      delayed_pid_done <= &fin_q;
    end
  end
  always_comb begin
    sum1_d = sum1_q;
    sum2_d = sum2_q;
    done = 0;
    fin_d = fin_q;

    if (start_calc) begin
      fin_d = '0;
    end else begin
      fin_d[0] = done_p | fin_d[0] ? 1 : 0;
      fin_d[1] = done_i | fin_d[1] ? 1 : 0;
      fin_d[2] = done_d | fin_d[2] ? 1 : 0;
    end
    if (&fin_q) begin
      sum1_d = sum1;
    end
    if (delayed_pid_done && (&fin_q)) begin
      sum2_d = sum2;
      done = 1;
    end
  end
  assign PID_out = sum2_q;
endmodule
