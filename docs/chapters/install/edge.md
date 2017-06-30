# Installation
This chapter describes how the installation of EDGE and its dependencies.

## Examples
EDGE's entire installation process is continuously tested.
If you get stuck with this user guide, you might be able to find additional installation hints in the respective configurations:
* [Travis CI]({{book.edge_git}}/blob/master/.travis.yml)
* [GoCD]({{book.edge_git}}/blob/master/tools/gocd/cruise-config.tmpl)
* [Singularity]({{book.edge_git}}/blob/master/tools/singularity/debian.def)

## General Remarks
EDGE links almost all libraries statically and expects corresponding library installations.
The descriptions below are adjusted accordingly and only building static versions is described.
This is one of the reasons why manual library installations are recommended, for example, not using `sudo apt-get install` on your local machine.
`libnuma` and compiler-provided libraries, e.g., OpenMP, are the only exception.

All of the instructions below assume that you initiate the installation of each library in EDGE's root-directory and will put the installed library into the directory `libs`.
Make sure to navigate back to the root-directory before installing the next library.

## Getting the Code
EDGE's sources are hosted at {{book.edge_git}}.
The repository has two branches `master` and `develop`.
`master` is the most recent stable version of EDGE.
The minmimum acceptance requirement for `master` is passing EDGE's [continuous delivery pipeline]({{book.edge_dev_pub}}/chapters/cont/cont.html).
Periodically EDGE also provides tags, which are simply snapshots of the master branch.
Typically tags passed additional, manual testing.
We recommend to use the most recent tag to get started with EDGE.
`develop` is the bleeding edge version of EDGE.
Changes in `develop` are intended to be merged into master.
However, `develop` is for ongoing development and broken from time to time.

The procedure for obtaining the code as follows:
1. Clone the git-repository and navigate to the root-directory through:
```
git clone https://github.com/3343/edge.git
cd edge
```
This gives you the `master`-branch.
If this is what you want, jump over the next step.
2. Checkout the desired tag:
```
git checkout YY.MM.VV
```
_Remark:_ `YY.MM.VV` is a place holder.
You have to replace this with your actual tag.
Available tags are shown at the GitHub-homepage or directly through `git tag`.
3. Initialize and update the submodules:
```
git submodule init
git submodule update
```

## LIBXSMM
The single core backend of EDGE's high-performance kernels is provided through the library [LIBXSMM](https://github.com/hfp/libxsmm).
LIBXSMM is optional, but highly recommended due to severe performance-limitations of the vanilla kernels.

* Install libxsmm by running:
```
cd submodules/libxsmm; PREFIX=../../libs make BLAS=0 install
```

## zlib
zlib is a requirement for the HDF5 library.

1. Download zlib at http://zlib.net/ (tar.gz):
```
wget http://zlib.net/zlib-1.2.11.tar.gz -O zlib.tar.gz
```
2. Extract zlib to the directory `zlib`:
```
mkdir zlib; tar -xzf zlib.tar.gz -C zlib --strip-components=1
```
3. Configure the installation and set `libs` as installation directory by running:
```
cd zlib; ./configure --static --prefix=$(pwd)/../libs
```
4. Run `make` to build the library and `make install` to put it in the `libs` directory.

## HDF5
HDF5 is a requirement for the NetCDF library, which is used for kinematic source description.
Futher, we recommend building MOAB, EDGE's interface to unstructured meshes, with HDF5-support.

1. Download HDF5 at https://www.hdfgroup.org/downloads/hdf5/source-code/ (gzip):
```
wget https://www.hdfgroup.org/package/gzip/?wpdmdl=4301 -O hdf5.tar.gz
```
2. Extract HDF5 to the directory `hdf5`:
```
mkdir hdf5; tar -xzf hdf5.tar.gz -C hdf5 --strip-components=1
```
3. Configure the installation and set `libs` as installation directory.
  * Sequential:
```
cd hdf5; ZLIBDIR=$(pwd)/../libs ./configure --enable-shared=no --with-zlib=${ZLIBDIR} --prefix=$(pwd)/../libs
```
  * Parallel:
```
cd hdf5; ZLIBDIR=$(pwd)/../libs ./configure --enable-shared=no --enable-parallel --with-zlib=${ZLIBDIR} --prefix=$(pwd)/../libs
```
Make sure to check that the configuration, printed at the very end, matches your expectations.
4. Finally run `make` to build the library and `make install` to put it in the `libs` directory.

