module div32_tb();

logic [31:0] dividend, divisor;
logic [31:0] quotient;
logic [31:0] actual_quotient;

div32 dut(.dividend(dividend), .divisor(divisor), .quotient(quotient));

integer mismatches;
integer successes;
integer file;

// path to the vector file; adjust as needed or make it a parameter
string fname;

integer ret;
integer count;
initial begin
    fname = "testbenches/fpdiv32_vectors.txt"; // use relative or absolute path
    file = $fopen(fname, "r");

    if (file == 0) begin
        $display("Could not open %s", fname);
        $finish;
    end

    while (!$feof(file)) begin
        ret = $fscanf(file, "%h %h %h\n", dividend, divisor, actual_quotient);
        if (ret != 3) begin
            $display("Invalid vector format on line %d", count);
            $finish;
        end

        count = count + 1;

        #1;
        if (quotient != actual_quotient) begin
            $display("Mismatch: dividend: %h divisor: %h found: %h expected: %h on line %d", 
                     dividend, divisor, quotient, actual_quotient, count);
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
