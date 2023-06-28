#!/bin/bash

cd {{workdir}}
version=2.06.11
url=http://hepmc.web.cern.ch/hepmc/releases/HepMC-{{version}}.tar.gz
url=http://hepmc.web.cern.ch/hepmc/releases/HepMC-{{version}}.tgz
url=https://hepmc.web.cern.ch/hepmc/releases/hepmc{{version}}.tgz
#local_file={{workdir}}/HepMC-{{version}}.tar.gz
local_file={{workdir}}/hepmc{{version}}.tgz
{{yasp}} --download {{url}} --output {{local_file}}
tar zxvf {{local_file}}
#srcdir={{workdir}}/HepMC-{{version}}
srcdir={{workdir}}/hepmc{{version}}
cd {{builddir}}

cmake -Dmomentum:STRING=GEV -Dlength:STRING=CM \
					-DCMAKE_INSTALL_PREFIX={{prefix}} \
			     	-DCMAKE_BUILD_TYPE=Release \
			      	-Dbuild_docs:BOOL=OFF \
			      	-DCMAKE_MACOSX_RPATH=ON \
			      	-DCMAKE_INSTALL_RPATH={{prefix}}/lib \
			      	-DCMAKE_BUILD_WITH_INSTALL_NAME_DIR=ON \
					{{srcdir}}



cmake --build . --target all
cmake --build . --target install