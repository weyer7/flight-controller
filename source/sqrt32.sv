`default_nettype none
module sqrt_fxp #(
    parameter WIDTH = 32,
    parameter FRAC_BITS = 16
)(
    input  logic clk,
    input  logic start,
    input  logic [WIDTH-1:0] rad,   // Qm.n input
    output logic done,
    output logic valid,
    output logic [WIDTH-1:0] root   // Qm.n output
);


	logic [WIDTH-1:0] x, x_next;    // radicand copy
	logic [WIDTH-1:0] q, q_next;    // intermediate root (quotient)
	logic [WIDTH+1:0] ac, ac_next;  // accumulator (2 bits wider)
	logic [WIDTH+1:0] test_res;     // sign test result (2 bits wider)
	logic valid_next;

	localparam ITER = WIDTH >> 1;   // iterations are half radicand width
	logic [$clog2(ITER)+1:0] i;     // iteration counter

	always_comb begin
		if (sign == 0) begin
			valid_next = 1'd1;
			test_res = ac - {q, 2'b01};
			if (test_res[WIDTH+1] == 0) begin  // test_res ≥0? (check MSB)
				{ac_next, x_next} = {test_res[WIDTH-1:0], x, 2'b0};
				q_next = {q[WIDTH-2:0], 1'b1};
			end else begin
				{ac_next, x_next} = {ac[WIDTH-1:0], x, 2'b0};
				q_next = q << 1;
			end
		end else begin
			q_next = 0;
			test_res = 0;
			ac_next = 0;
			x_next = 0;
			valid_next = 1'd0;
		end
	end

	always_ff @(posedge clk) begin
		if (start) begin
			done <= 0;
			i <= 0;
			q <= 0;
            // Align radicand for fixed-point scaling
            {ac, x} <= {{WIDTH{1'b0}}, rad << FRAC_BITS, 2'b0};

		end else if (~done) begin
			if ({i} == ITER-1) begin  // we're done
				done <= 1;
				root <= q_next;
				rem <= ac_next[WIDTH+1:2];  // undo final shift
				valid <= valid_next;
			end else begin  // next iteration
				i <= i + 1;
				x <= x_next;
				ac <= ac_next;
				q <= q_next;
			end
		end
	end
endmodule