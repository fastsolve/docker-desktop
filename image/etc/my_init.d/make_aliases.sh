#!/bin/bash

if [[ -n "$MATLAB_VERSION" ]]; then
  ln -s -f /usr/local/MATLAB/$MATLAB_VERSION/bin/matlab /usr/local/bin
  ln -s -f /usr/local/MATLAB/$MATLAB_VERSION/bin/mex /usr/local/bin
  ln -s -f /usr/local/MATLAB/$MATLAB_VERSION/bin/glnxa64/mlint /usr/local/bin
else
  # Assume there is only one version of MATLAB installed
  ln -s -f /usr/local/MATLAB/R*/bin/matlab /usr/local/bin
  ln -s -f /usr/local/MATLAB/R*/bin/mex /usr/local/bin
fi
