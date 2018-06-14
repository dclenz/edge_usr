# EDGE-V

EDGE Velocity (EDGE-V) is a tool used to annotate the meshes with velocity model data. It is developed based on [Unified Community Velocity Model](http://scec.usc.edu/scecpedia/UCVMC) (UCVM), which is the data source, and [Mesh-Oriented datABase](http://sigma.mcs.anl.gov/moab-library) (MOAB).

## System and Software Requirements

EDGE-V works with the following operating systems and software stacks.

*  CentOS 7 Linux x86_64-linux 
*  GNU gcc compilers version 4.8.5
*  MPI C/C++ compilers - openmpi 1.8.8 or mpich 1.2.6 or Intel MPI compilers
*  Autotools build software for Linux
*  Unified Community Velocity Model C-language (UCVMC) library: https://scec.usc.edu/scecpedia/UCVMC
*  Proj.4 projection library: http://trac.osgeo.org/proj/ (provided in UCVMC)
*  Mesh-Oriented datABase (MOAB) library: http://sigma.mcs.anl.gov/moab-library/ (contained in submodules of EDGE)


## Build Instructions

### UCVMC

To set up the UCVM C-interface library, please follow the commands below:

```bash
git clone https://github.com/SCECcode/UCVMC.git
cd UCVMC/largefiles
./get_large_files.py
./check_largefiles_md5.py
./stage_large_files.py
cd ..
./ucvm_setup.py
```

During the installation process in `./ucvm_setup.py`, it is recommended to install all the libraries and models to get the full support. Be aware that it will occupy a large amount of storage.
Please refer to [UCVMC repo](https://github.com/SCECcode/UCVMC#ucvmc) for detailed intructions.

### MOAB

Please refer to EDGE's [installation guide](https://usr.dial3343.org/chapters/install/edge.html) for compatible setup.

### EDGE-V

Finally, to build EDGE-V tool, please run the following command:

```bash
PREFIX=$(pwd) make MOABDIR="path_to_MOAB" UCVMDIR="path_to_UCVMC" PROJ4DIR="path_to_Proj_4" 
```
The paths to MOAB library and UCVMC library are required. If `PROJ4DIR` is not provided, the Proj.4 library within UCVMC will be searched and used. By default, the released tool is in `$(pwd)`. Please set `PREFIX` to change it.

One can also set up the dependent libraries in the `Makefile.inc` file, and simply run:
```bash
make
```

**NOTE**: The default C++ compiler to build EDGE-V is the MPI compiler because MOAB and its dependency are usually built as MPI version. Be careful when switching to GNU C++ compiler.



## Usage

### Overview

To use the EDGE-V tool for annotation, simply run:

```bash
./bin/edge_v -f config_file.log
```

Here `config_file.log` is the path to the annotation configuration file. There is an example configuration in `./example/annotation.conf`:

```bash
# initialization params for UCVMC
ucvm_config=./example/ucvm.conf
ucvm_model_list=cvmh
ucvm_cmode=UCVM_COORD_GEO_ELEV
ucvm_type=2

# other params
min_vp=1500.0
min_vs=500.0
min_vs2=1200.0
max_vp_vs_ratio=3.0

elmts_per_wave=20.0

proj_mesh=+proj=tmerc +units=m +axis=enu +no_defs +datum=WGS84 +k=0.9996 +lon_0=-117.916 +lat_0=33.933
proj_vel=+proj=latlong +datum=WGS84

# input mesh file path
mesh_file=./meshes/ucvm_mini.msh

# output file path
node_vm_file=./meshes/ucvm_mini_node.vel
elmt_vm_file=./meshes/ucvm_mini_elmt.vel
h5m_file=./meshes/ucvm_mini_vmtags.h5m
```

All the settings are required. 
* `ucvm_config` : 
    The configuration file for UCVM. There is a reference config file at `$(UCVMDIR)/conf/ucvm.conf`.
    (correspondent to the argument of `-f` option in `ucvm_query`)

* `ucvm_model_list` :
    The sub-model used to provide velocity model data.
    (correspondent to the argument of `-m` option in `ucvm_query`)

**Note**: For details in the UCVMC initial parameters, please refer to [UCVMC wiki](https://github.com/SCECcode/UCVMC/wiki).

* `min_vp`, `min_vs`, `min_vs2`, `max_vp_vs_ratio`:
    Parameters used for adjustment of the velocity model in the upper layers (see [High-F](https://scec.usc.edu/scecpedia/HighF_2018)).

* `trafo_x`, `trafo_y`, `trafo_z` (optional): Transformation, applied to the mesh nodes, before querying the UCVM. The three-valued vectors are space-separated. For example, if `trafo_x=0.5 0.0 0.5`, the x-coordinate of every node in the query, would be `0.5*x + 0.5*z`.
* `elmts_per_wave` :
    Number of targeted elements per wavelength when performing mesh refinement (see corresponding section below).

* `proj_mesh` :
    Projection, used for deriving the Cartesian coordinates of the mesh.
* `proj_vel` :
    Projection, used for querying the velocity model.

* `mesh_file` :
    The input mesh file in Gmsh’s native “MSH” ASCII file format.
* `node_vm_file` :
    The output velocity model data for all the nodes in the mesh in ASCII file format.
    The velocity model data is parameterized as `lambda`, `mu` and `rho`.

* `elmt_vm_file` :
    The output velocity model data for all the tets in the mesh in ASCII file format.
    The velocity model data is parameterized as `lambda`, `mu` and `rho`.

* `h5m_file` :
    The output mesh file with velocity model annotation in H5M file format.
    The velocity model data is parameterized as `lambda`, `mu` and `rho`, recorded as dense, 4-byte tags for only tetrahedron elements in the mesh. Each 4-byte data is interpreted as a single-precision floating-point number for use.

### Example

A basic example is provided with `example/annotation.conf`. First, download the mini mesh:

```bash
mkdir -p meshes
wget https://bitbucket.org/3343/edge_opt/raw/HEAD/tools/edge_v/meshes/ucvm_mini.msh -O ./meshes/ucvm_mini.msh
```

Change the `ucvm_config` setting in `example/annotation.conf` to the path of the reference config file in UCVMC (could be found at `${UCVMC_DIR}/conf/ucvm.conf`), and run the following command:

```bash
~bash $ ./bin/edge_v -f example/annotation.conf 
Reading Annotation Config File: example/annotation.conf... Done!
Reading Mesh File: ./meshes/ucvm_mini.msh... 
 | Number of vertices is 13789
 | Number of elements is 58232
Done!
UCVM Query... Done!
Write Velocity Model: ./meshes/ucvm_mini_node.vel... Done!
No fault input files... Skipping fault annotation
Writing Velocity Model: ./meshes/ucvm_mini_elmt.vel... Done!
Writing Annotated Mesh File: ./meshes/ucvm_mini_vmtags.h5m... Done!
```

This should output the same logging info as above. The velocity model files and the annotation file are generated in `meshes/`.


## Velocity Model based Mesh Refinement

<img style="float: right;" src="https://scec.usc.edu/scecwiki/images/thumb/6/62/Base_lahabra-win1.png/250px-Base_lahabra-win1.png">

Here is an example of a velocity based mesh refinement for the [La Habra simulation region](https://scec.usc.edu/scecpedia/La_Habra_Simulation_Region). A script is provided (`mesh_refinement.sh`) to perform iterative mesh refinement in order to generate a final refined mesh that is based on the UCVM model [CVM-S4.26.M01](https://github.com/SCECcode/UCVMC/wiki/Registered-CVMs).

First, change the `ucvm_config` setting inside `./example/la_habra_small.conf` to the path of the reference config file in UCVMC (could be found at `${UCVMC_DIR}/conf/ucvm.conf`).

Next, we need to download the `la_habra_small.geo` file:
```bash
mkdir -p meshes
wget https://bitbucket.org/3343/edge_opt/raw/HEAD/tools/edge_v/meshes/la_habra_small.geo -O ./meshes/la_habra_small.geo
```

The script (`mesh_refinement.sh`) uses this geo file to produce an initial (coarse) mesh which is used as an input to the `write_pos` program in order to generate a background velocity map (pos file) based on UCVM. The subsequent mesh generation uses this background pos file and generates a refined mesh.

The script automatically tries to export the location of the `write_pos` program (typically `./bin/`) to the system environment variable PATH. In case of failure, the user needs to ensure `write_pos` exists and manually export its location to PATH by typing the following command in terminal:
```bash
export PATH="path_to_edge_v"/bin:$PATH
```

Command line arguments for `mesh_refinement.sh` are:

| Argument | Result                                         |
| :--:     | --                                             |
| `-m`     | Model name (required)                          |
| `-c`     | Config directory (required)                    |
| `-o`     | Mesh directory (required)                      |
| `-p`     | Handling intermediate mesh files (optional). 1: Generate and zip intermediate files (done by default), 2: Generate but don't zip intermediate files, 3: Do not generate intermediate files (i.e. only generate refined mesh)    |
| `-n`     | Number of iterations (optional, by default 10) |
| `-r`     | Remote meshing (optional, by default 0)        |
| `-u`     | Remote username (optional)                     |
| `-d`     | Remote domain name (optional)                  |
| `-g`     | Remote location of Gmsh executable (optional)  |
| `-t`     | Remote mesh directory (optional)               |

The bare minimum arguments required to run the script are `-m, -c, -o`, as shown below.
```bash
./mesh_refinement.sh -m la_habra_small -c ./example/ -o ./meshes/ 2>&1 | tee mesh_refinement.sh.log
```
The model name (`-m`) is the same name as the geo file (case-sensitive), in this case `la_habra_small`. We set the config directory (`-c`) to `./example/` as the `la_habra_small.conf` file resides there. The mesh directory (`-o`) is the directory containing the geo file and is the directory where all mesh related files (`.msh, .pos, .log, .tar.gz`) will be generated and stored (`./meshes/`). The above command also logs the script's output to a log file (`mesh_refinement.sh.log`), which can be very useful for debugging purposes.


The next two arguments (`-p` and `-n`) are optional and independent of the rest of the arguments. The first argument (`-p`) controls how we handle intermediate files (`.msh`, `.msh.log`, `.pos`, `.pos.log`). There are 3 options available to us:
1. Generate and zip (`.tar.gz`) intermediate files (done by default; one for each intermediate iteration)
2. Generate but don't zip intermediate files
3. Do not generate intermediate files (i.e. only generate refined mesh)

The other argument (`-n`) specifies the number of intermediate mesh iterations to be performed (10 by default; 10 is the total number of iterations, i.e. 9 intermediate + 1 final)
```bash
./mesh_refinement.sh -m la_habra_small -c ./example/ -o ./meshes/ -p 3 -n 5 2>&1 | tee mesh_refinement.sh.log
```

The rest of the arguments (`-u`, `-d`, `-g`, `-t`) are controlled by the remote meshing argument (`-r`) and are active only when `-r` is set to 1 (0 by default). This is a provision to utilize any high clock-speed CPU rack (that you have access) to perform the heavy-duty meshing operations and transmit intermediate files back and forth between the local machine and the remote client automatically. The script will fail to run if `-r` is set to 1 but any of the other arguments (`-u`, `-d`, `-g`, `-t`) is missing.

**IMPORTANT: Do note that this will require you to have a working SSH public key ([ssh-keygen](https://help.github.com/articles/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent/)) established with the remote client and [Gmsh](http://gmsh.info/) to have been installed on the remote client somewhere (we will need this location for `-g`)**.

If you are using the above-mentioned remote meshing provision, then set your ssh username (`-u`), remote-client domain (`-d`), Gmsh executable path on the remote client (`-g`) and the mesh directory on the remote client (`-t`) to store the intermediate files. For example, if the ssh login credentials to the remote client look like `ssh myuser@remote.client.domain`, run the following command in the terminal:
```bash
./mesh_refinement.sh -m la_habra_small -c ./example/ -o ./meshes/ -r 1 -u myuser -d remote.client.domain -g /home/myuser/path-to/gmsh-3.0.6-Linux64/bin/gmsh -t /home/myuser/path-to/la_habra_small/ 2>&1 | tee mesh_refinement.sh.log
```

At the end of the iterations, a final refined mesh file (`./meshes/la_habra_small_refined.msh`) is generated and this file can now be used with `edge_v` (see below command) to generate the velocity-information annotated h5m file of the La Habra simulation region. To do so, either rename the final refined mesh file to `./meshes/la_habra_small.msh` in order to avoid changing the config file OR change the input mesh file path inside `./example/la_habra_small.conf` to point to the final refined mesh, i.e. line 42 now reads `mesh_file=./meshes/la_habra_small_refined.msh`.

```bash
./bin.edge_v -f ./example/la_habra_small.conf
```

This process of mesh refinement can be repeated for any other model for which you have the geo file. Simply use the geo filename as model argument (`-m`) and make sure your other arguments are correct.
