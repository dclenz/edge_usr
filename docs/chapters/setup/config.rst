Configuration
=============
EDGE uses XML-files for build- and runtime-configurations.
Using XML-input for building EDGE through ``--xml=[...]`` is optional.
All build arguments might also be passed to SCons directly.
In contrast, passing XML-input for the runtime configuration through ``-x [...]`` is mandatory.
Except for the verbose flag ``-v``, no other command-line arguments are accepted.

XML-tree
--------
The following shows an overview of all XML-nodes in EDGE.
Dependent on the build-type, only a subset of the nodes is active.
For example, a given velocity model (``<velocity_model>``) is only parsed for seismic problems.
The comment ``<!-- [...] -->`` indicates, that a node is allowed to appear multiple times in the XML-tree.
.. code-block::

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
      <moab/>
      <inst/>
    </build>

    <cfr>
      <mesh>
        <!-- regular meshes only -->
        <n_elements>
          <x/>
          <y/>
          <z/>
        </n_elements>
        <size>
          <x/>
          <y/>
          <z/>
        </size>

        <!-- unstructured meshes only -->
        <files>
          <in/>
          <out/>
        </files>
        <options>
          <read/>
        </options>

        <!-- regular and unstructured meshes -->
        <!-- boundary tags currently ignored -->
        <boundary>
          <free_surface/>
          <outflow/>
          <rupture/>
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
        <point_sources>
          <file/>
          <!-- [...] -->
        </point_sources>

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

        <error_norms>
          <type/>
          <file/>
        </error_norms>
      </output>
    </cfr>
  </edge>

<edge>
------
The node ``<edge>`` is the root of both, the runtime- and the build-configuration.

.. _sec-setup-config-build:

<build>
-------
The node ``<build>`` describes the build-configuration and is only used by SCons.
EDGE also parses ``<build>`` at runtime, however the information is only logged and does not influence runtime behavior.

+--------------+----------------------------------------+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
|    Attribute | Allowed Values                         | Description                                                                                                                                                                         |
+==============+========================================+=====================================================================================================================================================================================+
| cfr          | 1, 2, 4, 8, 12, 16                     | Number of concurrent/fused forward runs. 1, 4, 8, and 16 are typically used.                                                                                                        |
+--------------+----------------------------------------+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| equations    | advection, elastic, swe                | Equations solved. advection: advection equation, elastic: elastic wave equations, swe: shallow water equations.                                                                     |
+--------------+----------------------------------------+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| element_type | line, quad4r, tria3, hex8r, tet4       | Element type used for spatial discretization. line: line elements, quad4r: 4-node, rectangular quads, tria3: 3-node triangles, hex8r: 8-node, rectangular hexes, tet4: 4-node tets. |
+--------------+----------------------------------------+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| order        | 1, 2, 3, 4, 5, ..                      | Convergence rate of the solver. 1: Finite volume solver (P0 elements), 2-9: ADER-DG solver (P1-P8 elements).                                                                        |
+--------------+----------------------------------------+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| mode         | release, debug, release+san, debug+san | Compile mode. release: fastest option, debug: debug flags and disabled optimizations, debug/release+san (gnu and clang): same as debug/release, but with sanitizers.                |
+--------------+----------------------------------------+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| arch         | host, snb, hsw, knl, skx, knm, avx512  | Targeted architecture. host: uses the architecture of the machine compiling the code, snb: Sandy Bridge, hsw: Haswell, knl: Knights Landing, skx: Skylake, knm: Knights Mill        |
+--------------+----------------------------------------+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| precision    | 32, 64                                 | Floating point precision in bit. 32: single precision arithmetic (recommended), 64: double precision arithmetic.                                                                    |
+--------------+----------------------------------------+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| parallel     | none, omp, mpi, mpi+omp                | Shared and distributed memory parallelization. none: disabled, omp: OpenMP only, mpi: MPI only, mpi+omp: hybrid parallelization with MPI and OpenMP.                                |
+--------------+----------------------------------------+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| cov          | yes, no                                | Support for code coverage reports.                                                                                                                                                  |
+--------------+----------------------------------------+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| tests        | yes, no                                | Unit tests. yes: builds unit tests in the separate binary `tests`.                                                                                                                  |
+--------------+----------------------------------------+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| build_dir    | /path/to/build_dir                     | Path to the build-directory. Temporary files and the final executable(s) are stored in the build-directory.                                                                         |
+--------------+----------------------------------------+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| xsmm         | yes, no, path/to/xsmm                  | LIBXSMM support. Available only for ADER-DG and elastics.                                                                                                                           |
+--------------+----------------------------------------+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| zlib         | yes, no, path/to/zlib                  | zlib support.                                                                                                                                                                       |
+--------------+----------------------------------------+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| hdf5         | yes, no, path/to/hdf5                  | hdf5 support.                                                                                                                                                                       |
+--------------+----------------------------------------+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| moab         | yes, no, path/to/moab                  | MOAB support. If MOAB is enabled, EDGE is build with support for unstructured meshes. If disabled, EDGE is build with support for regular meshes.                                   |
+--------------+----------------------------------------+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| inst         | yes, no                                | EDGE's high-level code instrumentation through the Score-P library.                                                                                                                 |
+--------------+----------------------------------------+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+

