module csa24(
    input logic [23:0] a,
    input logic [23:0] b,
    output logic [47:0] sum
);

logic [26:0] carry_layer_1 [0:7]
logic [25:0] sum_layer_1 [0:7];

genvar i1;
generate
    for (i1 = 0; i1 < 8; i1 = i1 + 1) begin : csg_modules1
        carry_sum_generator csg_inst(
            .a(b[i1 * 3] ? a : 24'b0), 
            .b(b[i1 * 3 + 1] ? a : 24'b0), 
            .carry_in(b[i1 * 3 + 2] ? a : 24'b0),
            .sum(sum_layer_1[i1]),
            .carry_out(carry_layer_1[i1])
        );
    end
endgenerate

genvar i2;
generate
    for (i2 = 0; i2 < 5; i2 = i2 + 1) begin : csg_modules2
        carry_sum_generator csg_inst(
            .a(),
            .b(),
            .carry_in(),
            .sum(),
            .carry_out()
        );
    end
endgenerate

endmodule

module carry_sum_generator #(n = 24) (
    input logic [n - 1:0] a,
    input logic [n - 1:0] b,
    input logic [n - 1:0] carry_in
    output logic [n + 1:0] sum,
    output logic [n + 2:0] carry_out
);

logic [n + 1:0] padded_a, padded_b, padded_carry_in, xor_result;
assign padded_a = {2'b0, a};
assign padded_b = {1'b0, b, 1'b0};
assign padded_carry_in = {carry_in, 2'b0};

assign xor_result = padded_a ^ padded_b;
assign sum = xor_result ^ padded_carry_in;
assign carry_out = {(padded_a & padded_b) | (xor_result & padded_carry_in), 1'b0};

endmodule