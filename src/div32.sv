module div32(
    input fp32_t dividend,
    input fp32_t divisor,
    output fp32_t quotient
);

fp32_t a, b, c;
assign a = 32'h40257eb5;
assign b = 32'hc0ba2e8c;
assign c = 32'h4087c1f0;

fp32_t shifted_divisor, shifted_dividend;
logic signed [7:0] shift = 8'sd126 - divisor.exponent;

assign shifted_divisor = {1'b0, 8'd126, divisor.mantissa};

assign shifted_dividend = {1'b0, dividend.exponent + shift, dividend.mantissa};

logic divisor_LSB, dividend_LSB, round_up_divisor, round_up_dividend;
logic [2:0] divisor_GRS, dividend_GRS;
logic [25:0] shifted_divisor_mantissa, shifted_dividend_mantissa;

fp32_t rounded_divisor, rounded_dividend;
logic [25:0] temp_divisor_mantissa, temp_dividend_mantissa;

assign round_up_divisor = divisor_GRS[2] & (divisor_GRS[1] | divisor_GRS[0] | divisor_LSB);
assign round_up_dividend = dividend_GRS[2] & (dividend_GRS[1] | dividend_GRS[0] | dividend_LSB);
always_comb begin : rounding
    if (shift < 0 & shift > -26) begin
        shifted_divisor_mantissa = {1'b1, divisor.mantissa, 2'b0} >> shift;
        shifted_dividend_mantissa = {1'b1, dividend.mantissa, 2'b0} >> shift;

        divisor_LSB = shifted_divisor_mantissa[2];
        dividend_LSB = shifted_dividend_mantissa[2];

        divisor_GRS = {shifted_divisor_mantissa[1:0], |(divisor.mantissa << (26 + shift))};
        dividend_GRS = {shifted_dividend_mantissa[1:0], |(dividend.mantissa << (26 + shift))};
    end
    else if (shift <= -26) begin
        shifted_divisor_mantissa = 26'b0;
        shifted_dividend_mantissa = 26'b0;

        divisor_LSB = 1'b0;
        dividend_LSB = 1'b0;

        divisor_GRS = {2'b0, |divisor.mantissa};
        dividend_GRS = {2'b0, |dividend.mantissa};
    end
    else begin
        shifted_divisor_mantissa = {1'b1, divisor.mantissa, 2'b0};
        shifted_dividend_mantissa = {1'b1, dividend.mantissa, 2'b0};

        divisor_LSB = 1'b0;
        dividend_LSB = 1'b0;

        divisor_GRS = 3'b0;
        dividend_GRS = 3'b0;
    end

    if (round_up_divisor) begin
        rounded_divisor.sign = shifted_divisor.sign;
        temp_divisor_mantissa = shifted_divisor_mantissa + 26'h0000004;
        rounded_divisor.mantissa = temp_divisor_mantissa[25:3];

        if (temp_divisor_mantissa[25:2] == 24'b0) begin
            rounded_divisor.exponent = shifted_divisor.exponent + 1;
        end
        else begin
            rounded_divisor.exponent = shifted_divisor.exponent;
        end
    end
    else begin
        rounded_divisor = shifted_divisor;
    end

    if (round_up_dividend) begin
        rounded_dividend.sign = shifted_dividend.sign;
        temp_dividend_mantissa = shifted_dividend_mantissa + 26'h0000004;
        rounded_dividend.mantissa = (temp_dividend_mantissa[25:3]);

        if (temp_dividend_mantissa[25:2] == 24'b0) begin
            rounded_dividend.exponent = shifted_dividend.exponent + 1;
        end
        else begin
            rounded_dividend.exponent = shifted_dividend.exponent;
        end
    end
    else begin
        rounded_dividend = shifted_dividend;
    end
end

fp32_t linear_term;
mult32 linear(
    .a(shifted_divisor),
    .b(b),
    .product(linear_term)
);

fp32_t linear_sum;
add32 adder1(
    .a(c),
    .b(linear_term),
    .sum(linear_sum)
);

fp32_t divisor_square;
mult32 square(
    .a(shifted_divisor),
    .b(shifted_divisor),
    .product(divisor_square)
);

fp32_t quadratic_term;
mult32 quadratic(
    .a(divisor_square),
    .b(a),
    .product(quadratic_term)
);

fp32_t initial_estimate;
add32 adder2(
    .a(linear_sum),
    .b(quadratic_term),
    .sum(initial_estimate)
);

fp32_t second_estimate;
nr_iterate iteration1(
    .X(initial_estimate),
    .divisor(shifted_divisor),
    .next_X(second_estimate)
);

fp32_t third_estimate;
nr_iterate iteration2(
    .X(second_estimate),
    .divisor(shifted_divisor),
    .next_X(third_estimate)
);

fp32_t final_product;
mult32 final_multiplier(
    .a(third_estimate),
    .b(shifted_dividend),
    .product(final_product)
);

logic signed [7:0] test;
always_comb begin
    test = shift;
    //$display("shift: %b", test);
end

assign quotient = {divisor[31] ^ dividend[31], final_product.exponent, final_product.mantissa};

endmodule

module nr_iterate(
    input fp32_t X,
    input fp32_t divisor,
    output fp32_t next_X
);

logic [31:0] mult_result;
logic [31:0] coefficient;

mult32 multiplier_1(
    .a(divisor),
    .b(X),
    .product(mult_result)
);

add32 subtractor(
    .a(32'h40000000),
    .b({~mult_result[31], mult_result[30:0]}),
    .sum(coefficient)
);

mult32 multiplier_2(
    .a(coefficient),
    .b(X),
    .product(next_X)
);

endmodule