## NetCDF
NetCDF is a requirement for kinematic source descriptions, including single point sources.
The library can also be used in the installation of MOAB (unstructured mesh interface) to allow reading of exodus-meshes.

1. Download the sources ("NetCDF-C Releases") from https://www.unidata.ucar.edu/downloads/netcdf/index.jsp:
```
wget ftp://ftp.unidata.ucar.edu/pub/netcdf/netcdf-4.4.1.1.tar.gz -O netcdf.tar.gz
```

2. Extract NetCDF to the directory `netcdf`:
```
mkdir netcdf; tar -xzf netcdf.tar.gz -C netcdf --strip-components=1
```

3. Configure the installation and set `libs` as installation directory. Adjust the path to HDF5, if necessary.
Two examples:
  * Sequential:
```
cd netcdf; HDF5DIR=$(pwd)/../libs CPPFLAGS=-I${HDF5DIR}/include LDFLAGS=-L${HDF5DIR}/lib ./configure --enable-shared=no --disable-dap --prefix=$(pwd)/../libs
```
  * MPI-parallel with OpenMPI-wrapper:
```
cd netcdf; CC=mpicc HDF5DIR=$(pwd)/../libs CPPFLAGS=-I${HDF5DIR}/include LDFLAGS=-L${HDF5DIR}/lib ./configure --enable-shared=no --disable-dap --prefix=$(pwd)/../libs
```
Check that the configuration, printed at the very end matches your expectations.

4. Finally run `make` to build the library and `make install` to put NetCDF in the `libs` directory.

