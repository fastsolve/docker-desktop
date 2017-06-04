#!/bin/bash

if [[ -z "$MATLAB_VERSION" ]]; then
    if [[ "$(cd /usr/local/MATLAB; ls | wc -w)" == "1" ]]; then
        MATLAB_VERSION=$(cd /usr/local/MATLAB; ls)
    else
        echo "There are multiple versions of MATLAB installed. Please set MATLAB_VERSION."
        exit -1
    fi
fi

ln -s -f /usr/local/MATLAB/$MATLAB_VERSION/bin/matlab /usr/local/bin
ln -s -f /usr/local/MATLAB/$MATLAB_VERSION/bin/mex /usr/local/bin
ln -s -f /usr/local/MATLAB/$MATLAB_VERSION/bin/glnxa64/mlint /usr/local/bin
