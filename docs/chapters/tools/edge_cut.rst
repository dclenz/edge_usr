EDGE-CUT
=========
EDGE-CUT is a tool for generating surface meshes for a computational domain with topography. It makes
heavy use of the `Computational Geometry Algorithms Library <https://www.cgal.org/>`_ (CGAL), particularly the
`3D Mesh Generation <https://doc.cgal.org/latest/Mesh_3/index.html#Chapter_3D_Mesh_Generation/>`_,
`Polygon Mesh Processing <https://doc.cgal.org/latest/Polygon_mesh_processing/index.html#Chapter_PolygonMeshProcessing/>`_,
and `3D Polyhedral Surface <https://doc.cgal.org/latest/Polyhedron/index.html#Chapter_3D_Polyhedral_Surfaces/>`_ packages.


Dependencies
---------------
EDGE-CUT has the following dependencies:

* `GCC <https://www.gnu.org/software/gcc/>`_ version 5 or higher
* `SCons <https://scons.org/>`_
* `CGAL version 4.12.1 <https://doc.cgal.org/4.12.1/Manual/installation.html/>`_, which has its own `set of dependencies <https://doc.cgal.org/4.12.1/Manual/installation.html#secessential3rdpartysoftware/>`_:

  * `CMake <https://cmake.org/>`_ version 3.1 or higher
  * `Boost C++ Libraries <https://www.boost.org/>`_ version 1.48 or higher, with ``Boost.Thread`` and ``Boost.System`` installed
  * `GMP <http://gmplib.org/>`_ version 4.2 or higher
  * `MPFR <http://www.mpfr.org/>`_ version 2.2.1 or higher
  * `zlib <http://www.zlib.net/>`_


Build Instructions
--------------------
SCons
^^^^^^^
`SCons <https://scons.org/>`_ is a python-based build tool and can be installed with ``pip``:

.. code-block:: bash

  pip install scons


Boost
^^^^^^^
The Boost C++ Libraries are a dependency of CGAL; however, they must also be linked to EDGE-CUT at build-time.
EDGE-CUT requires the ``Boost.Thread`` and ``Boost.System`` libraries to be installed (these libraries are not header-only).
Since Boost is a CGAL dependency, these libraries must be installed before attempting to install CGAL.
For more information on how to install Boost libraries, please see the `Boost Getting Started Guide <https://www.boost.org/doc/libs/1_68_0/more/getting_started/index.html/>`_.

If you are using a Windows system, CGAL requires additional Boost libraries. EDGE-CUT has not been tested on Windows, but you can
read more about these additional requirements in the `CGAL Installation Manual <https://doc.cgal.org/latest/Manual/installation.html#secessential3rdpartysoftware/>`_.

CGAL
^^^^^^
EDGE-CUT has been tested with CGAL version 4.12.1. CGAL releases are designed for backwards-compatibility,
but there is always a risk that future versions may introduce unforeseen changes in behavior.

The `CGAL Installation Manual <https://doc.cgal.org/latest/Manual/installation.html/>`_ provides a comprehensive set of
instructions for installing CGAL and is good reference if the "quick install" instructions below do not suffice for your system.

Before building CGAL, make sure that you have installed GMP, MPFR, zlib, Boost, and CMake. It is recommended that you add the locations
of GMP, MPFR, and Boost to your ``CPLUS_INCLUDE_PATH`` and ``LIBRARY_PATH`` environment variables. If you don't you will need to specify
additional options during configuration (see below).

You can download CGAL 4.12.1 with:

.. code-block:: bash

  wget https://github.com/CGAL/cgal/releases/download/releases%2FCGAL-4.12.1/CGAL-4.12.1.tar.xz -O cgal-4.12.1.tar.xz
  mkdir cgal-4.12.1; tar -xf cgal-4.12.1.tar.xz -C cgal-4.12.1 --strip-components=1

Then, configure CGAL with CMake:

.. code-block:: bash

  cmake . -DWITH_CGAL_ImageIO=OFF -DWITH_CGAL_Qt5=OFF [additional flags...]

You may want to configure with some non-default options if, for instance, you do not have ``sudo`` access on your machine or
wish to use libraries in non-standard locations. Instructions on how to customize your configuration are given below; an example
configuration for someone who maintains software in ${HOME}/local might be:

.. code-block:: bash

  cmake . -DWITH_CGAL_ImageIO=OFF -DWITH_CGAL_Qt5=OFF -DCMAKE_INSTALL_PREFIX=${HOME}/local -DBOOST_ROOT=${HOME}/local -DBUILD_SHARED_LIBS=FALSE -DCGAL_Boost_USE_STATIC_LIBS=ON

