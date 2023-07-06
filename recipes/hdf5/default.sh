#!/bin/bash

cd {{workdir}}
version=1_14_1-2
url=https://github.com/HDFGroup/hdf5/archive/refs/tags/hdf5-{{version}}.tar.gz
local_file={{workdir}}/hdf5-{{version}}.tar.gz
{{yasp}} --download {{url}} --output {{local_file}}
tar zxvf {{local_file}}
srcdir={{workdir}}/hdf5-hdf5-{{version}}

cd {{builddir}}
opts="--enable-tools --enable-parallel --enable-build-mode=production" 
# --enable-cxx"
{{srcdir}}/configure --prefix={{prefix}} ${opts} && make -j {{n_cores}} && make install
exit $?
