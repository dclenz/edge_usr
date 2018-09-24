Sources
=======
EDGE implements seismic sources through simple binary `HDF5 <https://support.hdfgroup.org/HDF5/>`_-input.
Each of the fused simulations has an independent HDF5-input file, which contains a collection of point sources.
This collection is completely decoupled from EDGE's fused simulation approach.
Thus, each of the fused simulations can have an arbitrary source description.

If a point source is outside of the modeling domain, it will be adjusted to the closest point of the mesh boundary.
For example, assume that we specify a point force at the peak of a mountain for a tetrahedral mesh.
In our example, the peak is outside the mesh, meaning that the source would be mapped to the closest-by point of the respective surface triangle.

HDF5 Input
----------
We use five arrays to discretize the point sources, where #pt is the number of point sources and #ts the number of samples of all time series.
All time series are integrated numerically (linear interpolation) before they are applied to Degrees of Freedom in EDGE.

+-----------------+--------+---------+---------+---------------------------------------------------------------+
| Dataset         | Type   | 2D Size | 3D Size | Description                                                   |
+=================+========+=========+=========+===============================================================+
| points          | fp32   | #pt, 2  | #pt, 3  | Cartesian coordinates of the point sources.                   |
+-----------------+--------+---------+---------+---------------------------------------------------------------+
| scalings        | fp32   | #pt, 5  | #pt, 9  | Scalings of each time series for each elastic quantity.       |
+-----------------+--------+---------+---------+---------------------------------------------------------------+
| time_parameters | fp32   | #pt, 2  | #pt, 2  | 1st: Offset of each time series in time.                      |
|                 |        |         |         | 2nd: Time step of each time series.                           |
+-----------------+--------+---------+---------+---------------------------------------------------------------+
| time_pointers   | uint64 | #pt+1   | #pt+1   | 0 to #ts-1: Pointers to the first entries                     |
|                 |        |         |         | of the 1D time series array.                                  | 
|                 |        |         |         | #ts: total number of time samples over all time series (#ts). |
+-----------------+--------+---------+---------+---------------------------------------------------------------+
| time_series     | fp32   | #ts     | #ts     | Samples of all time series.                                   |
+-----------------+--------+---------+---------+---------------------------------------------------------------+

The file :edge_opt:`point_forces_2d_0.h5 <cont/unit_tests/elastic/sources/point_sources_2d_0.h5>` contains an exemplary source description.
We obtain an ASCII-representation by using the tool `h5dump <https://support.hdfgroup.org/HDF5/doc/RM/Tools.html#Tools-Dump>`_:

::

  > h5dump point_sources_2d_0.h5

    HDF5 "point_sources_2d_0.h5" {
    GROUP "/" {
    DATASET "points" {
        DATATYPE  H5T_IEEE_F32LE
        DATASPACE  SIMPLE { ( 2, 2 ) / ( 2, 2 ) }
        DATA {
        (0,0): 0.2, 2.1,
        (1,0): 1.3, 1
        }
    }
    DATASET "scalings" {
        DATATYPE  H5T_IEEE_F32LE
        DATASPACE  SIMPLE { ( 2, 5 ) / ( 2, 5 ) }
        DATA {
        (0,0): 0, 0, 0, 0, 2.3,
        (1,0): 0, 0, 0, 1, 3.3
        }
    }
    DATASET "time_parameters" {
        DATATYPE  H5T_IEEE_F32LE
        DATASPACE  SIMPLE { ( 2, 2 ) / ( 2, 2 ) }
        DATA {
        (0,0): 1, 0.001,
        (1,0): 2.3, 0.002
        }
    }
    DATASET "time_pointers" {
        DATATYPE  H5T_STD_U64LE
        DATASPACE  SIMPLE { ( 3 ) / ( 3 ) }
        DATA {
        (0): 0, 5, 8
        }
    }
    DATASET "time_series" {
        DATATYPE  H5T_IEEE_F32LE
        DATASPACE  SIMPLE { ( 8 ) / ( 8 ) }
        DATA {
        (0): 0, 0.1, 0.2, 0.1, 0.15, 0, 0.3, 0.2
        }
    }
    }
    }

In this two-dimensional example, we have two point sources, located at :math:`(0.2\text{m},2.1\text{m})` and :math:`(1.3\text{m},1.0\text{m})`.
The first source acts on the 5th quantity :math:`v` and has a time series, scaled by :math:`2.3 \times`.
The second source acts on the 4th quantity :math:`u` and on :math:`v`, but only scales :math:`v` by :math:`3.3 \times`.
The first source is active after :math:`1\text{s}`, the second source after :math:`2.3\text{s}`.
The first source has a time step of :math:`0.001\text{s}`, while the second one has a time step of :math:`0.002\text{s}`.
We have a total of eight samples for all time series, where the first source starts at position :math:`0` and the second one at :math:`5`.
The sampled, unscaled time series for the first source has the values :math:`(0, 0.1, 0.2, 0.1, 0.15)`.
The second source has the three values :math:`0, 0.3, 0.2` and does not scale the time series.

NRF (deprecated)
----------------
Previous versions of EDGE implemented an `intermediate netCDF format <https://github.com/SeisSol/SeisSol/wiki/Standard-Rupture-Format>`_ (NRF) of the `Standard Rupture Format <http://scec.usc.edu/scecpedia/Standard_Rupture_Format>`_ (SRF) for kinematic sources.
This implementation performs the moment tensor computation, based on rupture parameters, in the setup of the solver.
For higher flexibility, in particular the support of point forces at the surface, this procedure has been replaced by the format above.
If using SRF-input and a (deprecated) NRF-enabled EDGE-version, the ASCII-SRF has to converted to an intermediate binary netCDF-format.
You can use the tool `rconv <https://github.com/SeisSol/SeisSol/tree/master/preprocessing/science/rconv>`_ for the conversion from SRF to netCDF.