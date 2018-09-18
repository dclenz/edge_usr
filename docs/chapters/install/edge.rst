Installation
============
This chapter describes the installation of EDGE and its dependencies.

Examples
--------
EDGE's entire installation process is continuously tested.
If you get stuck with this user guide, you might be able to find additional installation hints in the respective configurations:

* :edge_git:`Travis CI <blob/master/.travis.yml>`
* :edge_git:`GoCD <blob/master/tools/gocd/cruise-config.tmpl>`
* :edge_git:`Singularity <blob/master/tools/singularity/debian.def>`

General Remarks
---------------
EDGE links almost all libraries statically and expects corresponding library installations.
The descriptions below are adjusted accordingly and only building static versions is described.
This is one of the reasons why manual library installations are recommended, for example, not using ``sudo apt-get install`` on your local machine.
``libnuma`` and compiler-provided libraries, e.g., OpenMP, are the only exception.

All of the instructions below assume that you initiate the installation of each library in EDGE's root-directory and will put the installed library into the directory ``libs``.
Make sure to navigate back to the root-directory before installing the next library.

Getting the Code
----------------
EDGE's sources are hosted at :edge_git:`GitHub <>`.
The repository has two branches :edge_git:`master <tree/master>` and :edge_git:`develop <tree/develop>`.
``master`` is the most recent stable version of EDGE.
The minmimum acceptance requirement for ``master`` is passing EDGE's :edge_dev_pub:`continuous delivery pipeline </chapters/cont/cont.html>`.
Periodically EDGE also provides tags, which are simply snapshots of the master branch.
Typically tags passed additional, manual testing.
We recommend to use the most recent tag to get started with EDGE.
``develop`` is the bleeding edge version of EDGE.
Changes in ``develop`` are intended to be merged into master.
However, ``develop`` is for ongoing development and broken from time to time.

The procedure for obtaining the code as follows:

1. Clone the git-repository and navigate to the root-directory through:

   .. code-block:: bash

     git clone https://github.com/3343/edge.git
     cd edge

   This gives you the ``master``-branch.
   If this is what you want, jump over the next step.

2. Checkout the desired tag:

   .. code-block:: bash

     git checkout YY.MM.VV

   `Remark:` ``YY.MM.VV`` is a place holder.
   You have to replace this with your actual tag.
   Available tags are shown at the GitHub-homepage or directly through ``git tag``.

3. Initialize and update the submodules:

   .. code-block:: bash

     git submodule init
     git submodule update

LIBXSMM
-------
The single core backend of EDGE's high-performance kernels is provided through the library `LIBXSMM <https://github.com/hfp/libxsmm>`_.
LIBXSMM is optional, but highly recommended due to severe performance-limitations of the vanilla kernels.

* Install libxsmm by running:

  .. code-block:: bash

    cd submodules/libxsmm; PREFIX=../../libs make BLAS=0 install

zlib
----
zlib is a requirement for the HDF5 library.

1. Download zlib from http://zlib.net/ (tar.gz):

   .. code-block:: bash

     wget http://zlib.net/zlib-1.2.11.tar.gz -O zlib.tar.gz

2. Extract zlib to the directory ``zlib``:

   .. code-block:: bash

     mkdir zlib; tar -xzf zlib.tar.gz -C zlib --strip-components=1

3. Configure the installation and set ``libs`` as installation directory by running:

   .. code-block:: bash

     cd zlib; ./configure --static --prefix=$(pwd)/../libs

4. Run ``make`` to build the library and ``make install`` to put it in the ``libs`` directory.

HDF5
----
HDF5 is a requirement for the NetCDF library, which is used for kinematic source descriptions.
Futher, we recommend building MOAB, EDGE's interface to unstructured meshes, with HDF5-support.
MOAB's native mesh format uses HDF5, which allows fast parsing of large meshes in parallel simulations.

1. Download HDF5 from https://www.hdfgroup.org/downloads/hdf5/source-code/ (gzip):

   .. code-block:: bash

     wget https://www.hdfgroup.org/package/gzip/?wpdmdl=11810 -O hdf5.tar.gz

2. Extract HDF5 to the directory ``hdf5``:

   .. code-block:: bash

     mkdir hdf5; tar -xzf hdf5.tar.gz -C hdf5 --strip-components=1

