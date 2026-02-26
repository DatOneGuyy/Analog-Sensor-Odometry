module add32(
    input [31:0] a,
    input [31:0] b,
    output logic [31:0] sum
);

localparam bias = 8'd127;

logic unsigned [7:0] exp_a;
logic unsigned [7:0] exp_b;
logic unsigned [7:0] diff;

logic signed [24:0] mantissa_a;
logic signed [24:0] mantissa_b;
logic signed [24:0] mantissa_a_neg;
logic signed [24:0] mantissa_b_neg;

assign exp_a = a[30:23]; 
assign exp_b = b[30:23];

//restore original mantissa values
assign mantissa_a = {2'b01, a[22:0]};
assign mantissa_b = {2'b01, b[22:0]};
assign mantissa_a_neg = ~mantissa_a + 1'b1;
assign mantissa_b_neg = ~mantissa_b + 1'b1;

logic signed [26:0] shifted_mantissa;
logic signed [24:0] sum_mantissa;
logic unsigned [24:0] sum_mantissa_unsigned;
logic sum_mantissa_sign;
logic signed [7:0] exp_sum;

logic addition_overflow;

integer leading_zeroes;

logic G, R, S, LSB, round_up;

always @(*) begin
    if (exp_a > exp_b) begin
        diff = exp_a - exp_b;
        if (diff < 26) begin
            shifted_mantissa = {(b[31] ? mantissa_b_neg : mantissa_b), 2'b00};
            shifted_mantissa = shifted_mantissa >>> diff;
            sum_mantissa = (a[31] ? mantissa_a_neg : mantissa_a) + shifted_mantissa[26:2];
            sum_mantissa_sign = sum_mantissa[24];
        end
        else begin
            shifted_mantissa = 27'b0;
            sum_mantissa = (a[31] ? mantissa_a_neg : mantissa_a);
            sum_mantissa_sign = a[31];
        end

        S = |({(b[31] ? mantissa_b_neg : mantissa_b)} << (27 - diff));
        
        addition_overflow = (a[31] == b[31]) & (a[31] != sum_mantissa_sign);
        exp_sum = exp_a + {7'b0, (a[31] == b[31]) & (a[31] != sum_mantissa_sign)};

        if (addition_overflow) begin
            sum_mantissa = {a[31], sum_mantissa[24:1]};
            sum_mantissa_sign = a[31];
        end
    end
    else begin
        diff = exp_b - exp_a;
        if (diff < 26) begin
            shifted_mantissa = {(a[31] ? mantissa_a_neg : mantissa_a), 2'b00};
            shifted_mantissa = shifted_mantissa >>> diff;
            sum_mantissa = (b[31] ? mantissa_b_neg : mantissa_b) + shifted_mantissa[26:2];
            sum_mantissa_sign = sum_mantissa[24];
        end
        else begin
            shifted_mantissa = 27'b0;
            sum_mantissa = (b[31] ? mantissa_b_neg : mantissa_b);
            sum_mantissa_sign = b[31];
        end
        
        G = shifted_mantissa[1];
        R = shifted_mantissa[0];
        S = |({(a[31] ? mantissa_a_neg : mantissa_a)} << (27 - diff));

        addition_overflow = (a[31] == b[31]) & (a[31] != sum_mantissa_sign);
        exp_sum = exp_b + {7'b0, addition_overflow};

        if (addition_overflow) begin
            sum_mantissa = {b[31], sum_mantissa[24:1]};
            sum_mantissa_sign = b[31];
        end
    end

    LSB = sum_mantissa[0];

    round_up = G & (R | S | LSB);
    exp_sum = exp_sum + {7'b0, (&(sum_mantissa[23:0]) & round_up)};

    if (sum_mantissa_sign) begin
        sum_mantissa_unsigned = (~sum_mantissa) + 25'b1;
    end
    else begin
        sum_mantissa_unsigned = sum_mantissa;
    end

    leading_zeroes = 0;
    //begin count ignoring the bit used for checking sign
    for (integer i = 23; i >= 0; i = i - 1) begin
        if (~sum_mantissa_unsigned[i]) begin
            leading_zeroes = leading_zeroes + 1;
        end
        else begin
            break;
        end
    end

    sum_mantissa_unsigned = sum_mantissa_unsigned << leading_zeroes;
    exp_sum = exp_sum - leading_zeroes[7:0];

    sum_mantissa = sum_mantissa + round_up;

    sum = {sum_mantissa_sign, exp_sum, sum_mantissa_unsigned[22:0]};
end

endmodule