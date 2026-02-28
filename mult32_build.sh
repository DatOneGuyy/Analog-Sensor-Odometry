verilator --binary -j 0 -o mult32 --Mdir ../modules src/imult24.sv src/lzc28.sv src/mult32.sv testbenches/mult32_tb.sv
rm *.h
rm *.cpp
rm *.a
rm *.d
rm *.o
rm *.dat
rm *.mk
rm *.gch
./mult32