3. Configure the installation and set ``libs`` as installation directory.

   * Sequential:

     .. code-block:: bash

       cd hdf5; ./configure --enable-shared=no --with-zlib=$(pwd)/../libs --prefix=$(pwd)/../libs

   * Parallel:

     .. code-block:: bash

       cd hdf5; ./configure --enable-shared=no --enable-parallel --with-zlib=$(pwd)/../libs --prefix=$(pwd)/../libs

   Make sure to check that the configuration, printed at the very end, matches your expectations.

4. Finally run ``make`` to build the library and ``make install`` to put it in the ``libs`` directory.

NetCDF
------
NetCDF is a requirement for kinematic source descriptions, including single point sources.
The library can also be used in the installation of MOAB (unstructured mesh interface) to allow reading of exodus-meshes.
However, we typically use Gmsh's ASCII-format or MOAB's HDF5-format.

1. Download the sources ("NetCDF-C Releases") from https://www.unidata.ucar.edu/downloads/netcdf/index.jsp:

   .. code-block:: bash

     wget ftp://ftp.unidata.ucar.edu/pub/netcdf/netcdf-4.6.0.tar.gz -O netcdf.tar.gz

2. Extract NetCDF to the directory ``netcdf``:

   .. code-block:: bash

     mkdir netcdf; tar -xzf netcdf.tar.gz -C netcdf --strip-components=1

3. Configure the installation and set ``libs`` as installation directory. Adjust the path to HDF5, if necessary.
Two examples:

* Sequential:

  .. code-block:: bash

    cd netcdf; CPPFLAGS=-I$(pwd)/../libs/include LDFLAGS=-L$(pwd)/../libs/lib ./configure --enable-shared=no --disable-dap --prefix=$(pwd)/../libs

* MPI-parallel with OpenMPI-wrapper:

  .. code-block:: bash

    cd netcdf; CC=mpicc CPPFLAGS="-I$(pwd)/../libs/include" LDFLAGS="-L$(pwd)/../libs/lib" ./configure --enable-shared=no --disable-dap --prefix=$(pwd)/../libs

  Check that the configuration, printed at the very end matches your expectations.

4. Finally run ``make`` to build the library and ``make install`` to put NetCDF in the ``libs`` directory.

MOAB
----
If using unstructured meshes in EDGE, you need to provide an installation of `MOAB <http://sigma.mcs.anl.gov/moab-library/>`_.
Since ASCII-only builds of MOAB are troublesome, building with HDF5-support also for small-scale runs is recommended.

1. Generate the configure-script:

   .. code-block:: bash

     cd submodules/moab; autoreconf -fi

2. Configure the installation, two examples:

   * Sequential example using GNU compilers:

     .. code-block:: bash

      LIBS="$(pwd)/../libs/lib/libz.a" CC=gcc CXX=g++ ./configure --disable-debug --enable-optimize --enable-shared=no --enable-static=yes --disable-fortran --enable-tools --disable-blaslapack --with-eigen3=$(pwd)/../eigen --with-zlib=$(pwd)/../libs --with-hdf5=$(pwd)/../libs --with-netcdf=$(pwd)/../libs --with-pnetcdf=no --with-metis=yes --download-metis --prefix=$(pwd)/../../libs

   * MPI-parallel example using Intel compilers:

     .. code-block:: bash

      LIBS="$(pwd)/../libs/lib/libz.a" CC=mpiicc CXX=mpiicpc ./configure --disable-debug --enable-optimize --enable-shared=no --enable-static=yes --disable-fortran --enable-tools --disable-blaslapack --with-eigen3=$(pwd)/../eigen --with-zlib=$(pwd)/../libs --with-hdf5=$(pwd)/../libs--with-netcdf=$(pwd)/../libs --with-pnetcdf=no --with-metis=yes --download-metis --with-mpi --prefix=$(pwd)/../../libs

3. Now you can build MOAB with ``make`` and install it through ``make install``.

EDGE
----
EDGE uses `SCons <http://scons.org/>`_ as build tool.
``scons --help`` returns all of EDGE's build-options.
All build options are given in the respective :ref:`sub-section <sec-setup-config-build>` of Sec. :doc:`../setup/config`.
You can enable the libraries in EDGE either by passing their installation directory explicitly (recommended) or by setting the environment variables ``CPLUS_INCLUDE_PATH`` and ``LIBRARY_PATH``.
For example, let's assume that you installed LIBXSMM in the directory ``$(pwd)/libs``.
Than we could either enable LIBXSMM by passing ``xsmm=$(pwd)/libs`` to EDGE's SCons-script or by using ``CPLUS_INCLUDE_PATH=$(pwd)/libs/include LIBRARY_PATH=$(pwd)/libs/lib scons [...] xsmm=yes``.