<cfr>
-----
The node ``<cfr>`` describes the runtime configuration of the forward simulations.
``<cfr>`` does not hold any attributes.
In the case of fused simulations, children of ``<cfr>`` are either shared among all forward simulations or describe varying configurations from run to run.
An example of a shared configuration is the child ``<mesh>``.

<mesh>
------
``<mesh>`` describes the used mesh of all, possibly fused, simulations.
Two configurations are possible: 1) Regular meshes, and 2) unstructured meshes.

In the case of a **regular mesh**, the configuration is given by the number of elements in every coordinate-direction and the correspoding size of the computational domain.
Regular meshes originate at :math:`(0,0,0)`.
The remaining corners are given by the size of the domain.

+------------+------------------------------+-----------------------------------------------------------------------+
| Node       | Attributes                   | Description                                                           |
+============+==============================+=======================================================================+
| n_elements | ``<x/>``, ``<y/>``, ``<z/>`` | Number of elements in the three coordinate directions.                |
|            |                              | For two-dimensional setups ``<z/>`` is ignored.                       |
|            |                              | For one dimensional setups, both, ``<z/>`` and ``<y/>``, are ignored. |
+------------+------------------------------+-----------------------------------------------------------------------+
| size       | ``<x/>``, ``<y/>``, ``<z/>`` | Size of the computational domain in the three coordinate directions.  |
+------------+------------------------------+-----------------------------------------------------------------------+
|            |                              | For two-dimensional setups ``<z/>`` is ignored.                       |
+------------+------------------------------+-----------------------------------------------------------------------+
|            |                              | For one dimensional setups, both, ``<z/>`` and ``<y/>``, are ignored. |
+------------+------------------------------+-----------------------------------------------------------------------+

**Unstructured meshes** are read from disk (or an equivalent storage).

+------------+-----------------------+-------------------------------------------------------------------------------------------------------------------------------+
| Node       | Attributes            | Description                                                                                                                   |
+============+=======================+===============================================================================================================================+
| files      | ``<in/>``, ``<out/>`` | ``<in/>``: path to the input-mesh, ``<out/>``: path to the output-mesh as parsed by EDGE (optional, typically for debugging). |
|            |                       | All mesh formats supported by MOAB are allowed.                                                                               |
+------------+-----------------------+-------------------------------------------------------------------------------------------------------------------------------+
| options    | ``<read/>``           | ``<read/>``: options forwarded to MOAB for mesh-input.                                                                        |
|            |                       | Non-empty default is the empty string "".                                                                                     |
|            |                       | MPI default is "PARALLEL=BCAST_DELETE; PARALLEL_RESOLVE_SHARED_ENTS; PARTITION=PARALLEL_PARTITION;".                          |
+------------+-----------------------+-------------------------------------------------------------------------------------------------------------------------------+

The setup of boundary conditions is shared among regular and unstructured meshes.
However, the runtime parameters are ignored for the time being, but will allow for user-defined tags in future.
For the time being: Use tag 101 for free surface boundaries, 105 for outflow boundaries and 201 for internal dynamic rupture boundaries in your meshes.


<velocity_model>
----------------
The node ``<velocity_model>`` describes the used velocity model, currently limited to the three elastic material parameters, given by the mass density :math:`\rho` and the two Lame parameters :math:`\mu` and :math:`\lambda`.
Alternatively, the velocity model can be defined as part of the mesh (see Sec. :doc:`../tools/edge_v`)
We utilize EDGE's generic domain approach for the velocity model.
Here, we define one or more domains for a velocity model, each of which allows for a constant set of material parameters.

