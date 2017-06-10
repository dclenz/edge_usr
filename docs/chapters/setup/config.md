# Configuration
EDGE uses XML-files for build- and runtime-configurations.
Using XML-input for building EDGE through `--xml=[...]` is optional.
All build arguments might also be passed to SCons directly.
In contrast, passing XML-input for the runtime configuration through `-x [...]` is mandatory.
Except for the verbose flag `-v`, no other command-line arguments are accepted.

## XML-tree
The following shows an overview of all XML-nodes in EDGE.
Dependent on the build-type, only a subset of the nodes is active.
For example, a given velocity model (`<velocity_model>`) is only parsed for seismic problems.
The comment `<!-- [...] -->` indicates, that a node is allowed to appear multiple times in the XML-tree.
```
<edge>
  <build>
    <cfr/>
    <equations/>
    <element_type/>
    <order/>
    <mode/>
    <arch/>
    <precision/>
    <parallel/>
    <cov/>
    <tests/>
    <build_dir/>
    <xsmm/>
    <zlib/>
    <hdf5/>
    <netcdf/>
    <moab/>
    <inst/>
  </build>

  <cfr>
    <mesh>
      <files>
        <in/>
      </files>
      <boundary>
        <free_surface/>
        <outflow/>
      </boundary>
    </mesh>

    <velocity_model>
      <domain>
        <half_space>
          <origin>
            <x/>
            <y/>
            <z/>
          </origin>
          <normal>
            <x/>
            <y/>
            <z/>
          </normal>
        </half_space>
        <!-- [...] -->

        <rho/>
        <lambda/>
        <mu/>
      </domain>
      <!-- [...] -->
    </velocity_model>

    <setups>
      <kinematic_sources>
        <file/>
        <!-- [...] -->
      </kinematic_sources>

      <end_time/>
    </setups>

    <output>
      <receivers>
        <path_to_dir/>
        <freq/>

        <receiver>
          <name/>
          <coords>
            <x/>
            <y/>
            <z/>
          </coords>
        </receiver>
        <!-- [...] -->
      </receivers>

      <wave_field>
        <type/>
        <file/>
        <int/>
      </wave_field>
    </output>
  </cfr>
</edge>
```

## &lt;edge&gt;
The node `<edge>` is the root of both, the runtime- and the build-configuration.

## &lt;build&gt; {#sec_build}
The node `<build>` describes the build-configuration and is only used by SCons.
EDGE also parses `<build>` at runtime, however the information is only logged and does not influence runtime behavior.

|    Attribute | Allowed Values | Description |
| --           | --             | --          |
| cfr          | 1, 2, 4, 8, 12, 16 | Number of concurrent/fused forward runs. 1, 4, 8, and 16 are typically used. |
| equations    | advection, elastic, elastic+rupture, swe | Equations solved. advection: advection equation, elastic: elastic wave equations with kinematic sources, elastic+rupture: elastic wave equations with solver for rupture physics at internal boundaries, swe: shallow water equations. |
| element_type | line, quad4r, tria3, hex8r, tet4 | Element type used for spatial discretization. line: line elements, quad4r: 4-node, rectangular quadrilaterals, tria3: 3-node triangles, hex8r: 8-node, rectangular hexahedrons, tet4: 4-node tetrahedrons. |
| order        | 1, 2, 3, 4, 5, 6, 7, 8, 9 | Convergence rate of the solver. 1: Finite volume solver (P0 elements), 2-9: ADER-DG solver (P1-P8 elements). |
| mode         | release, debug, release+san, debug+san | Compile mode. release: fastest option for use in production configurations, debug: debug flags and disabled optimizations, release+san (gnu and clang): same as release, but with enabled undefined behavior and address sanitizers, debug+san (gnu and clang): same as debug, but with enable undefined behavior and address sanitizers. |
| arch         | host, snb, hsw, knl | Targeted architecture. host: uses the architecture of the machine compiling the code, snb: SandyBridge, hsw: Haswell, knl: KnightsLanding. |
| precision    | 32, 64         | Floating point precision in bit. 32: single precision arithmetic, 64: double precision arithmetic. |
| parallel     | none, omp, mpi, mpi+omp | Shared and distributed memory parallelization. none: disabled, omp: OpenMP only, mpi: MPI only, mpi+omp: hybrid parallelization with MPI and OpenMP. |
| cov          | yes, no        | Support for code coverage reports. |
| tests        | yes, no        | Unit tests. yes: builds unit tests in the separate binary `tests`. |
| build_dir    | /path/to/build_dir | Path to the build-directory. Temporary files and the final executable(s) are stored in the build-directory. |
| xsmm         | yes, no, path/to/xsmm | LIBXSMM support. Available only for ADER-DG and elastics. |
| zlib         | yes, no, path/to/zlib | zlib support. |
| hdf5         | yes, no, path/to/hdf5 | hdf5 support. |
| netcdf       | yes, no, path/to/netcdf | NetCDF support. |
| moab         | yes, no, path/to/netcdf | MOAB support. If MOAB is enabled, EDGE is build with support for unstructured meshes. If disabled, EDGE is build with support for regular meshes. |
| inst         | yes, no | EDGE's high-level code instrumentation through the Score-P library. |
