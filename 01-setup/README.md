to run the program

as -o setup.o setup.s
ld -o setup setup.o -lSystem -syslibroot `xcrun -sdk macosx --show-sdk-path` -e _start -arch arm64