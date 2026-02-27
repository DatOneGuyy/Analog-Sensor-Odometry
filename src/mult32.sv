module mult32(
    input logic [31:0] a,
    input logic [31:0] b,
    output logic [31:0] product
);

logic implied_a, implied_b;
logic unsigned [7:0] exp_a, exp_b;
logic [22:0] mantissa_a, mantissa_b;

assign implied_a = (a[30:23] != 8'b0);
assign implied_b = (b[30:23] != 8'b0);
assign exp_a = implied_a ? a[30:23] : 8'b1;
assign exp_b = implied_b ? b[30:23] : 8'b1;

assign mantissa_a = a[22:0];
assign mantissa_b = b[22:0];

logic [27:0] lzc_in_a, lzc_in_b;
logic [4:0] lz_a, lz_b;

assign lzc_in_a = {implied_a, mantissa_a, 4'b0000};
assign lzc_in_b = {implied_b, mantissa_b, 4'b0000};

lzc28 lzc_inst_a (.in_vec(lzc_in_a), .leading_zeroes(lz_a));
lzc28 lzc_inst_b (.in_vec(lzc_in_b), .leading_zeroes(lz_b));

logic [23:0] pre_norm_mantissa_a, pre_norm_mantissa_b;

assign pre_norm_mantissa_a = {implied_a, mantissa_a} << lz_a;
assign pre_norm_mantissa_b = {implied_b, mantissa_b} << lz_b;

logic signed [9:0] eff_exp_a, eff_exp_b, exp_sum;

assign eff_exp_a = implied_a ? {2'b0, exp_a} : (10'sd1 - {5'b0, lz_a});
assign eff_exp_b = implied_b ? {2'b0, exp_b} : (10'sd1 - {5'b0, lz_b});

logic [47:0] mantissa_product;
imult24 imult_inst(
    .a(pre_norm_mantissa_a),
    .b(pre_norm_mantissa_b),
    .sum(mantissa_product)
);

logic sign_bit;
assign sign_bit = a[31] ^ b[31];

logic overflow, underflow, subnormal;

logic [26:0] normalized_mantissa;
logic LSB, round_up, normalization_shift;

assign LSB = normalized_mantissa[3];
assign normalization_shift = mantissa_product[47];

always_comb begin : normalization
    if (normalization_shift) begin
        normalized_mantissa = {mantissa_product[47:22], |mantissa_product[21:0]};
    end
    else begin
        normalized_mantissa = {mantissa_product[46:21], |mantissa_product[20:0]};
    end
end

logic [26:0] subnormal_mantissa;
logic [4:0] subnormal_shift;
always_comb begin : exponent_calculation
    exp_sum = eff_exp_a + eff_exp_b - 10'd127 + {9'b0, normalization_shift};

    overflow = exp_sum >= 255;
    underflow = exp_sum < -26;
    subnormal = (exp_sum < 1) & (exp_sum >= -26);

    subnormal_shift = 5'b1 - exp_sum[4:0];

    subnormal_mantissa = normalized_mantissa >> (subnormal ? subnormal_shift : 5'b0);
    subnormal_mantissa[0] = subnormal ? (|(normalized_mantissa << (27 - subnormal_shift))) : subnormal_mantissa[0];

    if (overflow) exp_sum = 10'sd255;
    else if (underflow | subnormal) exp_sum = 10'sd0;
end

logic unsigned [27:0] rounded_mantissa;
logic [9:0] rounded_exp;
always_comb begin : rounding
    if (subnormal) begin
        round_up = subnormal_mantissa[2] & (subnormal_mantissa[1] | subnormal_mantissa[0] | LSB);

        rounded_exp = 10'b0;
        rounded_mantissa = subnormal_mantissa + {23'b0, round_up, 3'b0};
    end
    else begin
        round_up = normalized_mantissa[2] & (normalized_mantissa[1] | normalized_mantissa[0] | LSB);

        rounded_mantissa = normalized_mantissa + {23'b0, round_up, 3'b0};
        rounded_exp = exp_sum + {9'b0, rounded_mantissa[27]};
    end
end

logic a_infty, a_nan, b_infty, b_nan, a_zero, b_zero;
assign a_infty = (exp_a == 8'hFF) & (mantissa_a == 23'b0);
assign b_infty = (exp_b == 8'hFF) & (mantissa_b == 23'b0);
assign a_nan = (exp_a == 8'hFF) & (mantissa_a != 23'b0);
assign b_nan = (exp_b == 8'hFF) & (mantissa_b != 23'b0);
assign a_zero = (a[30:0] == 31'b0);
assign b_zero = (b[30:0] == 31'b0);

logic is_special;
logic [31:0] special_result;
logic [31:0] nan_val;
always_comb begin : edge_cases
    if (a_nan | b_nan) begin
        is_special = 1'b1;

        special_result = b_nan ? b : a;
        special_result[22] = 1'b1;
    end
    else if ((a_infty | b_infty) & (a_zero | b_zero)) begin
        is_special = 1'b1;
        special_result = 32'h7FC00000; 
    end
    else if (a_infty | b_infty | overflow) begin
        is_special = 1'b1;
        special_result = {sign_bit, 8'hFF, 23'b0};
    end
    else if (a_zero | b_zero | underflow) begin
        is_special = 1'b1;
        special_result = {sign_bit, 31'b0};
    end
    else if (subnormal) begin
        is_special = 1'b1;
        special_result = {sign_bit, 8'b0, rounded_mantissa[25:3]};
    end
    else begin
        is_special = 1'b0;
        special_result = 32'h0; 
    end
end

assign product = is_special ? special_result : {sign_bit, rounded_exp[7:0], rounded_mantissa[25:3]};

endmodule