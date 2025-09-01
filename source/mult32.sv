`default_nettype none

module mult32 (
  input  logic [31:0] num1, num2, //signed 32-bit integer
  input  logic        clk, en, nrst, start,
  output logic [31:0] product, //signed 32-bit integer
  output logic        done, overflow

);

  logic [30:0] a_d, a_q, b_d, b_q;           //register versions of inputs
  logic [63:0] result_d, result_q;         //64-bit result accumulator
  logic [4:0] step_d, step_q;            //iteration step counter
  logic s1_d, s1_q, s2_d, s2_q;                //sign of each number
  logic [31:0] product_d, product_q;
  logic [1:0] state_d, state_q;
  logic overflow_d, overflow_q;
  assign overflow = overflow_q;
  assign product = product_d;


  typedef enum logic [1:0] {
    IDLE = 2'b0,
    START = 2'd1,
    RUN = 2'd2,
    DONE = 2'd3
  } state_t;

  always_ff @(posedge clk, negedge nrst) begin
    if (~nrst) begin
      state_q <= IDLE;
      result_q <= '0;
      step_q <= '0;
      product_q <= '0;
      overflow_q <= '0;
      s1_q <= '0;
      s2_q <= '0;
      a_q <= '0;
      b_q <= '0;
    end else if (en) begin
      state_q <= state_d;
      result_q <= result_d;
      step_q <= step_d;
      product_q <= product_d;
      overflow_q <= overflow_d;
      s1_q <= s1_d;
      s2_q <= s2_d;
      a_q <= a_d;
      b_q <= b_d;
    end
  end

  always @(*) begin
    state_d = state_q;
    result_d = result_q;
    step_d = step_q;
    done = 0;
    product_d = product_q;
    overflow_d = overflow_q;
    s1_d = s1_q;
    s2_d = s2_q;
    a_d = a_q;
    b_d = b_q;
    case (state_q)
      IDLE: begin
        if (start) begin
          state_d = START;
        end
      end
      START: begin
        s1_d     = num1[31];
        s2_d     = num2[31];
        a_d      = num1[30:0];
        b_d      = num2[30:0];
        result_d = 0;
        step_d   = 0;
        state_d = RUN;
      end
      RUN: begin
        if (step_q < 31) begin
          if (b_q[step_q]) begin
            result_d = result_q + ({33'b0,a_q} << step_q);
          end
          step_d = step_q + 1;
        end else begin
          done = 1;
          product_d = {s1_q^s2_q, result_q[30:0]};
          overflow_d = |result_q[63:32];
          state_d = IDLE;
        end
      end
      DONE: begin

      end
    endcase
    // done = 1;
  end
endmodule