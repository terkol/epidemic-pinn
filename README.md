# Epidemic PINN: Inverse Parameter Discovery from Stochastic Agent-Based Models

An end-to-end Scientific Machine Learning (SciML) pipeline bridging a discrete spatial simulation with continuous deep learning to solve an inverse data assimilation problem. The architecture consists of two decoupled components: a custom-built, stochastic Agent-Based Model (ABM) written in Fortran 90 that generates spatial epidemic trajectories, and a Physics-Informed Neural Network (PINN) written in PyTorch that autonomously reverse-engineers the continuous ordinary differential equation (ODE) parameters ($\beta$, $\gamma$) from that discrete trajectory data.

### Repository Structure

```text
epidemic-pinn/
├── bin/
│   └── epidemic_simulator            # Compiled Fortran executable (.gitignore)
├── build/                            # Compiled object files (*.o) (.gitignore)
├── report/                           # Academic figures and Rmd files (.gitignore)
├── run/
│   ├── 500_100_1000_100...txt        # Empirical fraction trajectories
│   └── epidemic.xyz                  # Spatial trajectory history (.gitignore)
├── src/
│   ├── simulator/                    # The Spatial ABM (Data Generator)
│   │   ├── mtfort90.f90              # Mersenne Twister RNG module
│   │   ├── utils.f90                 # Grid physics and state transition logic
│   │   └── epidemic_simulator.f90    # Fortran entrypoint
│   └── pinn/                         # The Inverse Solver (Parameter Discovery)
│       ├── data_loader.py            # Normalization and Tensor formatting
│       └── inverse_sir.py            # PINN architecture and ODE calculus graph
├── Makefile                          # Fortran compiler directives
├── pipeline.sh                       # End-to-end Bash orchestrator
├── Dockerfile                        # Containerized environment blueprint
├── requirements.txt                  # Python AI dependencies
└── Project-Report.txt                # Original academic scientific report

```
## Component 1: The Stochastic Spatial Simulator (Fortran 90)

The ground-truth data generator is a high-performance, discrete-time, 2D spatial Agent-Based Model. Agents (walkers) navigate a grid subject to periodic boundary conditions via an unbiased random-walk protocol. State transitions are determined entirely by local interactions rather than global mixing. Infection requires an absolute spatial collision, sharing an exact coordinate, coupled with a successful stochastic transmission roll. Conversely, recovery is determined by an independent probability evaluated for each infected agent at every time step. During execution, the simulator logs both the discrete spatial histories (`epidemic.xyz`) and the macroscopic state counts into the `run/` directory.


## Component 2: The Physics-Informed Neural Network (PyTorch)

The PyTorch module operates as a continuous, temporal calculus graph utilizing `torch.autograd` to calculate exact ODE constraints over the normalized trajectory data.

### Spatial Clustering and Model Mismatch

A primary scientific result of this pipeline is demonstrating the PINN's ability to natively quantify spatial correction factors when mapping a 2D grid simulation to a 0D continuous ODE (a Mean-Field Approximation). Given the default Fortran input probabilities, the theoretical well-mixed transmission rate is $\beta = 0.05$ and the recovery rate is $\gamma = 0.01$. While the PyTorch optimizer flawlessly converges on the exact recovery rate ($\gamma \approx 0.01$), it discovers an effective transmission rate of $\beta \approx 0.03$. This mathematically demonstrates that the spatial constraints of a 2D grid, where newly infected agents are physically isolated by local clusters of immune or already-infected agents, suppress transmission by approximately 40% compared to a perfectly mixed theoretical population. The network successfully assimilates this non-linear spatial clustering (local depletion of susceptibles) into a static ODE parameter.

### Lambda-weighting

To ensure stable convergence and prevent trivial solution collapse, the loss function implements $\lambda$-weighting ($1 \times 10^{-6}$) to balance the squared ODE residuals ($\mathcal{L}_ {physics}$) against the empirical mean squared error ($\mathcal{L}_ {data}$). This accounts for the temporal chain-rule scaling caused by the $t \in [0, 1]$ normalization.

$$\mathcal{L} = \mathcal{L}_{data} + \lambda \mathcal{L}_{physics}$$

## Execution Instructions

### End-to-End Execution (Docker)

This protocol autonomously compiles the Fortran environment, simulates a new 10,000-step stochastic epidemic, parses the output, and trains the neural network to discover the effective physical parameters.

Build the unified execution image (installs gfortran, Python 3.10, and PyTorch):

`docker build -t epidemic-pinn .`

Execute the orchestration pipeline:

`docker run --rm epidemic-pinn`

### Isolated Component Execution (Local)

To bypass the Fortran compilation and strictly evaluate the PyTorch calculus graph against pre-generated trajectory data in the `run/` directory:

Compile the Fortran binary manually:

`make`

Generate physical data: 

`./bin/epidemic_simulator 10000 100 1000 100 0 0.5 0.01 42`

Execute the PINN consumer: 

`python src/pinn/inverse_sir.py`
