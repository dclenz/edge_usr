Introduction
============
Hey there, you have reached the user guide of the Extreme-scale Discontinuous Galerkin Environment (EDGE).
EDGE uses the Discontinuous Galerkin (DG-) Finite Element Method (FEM) to solve hyperbolic partial differential equations.
EDGE supports different equations and element types.

Currently, the applications focus is on seismic simulations through the elastic wave equations and on unstructured tetrahedral meshes.
Here, EDGE targets seismic model setups with high geometric complexity and extreme-scale ensemble simulations.
The entire software stack is uniquely tailored to "fused" simulations.
Fused simulations allow for different model setups within one execution of the forward solver.
For example, you could share the mesh and velocity model in the fused runs, but alter the kinematic source from run to run.
This approach allows the code to exploit inter-simulation parallelism and reach significantly higher simulation throughput.
Typically, the speedup is around 2-5 times, depending on the configuration.
In short: Fusing simulations makes the code faster.

EDGE is distributed across different resources.
First of all, there is this user guide, which you are currently reading.
The main purpose of the user guide is to guide you through the installation of the code and the setup of simulations.
Be warned, we just started writing and important chapters might be missing.
If you run into trouble, use one of the issue trackers and we'll have a look at it together.
This user guide's issue tracker is available at :edge_usr_git:`issues`, the issue tracker of the code at :edge_git:`issues`.

The next resource is the :edge_git:`software <>` itself.
EDGE only provides source code, which is nice because you can always look at the guts of the software, but requires you to go through the compilation yourself.
Then there are the :edge_opt:`assets <>`, which are example setups, and supporting scripts and data.
For example, this is the place where setups for benchmarks and unit tests are hosted.
EDGE's :edge_dev_pub:`developer guide <>` describes what's going on under the hood of the code.
Finally, EDGE's :dial3343:`homepage <>` provides up-to-date information on the Extreme-scale Discontinuous Galerkin Environment.
To reach any of EDGE's other resources, consider using the :dial3343:`dispatcher <dispatcher>`

BSD 3-Clause and CC0
-----------------------------------
`Disclaimer:` We do not provide legal advice.
The provided information is incomplete and is not a substitute for legal advice.

EDGE's :edge_git:`core <>` is licensed under the BSD 3-Clause license.
This does not apply to dependencies and used libraries.
Libraries are either directly located in the directory ``submodules`` or included through ``.gitmodules``.
For the master branch the directory is located :edge_git:`here <tree/master/submodules>` and ``.gitmodules`` located :edge_git:`here <tree/master/.gitmodules>`.
EDGE's automated FOSSA-reports might be helpful for further details on the licenses:


.. image:: https://app.fossa.io/api/projects/git%2Bhttps%3A%2F%2Fgithub.com%2F3343%2Fedge.svg?type=large
  :alt: FOSSA Status
  :target: https://app.fossa.io/projects/git%2Bhttps%3A%2F%2Fgithub.com%2F3343%2Fedge?ref=badge_large

The sources of this user guide, and the sources of EDGE's :edge_dev_git:`developer guide <>` are CC0'd.
An `FAQ <https://wiki.creativecommons.org/wiki/CC0_FAQ>`_ on CC0 is provided by `Creative Commons <https://creativecommons.org/>`_.

EDGE's :edge_opt:`assets <>` follow a mixed approach.
Software-components, e.g., configurations for EDGE's core, or scripts, are BSD Clause-3.
Other, non-software files, e.g., generated meshes, or source-input are CC0'd to a large extend.
However, if, for example, used topography of a mesh is provided under the `CC BY license <https://creativecommons.org/licenses/by/4.0/>`_, a mesh might not be CC0'd.