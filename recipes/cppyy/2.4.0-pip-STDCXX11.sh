#!/bin/bash

STDCXX=11 python3 -m pip install cppyy==2.4.0
# the following will be used by module creation
# pkg_location=$({{python}} -m pip show cppyy | grep Location | cut -d' ' -f 2)
pkg_location="{{python}} -m pip show cppyy | grep Location | cut -d' ' -f 2"
# note the line below is not a comment - yasp will interpret the line and add a variable...
#yasp --shell-var python_path_cppyy={{pkg_location}}
