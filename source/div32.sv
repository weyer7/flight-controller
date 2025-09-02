`default_nettype none

module div32 #(
  parameter int F = 0 //fractional bits
)(
  input logic clk, nrst, en, start,
  input logic [31:0] dividend, divisor, //signed 32-bit integer
  output logic [31:0] quotient, remainder, //signed 32-bit integer
  output logic done
  // output logic [30:0] a, q, a_next, q_next, //debug
  // output logic [4:0] count, count_next,
  // output logic [1:0] state, state_next,
  // output logic [30:0] apm, amm,
  // output logic q0T, q0F,
  // output logic [30:0] shift
);
  logic [30:0] a, q, a_next, q_next;
  logic [31:0] quotient_next;
  logic [4:0] count, count_next;
  logic [1:0] state, state_next;
  logic [30:0] amm; //a-m
  logic [30:0] apm; //a+m
  logic q0T, q0F;
  logic [30:0] shift;
  logic [31:0] remainder_next;
  logic [31:0] divisor_d, divisor_q, dividend_d, dividend_q;

  typedef enum logic [1:0] {
    IDLE = 2'b0,
    START = 2'd1,
    RUN = 2'd2,
    DONE = 2'd3
  } state_t;

  always @(*) begin
    done = 0;
    a_next = a;
    q_next = q;
    state_next = state;
    count_next = count;
    remainder_next = remainder;
    quotient_next = quotient;
    apm = 31'b0;
    amm = 31'b0;
    q0T = 1'b0;
    q0F = 1'b0;
    shift = 31'b0;
    dividend_d = dividend_q;
    divisor_d = divisor_q;
    case (state)
      IDLE: begin
        if (start) begin
          state_next = START;
          q_next = dividend[30:0] << F;
          dividend_d = dividend[30:0] << F;
          divisor_d = divisor;
          a_next = 31'b0;
        end else begin
          state_next = IDLE;
        end
      end
      START: begin
        count_next = 5'b0;
        state_next = RUN;
        a_next = 0;
      end
      RUN: begin

        if (count == 5'd31) begin
          state_next = DONE;
          a_next = a;
          q_next = q;
        end else begin
          state_next = RUN;
          shift = {a[29:0], q[30]};
          apm = shift + divisor_q[30:0];
          amm = shift + $signed(~divisor_q[30:0] + 1'b1);

          // apm = {a[29:0], q[30]} + ({divisor[30:0]});
          // amm = {a[29:0], q[30]} + (~divisor[30:0] + 1'b1);
          q0T = $signed(apm) < 0 ? 1'b0 : 1'b1;
          q0F = $signed(amm) < 0 ? 1'b0: 1'b1;
          if ($signed(a) < 0) begin
            a_next = apm; //shift AQ left, with new a = a + m
            q_next = {q[29:0], q0T};
          end else begin
            a_next = amm; //shift AQ left, with new a = a - m
            q_next = {q[29:0], q0F};
          end
            count_next = count + 1'b1;
        end
      end
      DONE: begin
        if ($signed(a) < 0) begin
          remainder_next = {1'b0, a + divisor_q[30:0]};
        end else begin
          remainder_next = {1'b0, a};
        end
        a_next = a;
        q_next = q;
        state_next = IDLE;
        done = 1'b1;
        count_next = 5'b0;
        quotient_next = {divisor_q[31]^dividend_q[31], q};
      end
    endcase
  end

  always_ff @(posedge clk, negedge nrst) begin
    if (~nrst) begin
      //reset values here
      a <= 0;
      q <= 0;
      count <= 0;
      state <= 0;
      quotient <= 0;
      divisor_q <= '0;
      remainder <= 0;
      dividend_q <= '0;
    end else if (en) begin
      //begin normal function
      a <= a_next;
      q <= q_next;
      count <= count_next;
      state <= state_next;
      quotient <= quotient_next;
      divisor_q <= divisor_d;
      remainder <= remainder_next;
      dividend_q <= dividend_d;
    end
  end
endmodule
