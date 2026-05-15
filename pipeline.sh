#!/bin/bash

set -e

echo "PHASE 1: FORTRAN DATA GENERATION"

echo "Compiling..."
make

echo "Simulating..."
./bin/epidemic_simulator 1000 100 1000 100 0 0.5 0.01 42

echo "Simulation complete. Output written to run/ directory."
echo ""

echo "PHASE 2: PYTORCH PARAMETER DISCOVERY"

python src/pinn/inverse_sir.py

echo ""
echo "PIPELINE EXECUTION COMPLETE"