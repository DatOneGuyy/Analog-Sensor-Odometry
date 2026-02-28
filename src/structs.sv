typedef struct packed {
    logic sign;
    logic [7:0] exponent;
    logic [22:0] mantissa;
} fp32_t;