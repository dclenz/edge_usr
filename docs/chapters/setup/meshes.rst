Meshes
======
This section describes how to use meshes in EDGE.

Unstructured Meshes
-------------------
Assume that you created a mesh ``loh1_ext_small_16.msh`` in gmsh with a total of 16 partitions and would like to use it in EDGE.
While you could provide the gmsh-mesh directly to EDGE, this would result in considerable overhead when MOAB parses the mesh.
Therefore, we recommend converting the mesh to the MOAB-native HDF5-format before running simulations.
You can use MOAB's ``mbconvert`` for this purpose, e.g.:

.. code-block:: bash

  mbconvert -t loh1_ext_small_16.msh loh1_ext_small_16.h5m

Similar, if your mesh ``loh1_ext_small.msh`` is not partitioned already, you can use the tool ``mbpart`` to do both steps:

.. code-block:: bash

  mbpart 4 loh1_ext_small.msh loh1_ext_small_4.h5m -m ML_KWAY

MOAB's native format alone works for moderate sizes of your mesh.
However, for large-scale setups, we have to consider how the mesh is parsed.
EDGE's default is given by MOAB's ``PARALLEL=BCAST_DELETE`` option, which means that one rank reads the entire mesh from disk and broadcasts it to all other rank.
All of the ranks then extract their required information and delete the remainder.
This default mode has two severe drawbacks at scale: 1) The file-input is sequential, and 2) the entire mesh has to fit on a single rank.

Therefore, at scale, we use a different approach, which allows for parallel file-input and ensures that every rank only reads what is required.
For partitioning, we use the option ``--reorder`` in ``mbpart``, e.g.:

.. code-block:: bash

  mbpart 4 loh1_ext_small.msh loh1_ext_small_4.h5m -m ML_KWAY --reorder

This will order the entities by their owning rank, thus it is sufficient for every rank to read the corresponding part of the file.

* Hint: MOAB 4.9.2 segfaults when using ``mbpart`` if compiled sequentially as described in section MOAB. Compile an MPI-parallel version for this, sequential execution is ok though.
* Warning: Be aware that (in most cases) EDGE looses bit-reproducibility for different rank-counts in this step, since the reordering leads to different mappings to the reference element.

After reordering the entities, we have to make EDGE aware of this by overwriting the default behavior for mesh-input.
This is accomplished by forwarding ``READ_PART`` to MOAB through the ``<read/>`` attribute in the mesh's runtime configuration:

::

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

Entity Types
------------
EDGE parses the entity types (integer) specified in the mesh, e.g., you could use integer 105 to encode free-surface boundary conditions of faces.
