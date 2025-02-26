#!/bin/bash

cd {{workdir}}
version=dev
url=https://gitlab.com/sherpa-team/sherpa.git 

srcdir={{workdir}}/sherpa
if [ -d ${srcdir} ]; then
	cd ${srcdir}
	git pull
else
	git clone ${url}
fi
echo "[i] source dir is ${srcdir}"

cd {{builddir}}
# opts="-DSHERPA_ENABLE_INSTALL_LHAPDF=ON -DSHERPA_ENABLE_INSTALL_LIBZIP=ON"
# -DSHERPA_ENABLE_MANUAL=ON
opts="-DSHERPA_ENABLE_HEPMC2=ON -DSHERPA_ENABLE_HEPMC3=ON -DSHERPA_ENABLE_HEPMC3_ROOT=ON -DSHERPA_ENABLE_PYTHIA8=ON -DSHERPA_ENABLE_PYTHON=ON -DSHERPA_ENABLE_ROOT=ON -DENABLE_ANALYSIS=ON"

if [ -d "$OPENLOOPS_DIR" ]; then
    opts="$opts -DSHERPA_ENABLE_OPENLOOPS=ON"
fi

if [ -d "$FASTJET_DIR" ]; then
    opts="$opts -DSHERPA_ENABLE_FASTJET=ON -DFASTJET_DIR=${FASTJET_DIR}"
fi

echo "OPTS are $opts"

cmake -DCMAKE_INSTALL_PREFIX={{prefix}} \
	-DCMAKE_BUILD_TYPE=Release \
	-DSHERPA_ENABLE_INSTALL_LIBZIP=ON \
	${opts} \
	{{srcdir}} && cmake --build . --target install -- -j {{n_cores}}
exit $?
