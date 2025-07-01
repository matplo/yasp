#!/bin/bash

cd {{workdir}}
version=8315
url=https://pythia.org/download/pythia83/pythia{{version}}.tgz
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
    HEPMC2OPT=--with-hepmc2=${HEPMC2_DIR}
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

# Fix RPATH issue on macOS - remove malformed ../lib: prefix from RPATH
if [ "$(uname)" == "Darwin" ]; then
	echo "[i] Fixing RPATH on macOS..."
	pythia_lib={{prefix}}/lib/libpythia8.dylib
	if [ -f "${pythia_lib}" ]; then
		# Check if malformed RPATH exists and fix it
		malformed_rpath=$(otool -l ${pythia_lib} | grep -A 2 "LC_RPATH" | grep "../lib:" | awk '{print $2}')
		if [ ! -z "${malformed_rpath}" ]; then
			echo "[i] Removing malformed RPATH: ${malformed_rpath}"
			install_name_tool -delete_rpath "${malformed_rpath}" ${pythia_lib}
			echo "[i] Adding correct RPATH: {{prefix}}/lib"
			install_name_tool -add_rpath "{{prefix}}/lib" ${pythia_lib}
			echo "[i] RPATH fix completed"
		else
			echo "[i] No malformed RPATH found, skipping fix"
		fi
	else
		echo "[w] PYTHIA8 library not found at ${pythia_lib}"
	fi
fi

exit $?
