.PHONY: all clean dirs
all: dirs bin/epidemic_simulator

dirs:
	mkdir -p build bin

bin/epidemic_simulator: build/mtfort90.o build/utils.o build/epidemic_simulator.o
	gfortran -o $@ $^

build/%.o: src/simulator/%.f90 | dirs
	gfortran -J build -I build -c $< -o $@

clean:
	rm -rf build bin
