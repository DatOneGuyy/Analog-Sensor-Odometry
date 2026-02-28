module div32(
    input fp32_t dividend,
    input fp32_t divisor,
    output fp32_t quotient
);



endmodule

module nr_iterate(
    input fp32_t X,
    input fp32_t divisor,
    input fp32_t next_X
);

logic [31:0] mult_result;
logic [31:0] coefficient;

mult32 multiplier_1(
    .a(divisor),
    .b(X),
    .result(mult_result)
);


add32 subtractor(
    .a(32'h40000000),
    .b({~mult_result[31], mult_result[30:0]}),
    .result(coefficient)
);

mult32 multiplier_2(
    .a(cofficient),
    .b(X),
    .result(next_X)
);

endmodule