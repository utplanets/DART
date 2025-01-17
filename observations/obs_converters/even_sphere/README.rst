===========
Even Sphere
===========

Generate a series of synthetic observations located at roughly
evenly distributed locations on a sphere.  At each location
generate a vertical column of observations.  This could mimic
a radiosonde observing network, for example.



This directory contains a MATLAB script that generates
input for the 'create_obs_sequence' program.  It takes
a number of vertical levels and a total number of points,
and generates a roughly evenly distributed set of observations
across the entire globe.  Note that the number of obs
will be the number of points times the number of vertical
levels.


the process, end to end:

MATLAB:

edit even_sphere.m and set the number of levels, the
number of profiles, the vertical coordinate type, etc.     

run it in MATLAB.  it will make a plot (which you can 
save from the menu) and it will create a file 'even_create_input'.

DART:

build the following executables and have these files
in the current directory:

.. code-block:: text

   ./create_obs_sequence
   ./create_fixed_network_seq
   input.nml

(if these executables were compiled for a specific model,
then if that model needs any other input files at startup
time, they will need to be copied here as well. 
e.g. cam needs a caminput.nc and cam_phis.nc even though
they will never be used.)

1) 
run ./create_obs_sequence < even_create_input > /dev/null

that makes a set_def.out file

2)
edit run_fixed_network_seq.csh to set the start/stop times

run ./run_fixed_network_seq.csh which will call ./create_fixed_network_seq
multiple times to make separate obs_seq files as output.
this script is where you set the period between files.


DETAILS on generating points evenly distributed on a sphere:

this is the algorithm (i believe) that's being used:

.. code-block:: text

  dlong := pi*(3-sqrt(5))  /* ~2.39996323 */
  dz    := 2.0/N
  long := 0
  z    := 1 - dz/2
  for k := 0 .. N-1
      r    := sqrt(1-z*z)
      node[k] := (cos(long)*r, sin(long)*r, z)
      z    := z - dz
      long := long + dlong

