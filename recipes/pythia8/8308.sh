#!/bin/bash

cd {{workdir}}
version=8308
url=https://pythia.org/download/pythia83/pythia{{version}}.tgz
local_file={{workdir}}/pythia{{version}}.tar.gz
{{yasp}} --download {{url}} --output {{local_file}}
tar zxvf {{local_file}}
srcdir={{workdir}}/pythia{{version}}

cd {{srcdir}}
{{srcdir}}/configure --prefix={{prefix}} && make -j {{n_cores}} && make install
exit $?
