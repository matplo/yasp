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

echo "Python version:" {{python_version}}
echo "Python version no dot:" {{python_version_no_dot}}
echo "Python site packages subpath:" {{python_site_packages_subpath}}
echo "Python site packages path:" {{prefix}}/lib/{{python_site_packages_subpath}}

python_opt=ON
cmake ${ROOTOPT} \
	-DHEPMC3_BUILD_EXAMPLES=ON \
	-DHEPMC3_ENABLE_TEST=ON \
	-DCMAKE_INSTALL_PREFIX={{prefix}} \
	-DHEPMC3_ENABLE_PYTHON:BOOL={{python_opt}} \
	-DHEPMC3_INSTALL_INTERFACES:BOOL=ON \
	-DHEPMC3_PYTHON_VERSIONS={{python_version}} \
	-DHEPMC3_Python_SITEARCH{{python_version_no_dot}}={{prefix}}/lib/{{python_site_packages_subpath}} \
	{{srcdir}}
# cmake --build ./
# {{srcdir}}/configure --prefix={{prefix}} ${other_opts} && make -j {{n_cores}} && make install

if [ "0x$?" == "0x0" ]; then
	make -j {{n_cores}} && make test && make install
fi

exit $?
