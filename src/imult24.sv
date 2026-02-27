module imult24(
    input logic [23:0] a,
    input logic [23:0] b,
    output logic [47:0] sum
);

logic [48:0] output_layer_1 [0:15];
genvar i1;
generate
    for (i1 = 0; i1 < 8; i1 = i1 + 1) begin : csg_modules1
        carry_sum_generator #(.n(48)) csg_inst1 (
            .a({{(24 - i1 * 3){1'b0}}, b[i1 * 3] ? a : 24'b0, {(i1 * 3){1'b0}}}),
            .b({{(23 - i1 * 3){1'b0}}, b[i1 * 3 + 1] ? a : 24'b0, {(i1 * 3 + 1){1'b0}}}),
            .c_in({{(22 - i1 * 3){1'b0}}, b[i1 * 3 + 2] ? a : 24'b0, {(i1 * 3 + 2){1'b0}}}),
            .sum(output_layer_1[i1]),
            .c_out(output_layer_1[i1 + 8])
        );
    end
endgenerate

logic [48:0] output_layer_2 [0:10];
genvar i2;
generate
    for (i2 = 0; i2 < 5; i2 = i2 + 1) begin : csg_modules2
        carry_sum_generator #(.n(48)) csg_inst2 (
            .a(output_layer_1[i2 * 3]),
            .b(output_layer_1[i2 * 3 + 1]),
            .c_in(output_layer_1[i2 * 3 + 2]),
            .sum(output_layer_2[i2]),
            .c_out(output_layer_2[i2 + 5])
        );
    end
endgenerate
assign output_layer_2[10] = output_layer_1[15];

logic [48:0] output_layer_3 [0:7];
genvar i3;
generate
    for (i3 = 0; i3 < 3; i3 = i3 + 1) begin : csg_modules3
        carry_sum_generator #(.n(48)) csg_inst3 (
            .a(output_layer_2[i3 * 3]),
            .b(output_layer_2[i3 * 3 + 1]),
            .c_in(output_layer_2[i3 * 3 + 2]),
            .sum(output_layer_3[i3]),
            .c_out(output_layer_3[i3 + 3])
        );
    end
endgenerate
assign output_layer_3[6] = output_layer_2[9];
assign output_layer_3[7] = output_layer_2[10];

logic [48:0] output_layer_4 [0:5];
genvar i4;
generate
    for (i4 = 0; i4 < 2; i4 = i4 + 1) begin : csg_modules4
        carry_sum_generator #(.n(48)) csg_inst4 (
            .a(output_layer_3[i4 * 3]),
            .b(output_layer_3[i4 * 3 + 1]),
            .c_in(output_layer_3[i4 * 3 + 2]),
            .sum(output_layer_4[i4]),
            .c_out(output_layer_4[i4 + 2])
        );
    end
endgenerate
assign output_layer_4[4] = output_layer_3[6];
assign output_layer_4[5] = output_layer_3[7];

logic [48:0] output_layer_5 [0:3];
genvar i5;
generate
    for (i5 = 0; i5 < 2; i5 = i5 + 1) begin : csg_modules5
        carry_sum_generator #(.n(48)) csg_inst5 (
            .a(output_layer_4[i5 * 3]),
            .b(output_layer_4[i5 * 3 + 1]),
            .c_in(output_layer_4[i5 * 3 + 2]),
            .sum(output_layer_5[i5]),
            .c_out(output_layer_5[i5 + 2])
        );
    end
endgenerate

logic [48:0] output_layer_6 [0:2];
carry_sum_generator #(.n(48)) csg_inst6 (
    .a(output_layer_5[0]),
    .b(output_layer_5[1]),
    .c_in(output_layer_5[2]),
    .sum(output_layer_6[0]),
    .c_out(output_layer_6[1])
);
assign output_layer_6[2] = output_layer_5[3];

logic [48:0] output_layer_7 [0:1];
carry_sum_generator #(.n(48)) csg_inst7 (
    .a(output_layer_6[0]),
    .b(output_layer_6[1]),
    .c_in(output_layer_6[2]),
    .sum(output_layer_7[0]),
    .c_out(output_layer_7[1])
);
assign sum = output_layer_7[0][47:0];

endmodule

module cla48(
    input logic [47:0] a,
    input logic [47:0] b,
    input logic c_in,
    output logic [47:0] sum,
    output logic c_out
);

logic [47:0] p, g;
logic [48:0] c;

assign p = a ^ b;
assign g = a & b;

assign c[0] = c_in;

genvar i;
generate
    for (i = 0; i < 48; i = i + 1) begin : bit_cla
        assign c[i + 1] = g[i] | (p[i] & c[i]);
        assign sum[i] = p[i] ^ c[i];
    end
endgenerate

assign c_out = c[48];

endmodule

module carry_sum_generator #(n = 24) (
    input logic [n - 1:0] a,
    input logic [n - 1:0] b,
    input logic [n - 1:0] c_in,
    output logic [n - 1:0] sum,
    output logic [n:0] c_out
);

logic [n - 1:0] xor_result;
assign xor_result = a ^ b;

assign sum = xor_result ^ c_in;
assign c_out = {(a & b) | (xor_result & c_in), 1'b0};

endmodule