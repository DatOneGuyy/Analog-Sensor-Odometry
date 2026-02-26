verilator --binary -j 0 -o add32 --Mdir ../modules src/add32.sv testbenches/add32_tb.sv src/lzc28.sv
rm *.h
rm *.cpp
rm *.a
rm *.d
rm *.o
rm *.dat
rm *.mk
./add32