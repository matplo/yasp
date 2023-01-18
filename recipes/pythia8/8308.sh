#!/bin/bash

cd {{workdir}}
version=8308
url=https://pythia.org/download/pythia83/pythia{{version}}.tgz
local_file={{workdir}}/pythia{{version}}.tar.gz
{{yasp}} --download {{url}} --output {{local_file}}
tar zxvf {{local_file}}
srcdir={{workdir}}/pythia{{version}}

cd {{srcdir}}
{{srcdir}}/configure --prefix={{prefix}} --enable-shared && make -j {{n_cores}} && make install
# --with-python-include="$(python -c "from sysconfig import get_paths; info = get_paths(); print(info['include'])")"
exit $?