If something goes wrong with finding a library, EDGE will tell you so.
For example, if we did not install LIBXSMM in ``/tmp``, but tell EDGE so anyways, we get:

.. code-block:: bash

    scons equations=elastic order=4 cfr=1 element_type=tet4 xsmm=/tmp
    [...]
    Checking for C++ static library libxsmmnoblas..no
      Warning: Could not find libxsmm, continuing without.

Further information on what went wrong is logged in the file ``config.log``, which, in this case, shows that the compiler could not find the LIBXSMM-header:

::

    [...]
    scons: Configure: Checking for C++ static library libxsmmnoblas..
    .sconf_temp/conftest_2.cpp <-
      |#include <libxsmm.h>
      |int main(int i_argc, char **i_argv) { return 0; }
    g++ -o .sconf_temp/conftest_2.o -c -std=c++11 -Wall -Wextra -Wno-unknown-pragmas -Wno-unused-parameter -Werror -pedantic -Wshadow -Wundef -O2 -ftree-vectorize -DPP_N_CRUNS=1 -DPP_T_EQUATIONS_ELASTIC -DPP_T_ELEMENTS_TET4 -DPP_ORDER=4 -DPP_PRECISION=64 -I. -Isrc -I/tmp/include .sconf_temp/conftest_2.cpp
    .sconf_temp/conftest_2.cpp:1:21: fatal error: libxsmm.h: No such file or directory
    compilation terminated.
    scons: Configure: no

Stack Size
----------
In certain settings EDGE allocates substantial amounts of data on the stack.
For high-order configurations, this memory is mostly occupied by thread-private global matrix structures.
To circumvent errors due to limited stacks on Linux systems use ``ulimit``. ``ulimit -s`` shows you the current maximum, ``ulimit -s unlimited`` allows unlimited sized stacks.
Server machines typically operate unlimited.
If running CentOS, you can obtain an unlimited stack as default by adding the following line to ``/etc/security/limits.conf``:

::

    *                -       stack            unlimited

*Be aware*, that ``unlimited`` might interfere with your system's Out Of Memory (OOM) Killer.

Singularity Bootstrap
---------------------
`Singularity <http://singularity.lbl.gov/>`_ is software, which allows container-based execution of HPC-codes at close-to-native performance.
EDGE provides a Debian-bootstrap for automated installation of different configurations:

+--------------+------------------------------------------------+
| Build Option | Enabled Bootstrap Cofingurations               |
+==============+================================================+
| element_type | tet4 (4-node tetrahedral elements)             |
+--------------+------------------------------------------------+
| equations    | elastic (elastic wave equations)               |
+--------------+------------------------------------------------+
| order        | 1 (FV), 2-5 (ADER-DG)                          |
+--------------+------------------------------------------------+
| cfr          | 1 (hsw, non-fused), 16 (knl, fused)            |
+--------------+------------------------------------------------+
| arch         | hsw (Haswell), AVX512 (knl, skl, kml)          |
+--------------+------------------------------------------------+
| xsmm         | yes (LIBXSMM enabled except for FV)            |
+--------------+------------------------------------------------+
| zlib         | yes                                            |
+--------------+------------------------------------------------+
| hdf5         | yes                                            |
+--------------+------------------------------------------------+
| netcdf       | yes (enables kinematic sources)                |
+--------------+------------------------------------------------+
| moab         | yes (unstructured meshes), no (regular meshes) |
+--------------+------------------------------------------------+
| parallel     | omp (shared memory parallelization)            |
+--------------+------------------------------------------------+

Once a container is generated, you can run it on systems with Singularity installed, without installing any further dependencies.
Example systems with Singularity support are the XSEDE-resources `Stampede <https://github.com/TACC/TACC-Singularity>`_ and `Comet <https://github.com/zonca/singularity-comet>`_.
If you have root-access to a system with Singularity and `debootstrap <https://wiki.debian.org/Debootstrap>`_ installed, you can generate a container containing EDGE and all its dependencies.

1. Adjust the EDGE-version in the bootstrap, if required (defaults to ``develop``)

2. Run the bootstrap to install the dependencies and EDGE-configurations:

   .. code-block:: bash

     sudo singularity build /tmp/edge.simg ./debian.def

3. The bootstrap might run for several hours, maybe grab a coffee.
