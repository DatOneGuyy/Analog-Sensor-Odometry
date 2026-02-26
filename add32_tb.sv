module add32_tb();

logic [31:0] a, b;
logic [31:0] sum;
logic [31:0] actual_sum;

add32 dut(.a(a), .b(b), .sum(sum));

integer mismatches;
integer successes;
integer file;

integer ret;
integer count;
initial begin
    file = $fopen("vectors.txt", "r");

    if (file == 0) begin
        $display("Could not open vectors.txt");
        $finish;
    end

    while (!$feof(file)) begin
        ret = $fscanf(file, "%h %h %h\n", a, b, actual_sum);
        if (ret != 3) begin
            $display("Invalid vector format on line %d", count);
            $finish;
        end

        count = count + 1;

        #1;
        if (sum != actual_sum) begin
            $display("Mismatch: a: %h b: %h found: %h expected: %h on line %d", a, b, sum, actual_sum, count);
            mismatches = mismatches + 1;
        end
        else begin
            successes = successes + 1;
        end

        if (mismatches > 99) begin
            $display("Ended after 100 mismatches.");
            $finish;
        end
    end

    $display("Finished test. Total successes: %d", successes);
    $display("Total mismatches: %d", mismatches);
    $finish;
end

endmodule