EDGE-V
======
EDGE Velocity (EDGE-V) is a tool used to perform velocity-aware mesh refinement and annotate meshes with background data of velocity models.
It is developed based on the SCEC `Unified Community Velocity Model <https://www.scec.org/research/ucvm>`_ (UCVM), which is used as interface to different velocity models.

Dependencies
--------------------------------
EDGE-V has the following dependencies:

*  Recent C++ compiler, e.g., GCC 5
*  `SCEC Unified Community Velocity Model C-language (UCVMC) <https://github.com/SCECcode/UCVMC>`_
*  `PROJ.4 <http://trac.osgeo.org/proj/>`_ (provided as part of UCVMC)
*  `Mesh-Oriented datABase (MOAB) library <http://sigma.mcs.anl.gov/moab-library/>`_ (see Sec. :doc:`../install/edge` for details)


Build Instructions
------------------
UCVMC
^^^^^
Install UCVM's C-interface by following the commands below:

.. code-block:: bash

  git clone https://github.com/SCECcode/UCVMC.git
  git checkout v17.1.0
  cd UCVMC/largefiles
  ./get_large_files.py
  ./check_largefiles_md5.py
  ./stage_large_files.py
  cd ..
  ./ucvm_setup.py

On Cray systems, in particular Cori Phase II, use:

.. code-block:: bash

  CRAYPE_LINK_TYPE=dynamic CXX=g++ CC=gcc F77=gfortran F90=gfortran FC=gfortran ./ucvm_setup.py

During the installation process in ``./ucvm_setup.py``, it is recommended to install all the libraries and models to get the full support. Be aware that it will occupy a large amount of storage.
Please refer to the `UCVMC documentation <https://github.com/SCECcode/UCVMC/wiki/Registered-CVMs>`_ for detailed instructions.

MOAB
^^^^
Details on the MOAB isntallation are given in Sec. :doc:`../install/edge`.

EDGE-V
^^^^^^
Analogue to EDGE, EDGE-V uses SCons for the installation.
Finally, to build EDGE-V tool, please run the following command:
With a MOAB installation in ``../../libs`` and UCVM installation in ``../../libs/ucvm-17.1.0/``, the build commands reads as:

.. code-block:: bash

  scons moab=../../libs ucvm=../../libs/ucvm-17.1.0/ zlib=../../libs hdf5=../../libs netcdf=$(pwd)/../../libs

Usage
-----
Overview
^^^^^^^^

EDGE-V accepts a single command line argument, which is the configuration file (here: ``edge_v.conf``):

.. code-block:: bash

  ./edge_v -f edge_v.conf

An exemplary configuration is given below:

.. code-block:: bash

  # ucvm parameters
  ucvm_config=../../libs/ucvm-17.1.0/
  ucvm_model_list=cvmsi
  ucvm_cmode=UCVM_COORD_GEO_DEPTH
  ucvm_type=cmb

  # projections
  proj_mesh=+proj=tmerc +units=m +axis=enu +no_defs +datum=WGS84 +k=0.9996 +lon_0=-117.916 +lat_0=33.933
  proj_vel=+proj=latlong +datum=WGS84

  # trafo when scaling from mapped domain to mesh
  trafo_x=1.0 0.0 0.0
  trafo_y=0.0 1.0 0.0
  trafo_z=0.0 0.0 -1.0

  # mesh adaptivity
  refinement_center_xy=0.0 0.0
  refinement_radii_xy=20000 30000
  refinement_relative_cls=0.2 0.8

  # velocity rule
  vel_rule=highf2018

  # input mesh file
  mesh_file=gen/la_habra_small_refined.msh

  # output files
  pos_file=gen/la_habra_small.pos
  anno_file=gen/la_habra_small_refined_vmtags.h5m

In detail, the respective parameters are given as:

+-------------------------+-------------------------------------------------------------------------------------------------------------------+
| Parameter               | Description                                                                                                       |
+=========================+===================================================================================================================+
| ucvm_config             | UCVM's configuration file, which is automatically generated in the installation process.                          |
|                         | This is analogue to the ``-f`` option of the ``ucvm_query`` tool (see ``ucvm_query --help`` for details).         |
+-------------------------+-------------------------------------------------------------------------------------------------------------------+
| ucvm_model_list         | The used sub-models, which are queried for the velocity data.                                                     |
|                         | This is analogue to the ``-m`` option of ``ucvm_query``.                                                          |
+-------------------------+-------------------------------------------------------------------------------------------------------------------+
| ucvm_cmode              | Used coordinate mode, when querying UCVM.                                                                         |
|                         | Valid options are ``UCVM_COORD_GEO_DEPTH`` and ``UCVM_COORD_GEO_ELEV``.                                           |
+-------------------------+-------------------------------------------------------------------------------------------------------------------+
| ucvm_type               | Values used from the UCVM query, either ``gtl``, ``crust`` or ``cmb`` (combination of gtl and crust).             |
+-------------------------+-------------------------------------------------------------------------------------------------------------------+
| proj_mesh               | Projection, used for deriving the Cartesian coordinates of the mesh.                                              |
+-------------------------+-------------------------------------------------------------------------------------------------------------------+
| proj_vel                | Projection, used for querying UCVM                                                                                |
+-------------------------+-------------------------------------------------------------------------------------------------------------------+
| trafo_x,                | (Optional) Transformation, applied to the mesh nodes, before querying the UCVM.                                   |
| trafo_y,                | The three-valued vectors are space-separated.                                                                     |
| trafo_z                 | For example, if ``trafo_x=0.5 0.0 0.5``, the x-coordinate of every node in the query, would be ``0.5*x + 0.5*z``. |
+-------------------------+-------------------------------------------------------------------------------------------------------------------+
| refinement_center_xy    | Center in x- and y-direction of the cylinders, used for the generated Gmsh view.                                  |
+-------------------------+-------------------------------------------------------------------------------------------------------------------+
| refinement_radii_xy     | Radii of the inner and outer circle, used for the generated Gmsh view.                                            |
|                         | Vertices in the inner cylinder are assigned the first characteristic length.                                      |
|                         | Vertices outside the outer cylinder are assigned the second characteristic length.                                |
|                         | Vertices in the transition zone coarsen linearly between the provided characteristic lengths.                     |
+-------------------------+-------------------------------------------------------------------------------------------------------------------+
| refinement_relative_cls | Relative characteristic lengths of the vertices in the Gmsh view.                                                 |
|                         | The characteristic lengths are based on the s-wave velocities :math:`v_s` at 1Hz.                                 |
|                         | For example, if a vertex in the inner cylinder has a relative length of :math:`\text{cl}_\text{i}`, we set:       |
|                         | :math:`\text{cl}_v = \text{cl}_\text{i} * v_s` for the vertex's characteristic length.                            |
+-------------------------+-------------------------------------------------------------------------------------------------------------------+
| mesh_file               | Path to the mesh file, which is read.                                                                             |
|                         | Format can be everything, which MOAB supports                                                                     |
+-------------------------+-------------------------------------------------------------------------------------------------------------------+
| pos_file                | Path to the Gmsh view, which is written.                                                                          |
+-------------------------+-------------------------------------------------------------------------------------------------------------------+
| anno_file               | Path to the velocity annotated mesh file, which is written.                                                       |
|                         | Format can be everything, which MOAB supports.                                                                    |
+-------------------------+-------------------------------------------------------------------------------------------------------------------+

Vs-based Mesh Refinement
------------------------
EDGE-V's script ``mesh_refinement.sh`` performs an iterative mesh refinement to generate a final mesh, that adapts to the velocity model's s-wave velocities.
The script uses the given Gmsh-geo file to produce an initial (coarse) mesh.
This coarse mesh is used as input for ``edge_v``.
Next, the script generates a Gmsh-view, which contains the targeted characteristic lengths at the vertices.
This Gmsh-view is used to generate a new mesh and the procedure iterates by annotating the newly generated mesh.

Command line arguments for ``mesh_refinement.sh`` are:

+----------+-------------------------------------------------------------------------+
| Argument | Description                                                             |
+==========+=========================================================================+
| ``-m``   | Model name (required)                                                   |
+----------+-------------------------------------------------------------------------+
| ``-c``   | Config directory (required)                                             |
+----------+-------------------------------------------------------------------------+
| ``-o``   | Mesh directory (required)                                               |
+----------+-------------------------------------------------------------------------+
| ``-p``   | Handling intermediate mesh files (optional).                            |
|          | 1: Generate and zip intermediate files (done by default),               |
|          | 2: Generate but don't zip intermediate files,                           |
|          | 3: Do not generate intermediate files (i.e. only generate refined mesh) |
+----------+-------------------------------------------------------------------------+
| ``-n``   | Number of iterations (optional, by default 10)                          |
+----------+-------------------------------------------------------------------------+
| ``-r``   | Remote meshing (optional, by default 0)                                 |
+----------+-------------------------------------------------------------------------+
| ``-u``   | Remote username (optional)                                              |
+----------+-------------------------------------------------------------------------+
| ``-d``   | Remote domain name (optional)                                           |
+----------+-------------------------------------------------------------------------+
| ``-g``   | Remote location of Gmsh executable (optional)                           |
+----------+-------------------------------------------------------------------------+
| ``-t``   | Remote mesh directory (optional)                                        |
+----------+-------------------------------------------------------------------------+

At the end of the iterations, a final refined mesh file (``*_refined.msh``) is generated.