verilator --binary -j 0 -o add32 --Mdir ../modules add32.sv add32_tb.sv
rm *.h
rm *.cpp
rm *.a
rm *.d
rm *.o
rm *.dat
rm *.mk
./add32