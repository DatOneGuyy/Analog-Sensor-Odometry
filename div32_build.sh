verilator --binary -j 0 -o div32 --Mdir ../modules src/mult32.sv src/imult24.sv src/structs.sv src/lzc28.sv src/div32.sv src/add32.sv testbenches/div32_tb.sv
rm *.h
rm *.cpp
rm *.a
rm *.d
rm *.o
rm *.dat
rm *.mk
./div32