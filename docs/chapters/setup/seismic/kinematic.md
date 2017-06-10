# Kinematic Sources
EDGE has <strike>two</strike> one types of kinematic source implementations:
1. Each of the fused runs has a completely independent, non-fused kinematic source description.
   This approach is the most flexible since the source description can be arbitrary.
   However, no data is shared in the storage of the point sources.
   Further, this leads to less efficient code for source updates.
2. *Oops.. fused sources are not implemented for the time being.*
   Please let us know if you would like to have them, and we'll bump up the priority of the implementation. <br/>
   The number of fused kinematic sources equals the number of fused runs.
   In this case all possible data of the point sources will be shared in their storage.
   The two exceptions are the slip-rates per point source and the coefficients of the slip rates (encoding slip-direction, subfault area, etc.).
   Thus, the following parameters are shared:
     * The number of point sources (or subfaults) the kinematic source descriptions has to be identical.
     * The locations of the point sources have to be identical (up to a numerical tolerance).
     * The number of slip rates samples has to be identical.
     * The onset times and sampling intervals ($$\rightarrow$$ duration together with the number of samples) of the point sources have to be identical.

Given your input, EDGE will automatically determine the appropriate implementation.
Here, EDGE will fuse the source descriptions if the slip-parameters cover the fuse runs.
If only one set of slip parameters per point source is given, non-fused sources will be used.
In general, we recommend to use both, fused kinematic sources and fused runs, for higher performance.

## Standard Rupture Format
EDGE implements the ["Standard Rupture Format"](https://scec.usc.edu/scecpedia/Standard_Rupture_Format) (SRF) for kinmatic sources.
Here, we use an [intermediate format](https://github.com/SeisSol/SeisSol/wiki/Standard-Rupture-Format), which converts converting the ASCII-SRF to an intermediate binary netCDF-format.
You can use the tool [rconv](https://github.com/SeisSol/SeisSol/tree/master/preprocessing/science/rconv) for the conversion from SRF to netCDF.
