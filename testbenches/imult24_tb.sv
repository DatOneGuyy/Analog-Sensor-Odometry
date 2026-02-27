module imult24_tb();

logic [23:0] a, b;
logic [47:0] product;
logic [47:0] actual_product;

imult24 dut(.a(a), .b(b), .sum(product));

integer mismatches;
integer successes;
integer file;

// path to the vector file; adjust as needed or make it a parameter
string fname;

integer ret;
integer count;
initial begin
    fname = "testbenches/imult24_vectors.txt"; // use relative or absolute path
    file = $fopen(fname, "r");

    if (file == 0) begin
        $display("Could not open %s", fname);
        $finish;
    end

    while (!$feof(file)) begin
        ret = $fscanf(file, "%h %h %h\n", a, b, actual_product);
        if (ret != 3) begin
            $display("Invalid vector format on line %d", count);
            $finish;
        end

        count = count + 1;

        #1;
        if (product != actual_product) begin
            $display("Mismatch: a: %h b: %h found: %h expected: %h on line %d", a, b, product, actual_product, count);
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
