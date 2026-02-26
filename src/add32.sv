module add32(
    input [31:0] a,
    input [31:0] b,
    output logic [31:0] sum
);

logic unsigned [7:0] exp_a, exp_b, exp_sum, lz_count_exp, diff;
logic unsigned [26:0] mantissa_a, mantissa_b, shifted_mantissa;
logic [31:0] calculated_sum;

assign exp_a = a[30:23]; 
assign exp_b = b[30:23];

//{leading 1, mantissa, G, R, S}
assign mantissa_a = {1'b1, a[22:0], 3'b000};
assign mantissa_b = {1'b1, b[22:0], 3'b000};

logic round_up;

//{overflow, leading 1, mantissa, G, R, S}
logic unsigned [27:0] sum_mantissa, lz_count_mantissa;
logic [4:0] leading_zeroes;
lzc_28 lzc_inst(.in_vec(sum_mantissa), .leading_zeroes(leading_zeroes));

logic result_sign;

logic s_bit_a, s_bit_b, new_sticky;

always_comb begin : calculation
    shifted_mantissa = 27'b0;
    sum_mantissa = 28'b0;
    new_sticky = 1'b0;
    s_bit_a = 1'b0;
    s_bit_b = 1'b0;

    if (exp_a > exp_b) begin
        diff = exp_a - exp_b;
        exp_sum = exp_a;
        result_sign = a[31];

        if (diff < 26) begin
            shifted_mantissa = mantissa_b >> diff;
            s_bit_b = |(mantissa_b << (27 - diff));
            shifted_mantissa[0] = shifted_mantissa[0] | s_bit_b;

            if (a[31] ^ b[31]) sum_mantissa = mantissa_a - shifted_mantissa;
            else sum_mantissa = mantissa_a + shifted_mantissa;
        end
        else begin
            shifted_mantissa = 27'b0;
            sum_mantissa = {2'b01, a[22:0], 3'b000};

            sum_mantissa[0] = |mantissa_b;
        end
    end
    else if (exp_b > exp_a) begin
        diff = exp_b - exp_a;
        exp_sum = exp_b;
        result_sign = b[31];

        if (diff < 26) begin
            shifted_mantissa = mantissa_a >> diff;
            s_bit_a = |(mantissa_a << (27 - diff));
            shifted_mantissa[0] = shifted_mantissa[0] | s_bit_a;

            if (a[31] ^ b[31]) sum_mantissa = mantissa_b - shifted_mantissa;
            else sum_mantissa = mantissa_b + shifted_mantissa;
        end
        else begin
            shifted_mantissa = 27'b0;
            sum_mantissa[0] = |(mantissa_a << (27 - diff));
            
            sum_mantissa = {2'b01, b[22:0], 3'b000};
            sum_mantissa[0] = |mantissa_a;
        end
    end
    else begin
        diff = 8'b0;
        exp_sum = exp_a;

        if (a[31] ^ b[31]) begin
            if (mantissa_a > mantissa_b) begin
                sum_mantissa = mantissa_a - mantissa_b;
                result_sign = a[31];
            end
            else begin
                sum_mantissa = mantissa_b - mantissa_a;
                result_sign = b[31];
            end
        end
        else begin
            sum_mantissa = mantissa_a + mantissa_b;
            result_sign = a[31];
        end
    end

    //renormalize addition overflow
    if (sum_mantissa[27]) begin
        new_sticky = sum_mantissa[1] | sum_mantissa[0];

        exp_sum = exp_sum + 8'b1;
        sum_mantissa = sum_mantissa >> 1;
        sum_mantissa[0] = new_sticky;
    end
    
    lz_count_mantissa = sum_mantissa;
    lz_count_exp = exp_sum;
end

logic [27:0] normalized_mantissa;
logic [7:0] normalized_exp;

always_comb begin : normalization
    normalized_mantissa = lz_count_mantissa;
    normalized_exp = lz_count_exp;

    if (normalized_mantissa == 28'b0) begin
        normalized_exp = 8'b0;
    end
    else if ({3'b0, leading_zeroes} >= normalized_exp) begin
        normalized_mantissa = normalized_mantissa << (normalized_exp - 1);
        normalized_exp = 8'b0;
    end
    else begin
        normalized_mantissa = normalized_mantissa << leading_zeroes;
        normalized_exp = normalized_exp - {3'b0, leading_zeroes};
    end

    round_up = normalized_mantissa[2] & (normalized_mantissa[1] | normalized_mantissa[0] | normalized_mantissa[3]);
    
    normalized_exp = normalized_exp + {7'b0, (&(normalized_mantissa[25:3]) & round_up)};
    normalized_mantissa = normalized_mantissa + {24'b0, round_up, 3'b0};

    calculated_sum = {result_sign, normalized_exp, normalized_mantissa[25:3]};
end

logic a_infty, a_nan, b_infty, b_nan;
assign a_infty = (exp_a == 8'hff) & (mantissa_a[25:3] == 23'b0);
assign b_infty = (exp_b == 8'hff) & (mantissa_b[25:3] == 23'b0);
assign a_nan = (exp_a == 8'hff) & (mantissa_a[25:3] != 23'b0);
assign b_nan = (exp_b == 8'hff) & (mantissa_b[25:3] != 23'b0);

logic is_special;
logic [31:0] special_result;

always_comb begin : edge_cases
    is_special = 1'b0;
    special_result = 32'h7FC00000;

    if (a_nan | b_nan) begin
        is_special = 1'b1;
        special_result = a;
    end
    else if (a_infty ^ b_infty) begin
        is_special = 1'b1;
        special_result = a_infty ? a : b;
    end
    else if (a_infty & b_infty) begin
        is_special = 1'b1;
        special_result = (a[31] ~^ b[31]) ? a : 32'h7FC00000;
    end

    sum = is_special ? special_result : calculated_sum;
end

endmodule