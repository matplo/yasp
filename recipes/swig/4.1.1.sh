#!/bin/bash

cd {{workdir}}
version=4.1.1
# url=https://prdownloads.sourceforge.net/swig/swig-{{version}}.tar.gz
url="https://www.dropbox.com/s/1n65etk0cpxs88n/swig-{{version}}.tar.gz?dl=0"
local_file={{workdir}}/swig-{{version}}.tar.gz
{{yasp}} --download {{url}} --output {{local_file}}
tar zxvf {{local_file}}
srcdir={{workdir}}/swig-{{version}}

cd {{builddir}}
{{srcdir}}/configure --prefix={{prefix}} && make -j {{n_cores}} && make install
exit $?
