#!/bin/bash

# STDCXX=11 python3 -m pip install cppyy==2.4.0
# the following will be used by module creation
# pkg_location="{{python}} -m pip show cppyy | grep Location | cut -d' ' -f 2"
# note the line below is not a comment - yasp will interpret the line and add a variable...
# yasp --shell-var python_path_cppyy={{pkg_location}}
# yasp --shell-var python_path_cppyy={{prefix}}

# STDCXX=11 python3 -m pip install --target={{prefix}} --force-reinstall --upgrade --no-cache-dir cppyy==2.4.0
# STDCXX=11 python3 -m pip install --prefix={{prefix}} --force-reinstall --upgrade --no-cache-dir cppyy-backend==1.14.9 CPyCppyy==1.12.11 cppyy-cling==6.27.0 cppyy==2.4.0
# STDCXX=11 python3 -m pip install --force-reinstall --upgrade --no-cache-dir cppyy-backend==1.14.9 CPyCppyy==1.12.11 cppyy-cling==6.27.0 cppyy==2.4.0

# build from source
# STDCXX=11 MAKE_NPROCS={{n_cores}} python -m pip install --verbose cppyy --no-binary=cppyy-cling

version=2.4.2
STDCXX=11 MAKE_NPROCS={{n_cores}} {{python}} -m pip install --prefix={{prefix}} --verbose cppyy=={{version}} --no-cache-dir --upgrade --no-binary=cppyy-cling --force-reinstall
