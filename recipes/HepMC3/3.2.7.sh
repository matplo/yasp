#!/bin/bash
cd {{workdir}}
version=3.2.7
url=https://hepmc.web.cern.ch/hepmc/releases/HepMC3-{{version}}.tar.gz
local_file={{workdir}}/HepMC3-{{version}}.tar.gz
{{yasp}} --download {{url}} --output {{local_file}}
tar zxvf {{local_file}}
srcdir={{workdir}}/HepMC3-{{version}}

cd {{builddir}}

if [ -d "${ROOTSYS}" ]; then
	ROOTOPT="-DHEPMC3_ENABLE_ROOTIO=ON -DROOT_DIR=${ROOTSYS}"
else
	ROOTOPT="-DHEPMC3_ENABLE_ROOTIO=OFF"
fi

python_opt=ON
cmake ${ROOTOPT} \
	-DHEPMC3_BUILD_EXAMPLES=ON \
	-DHEPMC3_ENABLE_TEST=ON \
	-DCMAKE_INSTALL_PREFIX={{prefix}} \
	-DHEPMC3_ENABLE_PYTHON:BOOL={{python_opt}} \
	-DHEPMC3_INSTALL_INTERFACES:BOOL=ON \
	{{srcdir}}
# cmake --build ./
# {{srcdir}}/configure --prefix={{prefix}} ${other_opts} && make -j {{n_cores}} && make install

if [ "0x$?" == "0x0" ]; then
	make -j {{n_cores}} && make test && make install
fi

exit $?