## MOAB
If running on unstructured meshes, you need to provide an installation of [MOAB](http://sigma.mcs.anl.gov/moab-library/).
Since ASCII-only builds of MOAB are troublesome, building with HDF5-support also for small-scale runs is recommended.

1. Generate the configure-script:
```
cd submodules/moab; autoreconf -fi
```

2. Configure the installation, three examples:
  * Sequential example using GNU compilers:
```
F77=gfortran F90=gfortran FC=gfortran CC=gcc CXX=g++ ./configure --disable-debug --enable-optimize --enable-shared=no --enable-static=yes --disable-fortran --enable-tools --enable-all-static --with-hdf5=$(pwd)/../../libs --with-netcdf=$(pwd)/../../libs --with-pnetcdf=no --with-metis=yes --download-metis --prefix=$(pwd)/../../libs
```

  * MPI-parallel example using Intel compilers:
```
F77=mpiifort F90=mpiifort FC=mpiifort CC=mpiicc CXX=mpiicpc ./configure --disable-debug --enable-optimize --enable-shared=no --enable-static=yes --with-mpi --disable-fortran --enable-tools --enable-all-static --with-hdf5=$(pwd)/../../libs --with-netcdf=$(pwd)/../../libs --with-pnetcdf=no --with-metis=yes --download-metis --prefix=$(pwd)/../../libs
```

  * MPI-parallel example using Intel compilers and Intel MPI:
```
F77=mpiifort F90=mpiifort CC=mpiicc CXX=mpiicpc RUNPARALLEL="mpiexec.hydra -n 4" ./configure --disable-debug --enable-optimize --enable-shared=no --enable-static=yes --with-mpi --disable-fortran --disable-mbcslam --enable-all-static --with-hdf5=$(pwd)/../../libs --with-netcdf=$(pwd)/../../libs --with-pnetcdf=no --with-metis=yes --download-metis --prefix=$(pwd)/../../libs
```

3. Now you can build MOAB with `make` and install it through `make install`.

## EDGE
EDGE uses [SCons](http://scons.org/) as build tool.
`scons --help` returns all of EDGE's build-options.
Additionally, this user guide describes all build options as [part](../setup/config.md/#sec_build) of the chapter [Config](../setup/config.md).

You can enable the libraries in EDGE either by passing their installation directory explicitly (recommended) or by setting the environment variables `CPLUS_INCLUDE_PATH` and `LIBRARY_PATH`.
For example, let's assume that you installed LIBXSMM in the directory `$(pwd)/libs`.
Than we could either enable LIBXSMM by passing `xsmm=$(pwd)/libs` to EDGE's SCons-script or by using `CPLUS_INCLUDE_PATH=$(pwd)/libs/include LIBRARY_PATH=$(pwd)/libs/lib scons [...] xsmm=yes`.

If something goes wrong with finding a library, EDGE will tell you so.
For example, if we did not install LIBXSMM in `/tmp`, but tell EDGE so anyways, we get:
```
scons equations=elastic order=4 cfr=1 element_type=tet4 xsmm=/tmp
[...]
Checking for C++ static library libxsmmnoblas..no
  Warning: Could not find libxsmm, continuing without.
```
Further information on what went wrong is logged in the file `config.log`, which, in this case, shows that the compiler could not find the LIBXSMM-header:
```
[...]
 scons: Configure: Checking for C++ static library libxsmmnoblas..
 .sconf_temp/conftest_2.cpp <-
   |#include <libxsmm.h>
   |int main(int i_argc, char **i_argv) { return 0; }
 g++ -o .sconf_temp/conftest_2.o -c -std=c++11 -Wall -Wextra -Wno-unknown-pragmas -Wno-unused-parameter -Werror -pedantic -Wshadow -Wundef -O2 -ftree-vectorize -DPP_N_CRUNS=1 -DPP_T_EQUATIONS_ELASTIC -DPP_T_ELEMENTS_TET4 -DPP_ORDER=4 -DPP_PRECISION=64 -I. -Isrc -I/tmp/include .sconf_temp/conftest_2.cpp
 .sconf_temp/conftest_2.cpp:1:21: fatal error: libxsmm.h: No such file or directory
 compilation terminated.
 scons: Configure: no
```

## Stack Size
In certain settings EDGE allocates substantial amounts of data on the stack.
For high-order configurations, this memory is mostly occupied by thread-private global matrix structures.
To circumvent errors due to limited stacks on Linux systems use `ulimit`. `ulimit -s` shows you the current maximum, `ulimit -s unlimited` allows unlimited sized stacks.
Server machines typically operate unlimited.
If running CentOS, you can obtain an unlimited stack as default by adding the following line to `/etc/security/limits.conf`:
```
*                -       stack            unlimited
```

## Singularity Bootstrap
[Singularity](http://singularity.lbl.gov/) is software, which allows container-based execution of HPC-codes at close-to-native performance.
EDGE provides a Debian-bootstrap for automated installation of different configurations:

| Build Option | Enabled Bootstrap Cofingurations               |
| --           | --                                             |
| element_type | tet4 (4-node tetrahedral elements)             |
| equations    | elastic (elastic wave equations)               |
| order        | 1 (FV), 2-6 (ADER-DG)                          |
| cfr          | 1 (non-fused), 8                               |
| arch         | hsw (Haswell), knl (KnightsLanding)            |
| xsmm         | yes (LIBXSMM enabled except for FV)            |
| zlib         | yes                                            |
| hdf5         | yes                                            |
| netcdf       | yes (enables kinematic sources)                |
| moab         | yes (unstructured meshes), no (regular meshes) |
| parallel     | omp (shared memory parallelization)            |

Once a container is generated, you can run it on systems with Singularity installed, without installing any further dependencies.
Example systems with Singularity support are the XSEDE-resources [Stampede](https://github.com/TACC/TACC-Singularity) and [Comet](https://github.com/zonca/singularity-comet).
If you have root-access to a system with Singularity and [debootstrap](https://wiki.debian.org/Debootstrap) installed, you can generate a container containing EDGE and all its dependencies.
1. Clone a clean copy of EDGE, including all submodules.
2. Generate an archive of EDGE's root-directory:
```
tar -czf /tmp/edge.tar.gz edge
```
3. Create a Singularity container image of with a maximum size of 8 GiB (8192 MiB):
```
sudo singularity create -s 8192 /tmp/edge.img
```
4. Import EDGE's source code:
```
sudo singularity import /tmp/edge.img /tmp/edge.tar.gz
```
You can ignore the warning `ERROR: Container does not contain the valid minimum requirement of /bin/sh`, we haven't installed anything by now, so this is fine.
5. Run the bootstrap to install the dependencies and EDGE-configurations:
```
sudo singularity bootstrap /tmp/edge.img ./debian.def
```
6. The bootstrap might run for several hours, maybe grab a coffee.
