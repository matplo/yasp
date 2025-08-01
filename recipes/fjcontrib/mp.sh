#!/bin/bash

source ${YASP_DIR}/src/util/bash/util.sh

separator "fjcontrib from GITHUB repository"
echo_info "version: {{version}}"
echo_warning "this is a development version - but taken from official repo for 1.101"
echo_info "using workdir: {{workdir}}"
echo_info "using n_cores: {{n_cores}}"

fjconfig=$(which fastjet-config)
if [ ! -e "${fjconfig}" ]; then
	echo_error "no fastjet-config [${fjconfig} ] this will not work"
	exit -1
else
	echo_info "using ${fjconfig}"
fi
fastjet_prefix=$(fastjet-config --prefix)
echo_info "using prefix: {{fastjet_prefix}}"
install_prefix="{{fastjet_prefix}}"
echo_warning "forcing prefix: ${install_prefix}"
echo_warning "typically the prefix is the same as fastjet-config --prefix"

#determine lib extension
if [[ "$(uname)" == "Darwin" ]]; then
	libext="dylib"
else
	libext="so"
fi

fragile_lib_path=${install_prefix}/lib/libfastjetcontribfragile.${libext}
if [ -e "${fragile_lib_path}" ]; then
    echo_warning "fragile lib already exists: ${fragile_lib_path}"
    # ask if to continue
    read -p "Continue recompiling? [Y/n] " answer
    if [[ "$answer" == "n" || "$answer" == "N" ]]; then
	echo_error "Done here due to existing fragile lib - but returning rc=0"
	exit 0
    else
	echo_info "Continuing..."
    fi
fi

if [ -d "${install_prefix}/include/fastjet/contrib" ]; then
    echo_warning "Will remove ${install_prefix}/include/fastjet/contrib - is this ok?"
    read -p "Continue recompiling? [Y/n] " answer
    if [[ "$answer" == "n" || "$answer" == "N" ]]; then
	echo_error "Done here but returning rc=0"
	exit 0
    else
	rm -rf ${install_prefix}/include/fastjet/contrib
    fi
fi

cd {{workdir}}
version=master
url=https://github.com/matplo/fjcontrib.git

echo "[i] Using FJcontrib at ${url} {{version}}"
echo "fjcontrib-version is:" fjcontrib-{{version}}

cd {{workdir}} && rm -rf fjcontrib-{{version}}
git clone ${url} fjcontrib-{{version}}
srcdir={{workdir}}/fjcontrib-{{version}}
build_dir={{workdir}}/fjcontrib-{{version}}-build

if [ "{{version}}" != "master" ]; then
    cd {{srcdir}}
    git checkout tags/{{version}} -b {{version}}
fi

#srcdir={{workdir}}/fjcontrib-{{version}}

# if [ -d "${CGAL_DIR}" ]; then
# 	# cgal_opt="--with-cgaldir=${CGAL_DIR} --enable-cgal-header-only"
# 	# echo "$CGAL_DIR"
# 	cgal_opt="--enable-cgal-header-only --with-cgaldir=${CGAL_DIR}"
# else
# 	cgal_opt="--disable-cgal"
# fi
other_opts=""

# if we are on macos we need to add path to coreutils
os=$(uname -s)
if [ "${os}" == "Darwin" ]; then
    echo_warning "building on a mac? - ok!"
fi

cd {{srcdir}}

rm -rfv {{builddir}}
mkdir -p {{builddir}}
cd {{builddir}}

BUILD_TYPE="Release"
BUILD_DIR="{{builddir}}"
INSTALL_PREFIX="${install_prefix}"
BUILD_EXAMPLES="ON"
BUILD_TESTING="OFF"
# PARALLEL_JOBS=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
PARALLEL_JOBS={{n_cores}}

cmake -DCMAKE_BUILD_TYPE=${BUILD_TYPE} \
      -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX} \
      -DFASTJET_DIR=${fastjet_prefix} \
      -DCMAKE_CXX_STANDARD=17 \
      -DCMAKE_CXX_STANDARD_REQUIRED=ON \
      -DCMAKE_CXX_EXTENSIONS=OFF \
      -DBUILD_EXAMPLES=${BUILD_EXAMPLES} \
      -DBUILD_TESTING=${BUILD_TESTING} \
      ${cgal_opt} ${other_opts} \
      ${srcdir} && cmake --build . --target install -- -j {{n_cores}}

if [ "0x$?" != "0x0" ]; then
    echo_error "cmake build failed with exit code $?"
    exit 1
fi

if [ -e "${fragile_lib_path}" ]; then
    echo_info "fragile lib created: ${fragile_lib_path}"
else
    echo_error "fragile lib not created: ${fragile_lib_path}"
    exit 1
fi

exit $?
