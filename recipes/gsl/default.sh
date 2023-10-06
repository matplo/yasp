#!/bin/bash

cd {{workdir}}
version=2.7.1
url=https://gnu.mirror.constant.com/gsl/gsl-{{version}}.tar.gz 
local_file={{workdir}}/fastjet-{{version}}.tar.gz
{{yasp}} --download {{url}} --output {{local_file}}
tar zxvf {{local_file}}
srcdir={{workdir}}/gsl-{{version}}

cd {{builddir}}
{{srcdir}}/configure --prefix={{prefix}} ${cgal_opt} ${other_opts} && make -j {{n_cores}} && make install
exit $?
