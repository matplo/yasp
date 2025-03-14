#!/bin/bash
cd {{workdir}}
version=02.02.03
url=https://evtgen.hepforge.org/downloads?f=EvtGen-{{version}}.tar.gz
local_file={{workdir}}/EvtGen-{{version}}.tar.gz
{{yasp}} --download {{url}} --output {{local_file}}
tar zxvf {{local_file}}

version_dashes=$(echo "${version}" | tr . -)
srcdir={{workdir}}/EvtGen/R${version_dashes}

cd {{builddir}}
pwd

CMAKE_EVTGEN_OPT="-DCMAKE_INSTALL_PREFIX={{prefix}}"

# Check for HepMC2
if [ -d "${HEPMC2_DIR}" ]; then
    CMAKE_EVTGEN_OPT="${CMAKE_EVTGEN_OPT} -DEVTGEN_HEPMC3=OFF"
    CMAKE_EVTGEN_OPT="${CMAKE_EVTGEN_OPT} -DHEPMC2_ROOT_DIR=${HEPMC2_DIR}"
elif [ -d "${HEPMC3_DIR}" ]; then
    CMAKE_EVTGEN_OPT="${CMAKE_EVTGEN_OPT} -DEVTGEN_HEPMC3=ON"
    CMAKE_EVTGEN_OPT="${CMAKE_EVTGEN_OPT} -DHEPMC3_ROOT_DIR=${HEPMC3_DIR}"
fi

# Check for Pythia8
if [ -d "${PYTHIA8_DIR}" ]; then
    CMAKE_EVTGEN_OPT="${CMAKE_EVTGEN_OPT} -DEVTGEN_PYTHIA=ON"
    CMAKE_EVTGEN_OPT="${CMAKE_EVTGEN_OPT} -DPYTHIA8_ROOT_DIR=${PYTHIA8_ROOT_DIR}"
fi

# Build docs, tests, and validations
#CMAKE_EVTGEN_OPT="${CMAKE_EVTGEN_OPT} -DEVTGEN_BUILD_DOC=ON"          # results in LaTeX error
#CMAKE_EVTGEN_OPT="${CMAKE_EVTGEN_OPT} -DEVTGEN_BUILD_TESTS=ON"        # results in build error
#CMAKE_EVTGEN_OPT="${CMAKE_EVTGEN_OPT} -DEVTGEN_BUILD_VALIDATIONS=ON"  # results in build error

cmake {{srcdir}} ${CMAKE_EVTGEN_OPT}

if [ "0x$?" == "0x0" ]; then
	make -j {{n_cores}}
    #make test
    make install
fi

exit $?
