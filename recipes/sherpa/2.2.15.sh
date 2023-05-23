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


{{srcdir}}/configure --prefix={{prefix}} ${LHAPDF6OPT} ${HEPMC2OPT} && make -j {{n_cores}} && make install
# --with-python-include="$(python -c "from sysconfig import get_paths; info = get_paths(); print(info['include'])")"
exit $?
