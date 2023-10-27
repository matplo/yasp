#!/bin/bash

cd {{workdir}}
version=2.2.15
url=https://sherpa.hepforge.org/downloads/SHERPA-MC-{{version}}.tar.gz
local_file={{workdir}}/SHERPA-MC-{{version}}.tar.gz
{{yasp}} --download {{url}} --output {{local_file}}
tar zxvf {{local_file}}
srcdir={{workdir}}/SHERPA-MC-{{version}}

cd {{srcdir}}

if [ -d "${LHAPDF6_DIR}" ]; then
	LHAPDF6OPT=--enable-lhapdf=${LHAPDF6_DIR}
else
	LHAPDF6OPT=""
fi

if [ -d "${HEPMC2_DIR}" ]; then
	HEPMC2OPT=--enable-hepmc2=${HEPMC2_DIR}
else
	HEPMC2OPT=""
fi

if [ -d "${HEPMC3_DIR}" ]; then
	HEPMC3OPT="--enable-hepmc3=${HEPMC3_DIR} --enable-hepmc3root"
	# --enable-hepmc3root # for this one needs to compile HepMC3 with ROOT support
else
	HEPMC3OPT=""
fi

if [ -d "${ROOT_DIR}" ]; then
	ROOTOPT="--enable-root=${ROOT_DIR}"
else
	ROOTOPT=""
fi

if [ -d "${FASTJET_DIR}" ]; then
	FASTJETOPT="--enable-fastjet=${FASTJET_DIR}"
else
	FASTJETOPT=""
fi

{{srcdir}}/configure --prefix={{prefix}} \
	${LHAPDF6OPT} ${HEPMC2OPT} ${HEPMC3OPT} ${ROOTOPT} ${FASTJETOPT} \
	--enable-pyext --enable-analysis --enable-gzip --enable-pythia --enable-ufo \
	&& make -j {{n_cores}} && make -j {{n_cores}} install
# --enable-mpi \
# --with-python-include="$(python -c "from sysconfig import get_paths; info = get_paths(); print(info['include'])")"
exit $?
