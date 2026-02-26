module lzc_28 (
    input  logic [27:0] in_vec,
    output logic [4:0]  leading_zeroes
);

logic [31:0] padded_vec;
assign padded_vec = {in_vec, 4'b0000};

logic [15:0] half_16;
logic [7:0]  half_8;
logic [3:0]  half_4;
logic [1:0]  half_2;
logic [4:0]  count;

always_comb begin
    if (padded_vec[31:16] == 16'b0) begin
        count[4] = 1'b1;
        half_16  = padded_vec[15:0];
    end else begin
        count[4] = 1'b0;
        half_16  = padded_vec[31:16];
    end

    if (half_16[15:8] == 8'b0) begin
        count[3] = 1'b1;
        half_8   = half_16[7:0];
    end else begin
        count[3] = 1'b0;
        half_8   = half_16[15:8];
    end

    if (half_8[7:4] == 4'b0) begin
        count[2] = 1'b1;
        half_4   = half_8[3:0];
    end else begin
        count[2] = 1'b0;
        half_4   = half_8[7:4];
    end

    if (half_4[3:2] == 2'b0) begin
        count[1] = 1'b1;
        half_2   = half_4[1:0];
    end else begin
        count[1] = 1'b0;
        half_2   = half_4[3:2];
    end

    if (half_2[1] == 1'b0) begin
        count[0] = 1'b1;
    end else begin
        count[0] = 1'b0;
    end

    leading_zeroes = count;
end

endmodule