There are configuration flags for specifying the location of the install directory, the location of dependencies, and other options.
A non-exhaustive list is given below. For more a more comprehensive list, see the CGAL manual section on
`Configuring CGAL with CMake <https://doc.cgal.org/latest/Manual/installation.html#secconfigwithcmake/>`_.

+------------------------------+------------------------------------------------------------------+
| Configure Flag               | Description                                                      |
+==============================+==================================================================+
| -DCMAKE_BUILD_TYPE           || Sets the CGAL version to build: either "Release" or "Debug".    |
|                              || **Defaults to:** "Release"                                      |
+------------------------------+------------------------------------------------------------------+
| -DCMAKE_INSTALL_PREFIX       || Path to where CGAL will be installed.                           |
|                              || **Defaults to:** ``/usr/local``                                 |
+------------------------------+------------------------------------------------------------------+
| -DWITH_CGAL_ImageIO          || Sets whether or not to build the component ``CGAL_ImageIO``.    |
|                              || (This component is not needed by EDGE-CUT)                      |
|                              || **Defaults to:** "ON"                                           |
+------------------------------+------------------------------------------------------------------+
| -DWITH_CGAL_Qt5              || Sets whether or not to build the component ``CGAL_Qt5``.        |
|                              || (This component is not needed by EDGE-CUT)                      |
|                              || **Defaults to:** "ON"                                           |
+------------------------------+------------------------------------------------------------------+
| -DBUILD_SHARED_LIBS          || Builds shared libraries when set to "TRUE", builds static       |
|                              || libraries when set to "FALSE".                                  |
|                              || **Defaults to:** "TRUE"                                         |
+------------------------------+------------------------------------------------------------------+
| -DBOOST_ROOT                 || Path to root directory of the Boost installation. If not set,   |
|                              || standard environment variables are used to locate the           |
|                              || the installation.                                               |
|                              || **Defaults to:** [None]                                         |
+------------------------------+------------------------------------------------------------------+
| -DCGAL_Boost_USE_STATIC_LIBS || Forces CGAL to link to static versions of the Boost libraries   |
|                              || when set to "ON", when both shared and static libraries are     |
|                              || found. In general, CGAL links to shared libraries if present.   |
|                              || **Defaults to:** "OFF"                                          |
+------------------------------+------------------------------------------------------------------+
|| -DGMP_INCLUDE_DIR           || Specifies the location of directories containing headers and    |
|| -DGMP_LIBRARIES_DIR         || libraries for GMP and MPFR. If not set, standard environment    |
|| -DMPFR_INCLUDE_DIR          || variables are used to locate the installations. `More options   |
|| -DMPFR_LIBRARIES_DIR        |  <https://doc.cgal.org/latest/Manual/installation.               |
|                              |  html#installation_gmp/>`_                                       |
|                              || are given in the manual.                                        |
|                              || **Defaults to:** [None]                                         |
+------------------------------+------------------------------------------------------------------+

.. IMPORTANT::
  It is highly recommended that you check the output of CMake at the end of the configuration step to make sure
  the configuration is what you expect. CMake will specify the versions and locations of its dependencies, as well
  as which "CGAL components" have been built (only CGAL_Core is required for EDGE-CUT).

After configuration, you can complete the build process by running

.. code-block:: bash

  make
  make install


.. _`cgal-linkpath-warn`:
.. WARNING::
  CGAL installs its libraries in ``${CMAKE_INSTALL_PREFIX}/lib64`` (if you configured with default options this
  is ``/usr/loca/lib64``).  On some systems, this is not one of the default search paths, which will lead linking
  errors when EDGE-CUT is built. The easiest way to fix this is to add this directory to your ``LIBRARY_PATH``
  environment variable.

EDGE-CUT
^^^^^^^^^^
To build EDGE-CUT, simply invoke scons with no additional arguments:

.. code-block:: bash

  scons

The build script will notify you if any required libraries are not found, with a message like the following:

.. code-block:: bash

  Running build script of EDGEcut.
  Checking for C++ library libCGAL... yes
  Checking for C++ library mpfr... yes
  Checking for C++ library gmp... yes
  Checking for C++ library boost_thread... yes

If you have installed Boost and/or CGAL in nonstandard locations, you can pass their root directories to the SCons
build script with the ``cgal_dir`` and ``boost_dir`` options:

.. code-block:: bash

  scons cgal_dir=${HOME}/local boost_dir=${HOME}/local

At this time, there are no options to specify other required library locations (e.g. GMP or MPFR) - they must be
included in your ``LIBRARY_PATH`` (or similar).

If you are having trouble getting SCons to find your CGAL installation, please keep in mind that CGAL typically installs
into the ``lib64`` subdirectory of the installation root, as this may be unexpected by your linker.
See `this warning <cgal-linkpath-warn_>`__ for more information.

Usage
---------
