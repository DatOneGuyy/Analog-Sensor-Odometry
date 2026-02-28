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
assign shifted_divisor = {divisor.sign, 8'd126, divisor.mantissa};

logic signed [7:0] shift = 8'd126 - shifted_divisor.exponent;
assign shifted_dividend = {dividend.sign, dividend.exponent + shift, dividend.mantissa};

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
    .b(c),
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

assign quotient = shifted_dividend * third_estimate;

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