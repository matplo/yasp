#!/bin/bash

# this is following https://root.cern/install/dependencies/

version="default"
this_prefix="{{prefix}}"
this_workdir="{{workdir}}"

source ${YASP_DIR}/src/util/bash/util.sh

note "this follows https://root.cern/install/dependencies/"

separator "root dependencies"

sudo apt-get install binutils cmake dpkg-dev g++ gcc libssl-dev git libx11-dev \
libxext-dev libxft-dev libxpm-dev python3

# optional

separator "root optional dependencies"

sudo apt-get install gfortran libpcre3-dev \
xlibmesa-glu-dev libglew-dev libftgl-dev \
libmysqlclient-dev libfftw3-dev libcfitsio-dev \
graphviz-dev libavahi-compat-libdnssd-dev \
libldap2-dev python3-dev python3-numpy libxml2-dev libkrb5-dev \
libgsl0-dev qtwebengine5-dev nlohmann-json3-dev