+------------+--------------------------------+--------------------------------------------------------------------------------------------+
| Node       | Nodes/Attributes               | Description                                                                                |
+============+================================+============================================================================================+
| domain     | ``<half_space/>``, ``<rho/>``, | ``<half_space>``: One or more half-spaces building the domain (see separate description)., |
|            | ``<lambda/>``, ``<mu/>``       | ``<rho/>``: mass density :math:`\rho`,                                                     |
|            |                                | ``<lambda/>``: Lame parameter :math:`\lambda`,                                             |
|            |                                | ``<mu/>``: Lame parameter :math:`\mu`                                                      |
+------------+--------------------------------+--------------------------------------------------------------------------------------------+

<domain>
------------------
The node ``<domain>`` describes EDGE's generic domain approach and might be used to describe different geometric settings.
A domain is defined by a set of geometric entities, currently limited to half-spaces.
When searching for the corresponding domain of an element in the mesh, EDGE iterates from top to bottom through the defined domains.
The first domain, which contains the element, is the one from which the respective parameters are read.
E.g., if domains are used to describe the velocity model in a fully elastic setting, we would store the mass density :math:`\rho` and the two Lame parameters :math:`\mu` and :math:`\lambda` for every domain.

For a single domain itself, the domain contains the element if and only if all geometric entities of the domain contain the element.

+------------+-------------------------------------------+
| Node       | Description                               |
+============+===========================================+
| half_space | One or more descriptions of a half-space. |
+------------+-------------------------------------------+

<half_space>
------------
The node ``<half_space>`` describes a half-space as geometric entity of a domain.
Each half-space consist of an origin and a normal.
The origin shifts the hyperplane in space, while the normal gives the orientation of the hyperplane.
Points on the side of the hyperplane, to which the normal points, are considered to be in the half-space.
Points on the hyperplane itself and within a small error margin are typically considered to be inside the half-space.
This, however, might depend on where the ``<half_space>``-node is used.
All other points are outside.

+------------+------------------------------+-----------------------------------------------------------------------------------------+
| Node       | Attributes                   | Description                                                                             |
+============+==============================+=========================================================================================+
| origin     | ``<x/>``, ``<y/>``, ``<z/>`` | x-, y- and z- coordinates of the origin.                                                |
|            |                              | For two-dimensional setups ``<z/>`` is ignored.                                         |
|            |                              | For one dimensional setups, both, ``<z/>`` and ``<y/>``, are ignored.                   |
+------------+------------------------------+-----------------------------------------------------------------------------------------+
| normal     | ``<x/>``, ``<y/>``, ``<z/>`` | x-, y- and z- coordinates of the normal. For two-dimensional setups ``<z/>`` is ignored.|
|            |                              | For one dimensional setups, both, ``<z/>`` and ``<y/>``, are ignored.                   |
+------------+------------------------------+-----------------------------------------------------------------------------------------+

<setups>
--------
The node `<setups>` describes the setups of the fused simulations.
A setup is given by initial values or source terms, and the shared end time of all fused simulations.

+---------------+-----------------+---------------------------------------------------------------------------------------------------+
| Node          | Attributes      | Description                                                                                       |
+===============+=================+===================================================================================================+
| point_sources | ``<file/>``     | One or more HDF5-files, each containing a point source description for a single fused simulation. |
+---------------+-----------------+---------------------------------------------------------------------------------------------------+
| end_time      |                 | End time of the fused simulations.                                                                |
+---------------+-----------------+---------------------------------------------------------------------------------------------------+

<output>
--------
EDGE supports three types of simulation output, summarized by the node ``<output/>``.
The different types can be activated separately:

* Wave field output writes all quantities for the constants modes of all fused simulations and elements.
  A fixed sampling interval determines the frequency of the wave field output.
  As a side-effect, wave field output enforces synchronization of the entire simulation.
  Thus, if enabled, the last time step before each output point is adjusted to match the desired time exactly.
* Receivers write point-wise output of all quantities for all fused simulations.
  The polynomial basis is evaluated accordingly.
  To match output points between two time steps in time, an ADER time prediction is evaluated.
* Convergence settings might write errors in the L1-, L2-, and :math:`\text{L}^\infty` norm.
  The errors are computed at the end of simulation by comparing the obtained result to the analytical reference solution through quadrature rules.
  Here, we use oversample the error computation by using a quadrature rule one order above the DG-solution.
  As usual, errors for all quantities and all fused simulations are written.
