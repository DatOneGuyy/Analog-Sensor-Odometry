verilator --binary -j 0 -o imult24 --Mdir ../modules src/imult24.sv testbenches/imult24_tb.sv
rm *.h
rm *.cpp
rm *.a
rm *.d
rm *.o
rm *.dat
rm *.mk
./imult24