#!/bin/bash

cd {{workdir}}
#version=3.3.3
version=3.4.0
url=http://fastjet.fr/repo/fastjet-{{version}}.tar.gz
local_file={{workdir}}/fastjet-{{version}}.tar.gz
{{yasp}} --download {{url}} --output {{local_file}}
tar zxvf {{local_file}}
srcdir={{workdir}}/fastjet-{{version}}

cd {{builddir}}
cgal_opt=--disable-cgal
other_opts="--enable-allcxxplugins"
# not enabling the swig interface --enable-pyext
{{srcdir}}/configure --prefix={{prefix}} {{cgal_opt}} ${other_opts} && make -j {{n_cores}} && make install
exit $?
