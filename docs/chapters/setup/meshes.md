# Meshes
This section describes how to use meshes in EDGE.

## Unstructured Meshes
Assume that you created a mesh `loh1_ext_small_16.msh` in gmsh with a total of 16 partitions and would like to use it in EDGE.
While you could provide the gmsh-mesh directly to EDGE, this would result in considerable overhead when MOAB parses the mesh.
Therefore, we recommend converting the mesh to the MOAB-native HDF5-format before running simulations.

### mbconvert
You can use MOAB's `mbconvert` for this purpose, e.g.:

```
mbconvert -t loh1_ext_small_16.msh loh1_ext_small_16.h5m
```

### mbpart
Similar, if your mesh `loh1_ext_small.msh` is not partitioned already, you can use the tool `mbpart` to do both steps:

```
mbpart 4 loh1_ext_small.msh loh1_ext_small_4.h5m -m ML_KWAY
```

MOAB's native format alone works for moderate sizes of your mesh.
However, for large-scale setups, we have to consider how the mesh is parsed.
EDGE's default is given by MOAB's `PARALLEL=BCAST_DELETE` option, which means that one rank reads the entire mesh from disk and broadcasts it to all other rank.
All of the ranks then extract their required information and delete the remainder.
This default mode has two severe drawbacks at scale: 1) The file-input is sequential, and 2) the entire mesh has to fit on a single rank.

Therefore, at scale, we use a different approach, which allows for parallel file-input and ensures that every rank only reads what is required.
For partitioning, we use the option `--reorder` in `mbpart`, e.g.:

```
mbpart 4 loh1_ext_small.msh loh1_ext_small_4.h5m -m ML_KWAY --reorder
```
This will order the entities by their owning rank, thus it is sufficient for every rank to read the corresponding part of the file.

After reordering the entities, we have to make EDGE aware of this by overwriting the default behavior for mesh-input.
This is accomplished by forwarding `READ_PART` to MOAB through the `<read/>` attribute in the mesh`s runtime configuration:

```
<edge>
  <build><!-- build options --></build>
  <cfr>
    <mesh>
      <options>
        <read>PARALLEL=READ_PART;PARALLEL_RESOLVE_SHARED_ENTS;PARTITION=PARALLEL_PARTITION;</read>
      </options>
      <!-- additional mesh parameters -->
    </mesh>
  <!-- additional runtime options -->
  </cfr>
</edge>
```

#### Issues and hints:
* MOAB 4.9.2 segfaults when using `mbpart` if compiled sequentially as described in section MOAB. Compile an MPI-parallel version for this, sequential execution is ok though.
* Writing partitioned meshes (`*h5m`) to file systems with disabled locking fails for HDF5 1.10.1 , e.g. NERSC's Cori:
```
HDF5-DIAG: Error detected in HDF5 (1.10.1) MPI-process 0:
[...]
  #003: H5FDsec2.c line 940 in H5FD_sec2_lock(): unable to lock file, errno = 524, error message = 'Unknown error 524'
    major: File accessibilty
    minor: Bad file ID accessed
[...]
```
As a workaround, execute `mbpart` with the environment variable `HDF5_USE_FILE_LOCKING` set to `FALSE`.
Details are in [HDF5 1.10.1's release notes](https://support.hdfgroup.org/ftp/HDF5/releases/ReleaseFiles/hdf5-1.10.1-RELEASE.txt).
* EDGE looses bit-reproducibility for different rank-counts in the reordering step, because reordering leads to different mappings to the reference element.

## Entity Types
EDGE parses the entity types (integer) specified in the mesh, e.g. you could use integer 105 to encode free-surface boundary conditions of faces.
