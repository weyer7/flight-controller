`default_nettype none
//invert each bit and add 1 for two's compliment (+ve to -ve)
module add32 #(
  parameter
    BIT_DEPTH = 32
)(
  input logic [BIT_DEPTH - 1:0] num1,num2, //two standard signed integers (not two's compliment)
  output logic [BIT_DEPTH - 1:0] sum, //standard signed integer (not two's compliment)
  output logic overflow
);
  logic [BIT_DEPTH - 1:0] com1, com2, sum_com;
  always @(*) begin

    //logic to convirt signed integers to two's compliment
    if (num1[BIT_DEPTH - 1] && num1[BIT_DEPTH - 2:0] != '0) begin
      com1 = {1'b1, ~num1[BIT_DEPTH - 2:0] + 1'b1};
    end else begin
      com1 = {1'b0, num1[BIT_DEPTH - 2:0]};
    end
    if (num2[BIT_DEPTH - 1] && num2[BIT_DEPTH - 2:0] != '0) begin
      com2 = {1'b1, ~num2[BIT_DEPTH - 2:0] + 1'b1};
    end else begin
      com2 = {1'b0, num2[BIT_DEPTH - 2:0]};
    end

    sum_com = com1 + com2; //add the two numbers

    //convert to signed integer (not two's compliment)
    if (sum_com[BIT_DEPTH - 1]) begin
      sum = {1'b1, ~(sum_com[BIT_DEPTH - 2:0] - 1'b1)}; 
    end else begin
      sum = {1'b0, sum_com[BIT_DEPTH - 2:0]};
    end

    overflow = (com1[BIT_DEPTH - 1]^com2[BIT_DEPTH - 1] ? 0 : 
    com1[BIT_DEPTH - 1]^sum_com[BIT_DEPTH - 1]) || 
    (num1 == ('b11 << (BIT_DEPTH - 2)) && num2 == ('b11 << (BIT_DEPTH - 2))); //check for signed overflow
  end

endmodule