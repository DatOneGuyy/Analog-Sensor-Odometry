module lzc_28 (
    input  logic [27:0] in_vec,
    output logic [4:0]  leading_zeroes
);
// Pad the 28-bit vector to 32 bits at the LSB. 
// This makes the binary tree perfectly symmetrical.
// in_vec[27] (the MSB) becomes padded_vec[31].
logic [31:0] padded_vec;
assign padded_vec = {in_vec, 4'b0000};

logic [15:0] half_16;
logic [7:0]  half_8;
logic [3:0]  half_4;
logic [1:0]  half_2;
logic [4:0]  count;

always_comb begin
    // Level 1: Split 32 bits into two 16-bit halves
    if (padded_vec[31:16] == 16'b0) begin
        count[4] = 1'b1;           // Top 16 bits are all 0, add 16 to count
        half_16  = padded_vec[15:0]; // Pass the bottom half to the next level
    end else begin
        count[4] = 1'b0;           // A 1 exists in the top half
        half_16  = padded_vec[31:16]; // Pass the top half to the next level
    end

    // Level 2: Split 16 bits into two 8-bit halves
    if (half_16[15:8] == 8'b0) begin
        count[3] = 1'b1;           // Add 8 to count
        half_8   = half_16[7:0];
    end else begin
        count[3] = 1'b0;
        half_8   = half_16[15:8];
    end

    // Level 3: Split 8 bits into two 4-bit halves
    if (half_8[7:4] == 4'b0) begin
        count[2] = 1'b1;           // Add 4 to count
        half_4   = half_8[3:0];
    end else begin
        count[2] = 1'b0;
        half_4   = half_8[7:4];
    end

    // Level 4: Split 4 bits into two 2-bit halves
    if (half_4[3:2] == 2'b0) begin
        count[1] = 1'b1;           // Add 2 to count
        half_2   = half_4[1:0];
    end else begin
        count[1] = 1'b0;
        half_2   = half_4[3:2];
    end

    // Level 5: Check the final remaining top bit
    if (half_2[1] == 1'b0) begin
        count[0] = 1'b1;           // Add 1 to count
    end else begin
        count[0] = 1'b0;
    end

    leading_zeroes = count;
end

endmodule