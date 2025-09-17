#!/bin/bash

function exit_with_error()
{
	echo_error "bailing out: $@"
	exit 1
}

source ${YASP_DIR}/src/util/bash/util.sh

export STARLIGHTGITHUB=https://github.com/matplo/STARlight.git
#export STARLIGHTGITHUB=git@github.com:matplo/STARlight.git
starlight_version=master

echo "[i] Using STARlight at ${STARLIGHTGITHUB} ${starlight_version}"
echo "    version=${starlight_version}"

cd {{workdir}}
if [ {{clean_build}} == "yes" ]; then
	echo_warning "cleaning build directory"
	rm -rf STARlight
fi

srcdir={{workdir}}/STARlight
build_dir={{workdir}}/build

if [ -d "STARlight" ]; then
	echo_warning "STARlight directory already exists, skipping git clone"
	if [ {{clean_build}} == "yes" ]; then
		if [ ! {{starlight_version}} == master ]; then
				git checkout {{starlight_version}}
				[ "0x$?" != "0x0" ] && exit_with_error "git checkout failed" $?
		fi
	fi
else
	echo_info "cloning STARlight"
	git clone ${STARLIGHTGITHUB}
	[ "0x$?" != "0x0" ] && exit_with_error "git clone failed" $?
fi

if [ -d "${HEPMC3_DIR}" ]; then
	echo_warning "HEPMC3_DIR is set, enabling HepMC3"
	HEPMC3_OPT="-DENABLE_HEPMC3=ON -DHepMC3_DIR=${HEPMC3_DIR}"
else
	echo_warning "HEPMC3_DIR is not set, disabling HepMC3"
	HEPMC3_OPT=""
fi

if [ -d "${DPMJET_DIR}" ]; then
	echo_warning "DPMJET_DIR is set, enabling DPMJET"
	DPMJET_OPT="-DENABLE_DPMJET=ON -DDPMJET_DIR=${DPMJET_DIR}"
else
	echo_warning "DPMJET_DIR is not set, disabling DPMJET"
	DPMJET_OPT=""
fi

cd {{build_dir}}
cmake {{srcdir}} -DCMAKE_INSTALL_PREFIX={{prefix}} -DCMAKE_BUILD_TYPE=Release ${HEPMC3_OPT} ${DPMJET_OPT} 
# -DCMAKE_CXX_FLAGS="-Wno-error" -DCMAKE_CXX_COMPILER=g++
[ "0x$?" != "0x0" ] && exit_with_error "cmake failed" $?
cmake --build . --target install -- -j {{n_cores}}

exit $?
