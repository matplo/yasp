#!/bin/bash
cd {{workdir}}
version=6.5.3
url=https://lhapdf.hepforge.org/downloads/?f=LHAPDF-{{version}}.tar.gz
local_file={{workdir}}/LHAPDF-{{version}}.tar.gz
{{yasp}} --download {{url}} --output {{local_file}}
tar zxvf {{local_file}}
srcdir={{workdir}}/LHAPDF-{{version}}

# cd {{builddir}}
# {{srcdir}}/configure --prefix={{prefix}} ${other_opts} && make -j {{n_cores}} && make install
cd {{srcdir}}
./configure --prefix={{prefix}} ${other_opts} && make -j {{n_cores}} && make install

if [ "0x$?" == "0x0" ]; then
	# example for installing PDFs
	# lhapdf install CT10nlo
	# or - here just for a test...
	wget http://lhapdfsets.web.cern.ch/lhapdfsets/current/CT10nlo.tar.gz -O- | tar xz -C {{prefix}}/share/LHAPDF
fi

exit $?
