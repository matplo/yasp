#!/bin/bash

cd {{workdir}}
version=8244
url=https://pythia.org/download/pythia82/pythia{{version}}.tgz
local_file={{workdir}}/pythia{{version}}.tar.gz
{{yasp}} --download {{url}} --output {{local_file}}
tar zxvf {{local_file}}
srcdir={{workdir}}/pythia{{version}}

cd {{srcdir}}
# obsolete --enable-shared
if [ -d "${LHAPDF6_DIR}" ]; then
	LHAPDF6OPT=--with-lhapdf6=${LHAPDF6_DIR}
else
	LHAPDF6OPT=""
fi

if [ -d "${HEPMC2_DIR}" ]; then
    HEPMC2OPT="--with-hepmc2=${HEPMC2_DIR} --with-hepmc2-version=${HEPMC2_VERSION}"
else
    HEPMC2OPT=""
fi

if [ -d "${FASTJET_DIR}" ]; then
	FASTJET3OPT=--with-fastjet3=${FASTJET_DIR}
else
	FASTJET3OPT=""
fi

if [ -d "${ROOTSYS}" ]; then
	ROOTOPT=--with-root=${ROOTSYS}
else
	ROOTOPT=""
fi

{{srcdir}}/configure --prefix={{prefix}} ${LHAPDF6OPT} ${ROOTOPT} ${FASTJET3OPT} ${HEPMC2OPT} && make -j {{n_cores}} && make install
# --with-python-include="$(python -c "from sysconfig import get_paths; info = get_paths(); print(info['include'])")"
exit $?
