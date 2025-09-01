module acc32 (
  input logic clk, en, nrst,
  input logic accumulate,
  input logic [31:0] in,
  output logic [31:0] out,
  output logic overflow
);
  logic [31:0] sum, sum_d, sum_q; //oversized internal accumulator
  always_ff @(posedge clk, negedge nrst) begin
    if (~nrst) begin
      sum_q <= '0;
    end else if (en) begin
      sum_q <= sum_d;
    end
  end

  always_comb begin
    sum_d = sum_q;
    if (accumulate) begin //only update with accumulate pulse
      sum_d = sum; //sum = sum_q + in
    end
  end

  add32 #(
    .BIT_DEPTH(32)
  ) add0 (
    .num1(in), .num2(sum_q),
    .sum(sum), .overflow(overflow)
  );

  assign out = sum_q;
endmodule
