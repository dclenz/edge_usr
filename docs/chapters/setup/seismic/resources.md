# Resource Requirements
This chapter summarizes EDGE's resource requirements for seismic simulations.

## Memory
EDGE's memory requirements depend on the chosen convergence rate and the number of fused runs.

In this section we only consider required memory for 4-node tetrahedral elements, the elastic wave equations (9 quantities), double precision arithmetic (64-bit per value) and the following data structures in every element:
* Degrees Of Freedom (DOFs)
* Time Integrated DOFs
* Each of the eight Riemann solvers (sometimes called flux solvers)
* Each of the three Jacobians (sometimes called star matrices)

Therefore, the memory requirements for the mesh, kinematic sources, internal dynamic rupture boundaries, etc. are neglected.

Increasing the convergence rate, increases the number of modes per element.
An increase in the number of fused runs, also increases the memory footprint of every element.
However, data is shared for fused simulations, which reduces the relative memory footprint per run.
For example, a second order simulation without fused runs (C1) requires 6,336 bytes in theory.
By fusing eight runs, the per-element footprint increases to 10,368 bytes.
This is equivalent to an increase by $$\frac{10.368}{6,336} \approx 1.64$$ in required memory.
However, the memory footprint per element and forward run decreases to $$\frac{10,368}{8} = 1,296$$.
The corresponding improvement per forward run is therefore: $$\frac{6,336}{1,296} \approx 4.9$$.

The following table gives the memory footprint per element in dependency of the order for a non-fused run (C1), four (C4), and eight fused runs (C8):

| Order | Modes | C1-Bytes | C4-Bytes | C8-Bytes |
|-------|-------|----------|----------|----------|
| 1     |     1 |    5,904 |    6,336 |    6,912 |
| 2     |     4 |    6,336 |    8,064 |   10,368 |
| 3     |    10 |    7,200 |   11,520 |   17,280 |
| 4     |    20 |    8,640 |   17,280 |   28,800 |
| 5     |    35 |   10,800 |   25,920 |   46,080 |
| 6     |    56 |   13,824 |   38,016 |   70,272 |
| 7     |    84 |   17,856 |   54,144 |  102,528 |

## Element Throughput
Analogue, to the discussed memory requirements, all considerations in this section are limited to 4-node tetrahedral elements, the elastic wave equations (9 quantities), and double precision arithmetic (64-bit per value).
Further, the reported times per element and time step were measured simulating the LOH.1 benchmark with a total of 350,264 tetrahedral elements.
Architecture was a single node of Cori Phase II (Intel Xeon Phi 7250 68-core processors at 1.4 GHz with Intel Turbo Boost enabled) and all data allocated in High Bandwidth Memory (HBM/MCDRAM).

The following table shows the required time per element and per time step in dependency of the order for non-fused configurations (C1) and eight fused runs (C8):

| Order | C1-Seconds | C8-Seconds |
|-------|------------|------------|
| 2     |   6.06E-08 |   1.30E-07 |
| 3     |   1.14E-07 |   2.88E-07 |
| 4     |   2.08E-07 |   7.30E-07 |
| 5     |   4.41E-07 |          - |
| 6     |   6.93E-07 |          - |
