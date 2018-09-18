Kinematic Sources
=================
Each of EDGE's fused runs has a completely independent, non-fused kinematic source description.
This approach is the most flexible since the source description can be arbitrary.

Standard Rupture Format
-----------------------
EDGE implements the `Standard Rupture Format <http://scec.usc.edu/scecpedia/Standard_Rupture_Format>`_ (SRF) for kinmatic sources.
Here, we use an `intermediate format <https://github.com/SeisSol/SeisSol/wiki/Standard-Rupture-Format>`_, which converts converting the ASCII-SRF to an intermediate binary netCDF-format.
You can use the tool `rconv <https://github.com/SeisSol/SeisSol/tree/master/preprocessing/science/rconv>`_ for the conversion from SRF to netCDF.
