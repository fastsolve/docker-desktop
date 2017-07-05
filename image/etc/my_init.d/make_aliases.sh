#!/bin/bash

if [ -n "$MATLAB_VERSION" ]; then
  ln -s -f /usr/local/MATLAB/$MATLAB_VERSION/bin/matlab /usr/local/bin
  ln -s -f /usr/local/MATLAB/$MATLAB_VERSION/bin/mex /usr/local/bin
  ln -s -f /usr/local/MATLAB/$MATLAB_VERSION/bin/glnxa64/mlint /usr/local/bin
elif [ -e  /usr/local/mlint/bin/glnxa64/mlint ]; then
  ln -s -f /usr/local/mlint/bin/glnxa64/mlint /usr/local/bin
fi
