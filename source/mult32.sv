`default_nettype none

module mult32 #(
  parameter int N_IN = 32,   //input bit width
  parameter int N_OUT = 32,  //output bit width
  parameter int F = 0     //number of fractional bits (Q-format)
)(
  input  logic              clk, en, nrst, start,
  input  logic [N_IN-1:0]      num1, num2, // sign-magnitude
  output logic [N_OUT-1:0]    product,    // sign-magnitude
  output logic              done, overflow
);

  //split into sign and magnitude
  logic              s1_d, s1_q, s2_d, s2_q;
  logic [N_IN-2:0]      a_d, a_q, b_d, b_q;
  logic [N_OUT-3:0]    result_d, result_q;

  logic [$clog2(N_IN):0] step_d, step_q;

  logic [N_OUT-1:0]    product_d, product_q;
  logic              overflow_d, overflow_q;
  logic [1:0]        state_d, state_q;

  logic [N_OUT-2:0] scaled;

  assign product  = product_q;
  assign overflow = overflow_q;

  typedef enum logic [1:0] {
    IDLE  = 2'b00,
    RUN   = 2'b01
  } state_t;

  //sequential state register
  always_ff @(posedge clk, negedge nrst) begin
    if (~nrst) begin
      state_q    <= IDLE;
      result_q   <= '0;
      step_q     <= '0;
      product_q  <= '0;
      overflow_q <= '0;
      s1_q <= '0;
      s2_q <= '0;
      a_q  <= '0;
      b_q  <= '0;
    end else if (en) begin
      state_q    <= state_d;
      result_q   <= result_d;
      step_q     <= step_d;
      product_q  <= product_d;
      overflow_q <= overflow_d;
      s1_q <= s1_d;
      s2_q <= s2_d;
      a_q  <= a_d;
      b_q  <= b_d;
    end
  end

  //combinational datapath
  always @(*) begin
    state_d    = state_q;
    result_d   = result_q;
    step_d     = step_q;
    product_d  = product_q;
    overflow_d = overflow_q;
    s1_d       = s1_q;
    s2_d       = s2_q;
    a_d        = a_q;
    b_d        = b_q;
    done       = 0;

    case (state_q)
      IDLE: begin
        if (start) begin
          s1_d     = num1[N_IN-1];
          s2_d     = num2[N_IN-1];
          a_d      = num1[N_IN-2:0];
          b_d      = num2[N_IN-2:0];
          result_d = '0;
          step_d   = '0;
          state_d  = RUN;
        end
      end

      RUN: begin
        if (step_q < N_IN-1) begin
          if (b_q[step_q]) begin
            result_d = result_q + ({{(N_IN-1){1'b0}}, a_q } << step_q);
          end
          step_d = step_q + 1;
        end else begin
          //fixed-point scaling: raw product has 2F fractional bits, rescale
          scaled = result_q >> F; // truncate to F fractional bits

          product_d  = {s1_q ^ s2_q, scaled[N_OUT-2:0]};
          overflow_d = |scaled[N_OUT-2 -: (N_IN-1)];
          done       = 1;
          state_d    = IDLE;
        end
      end
    endcase
  end

endmodule
