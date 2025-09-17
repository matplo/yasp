#!/bin/bash

source ${YASP_DIR}/src/util/bash/util.sh

separator "cmake"
echo_info "version: {{version}}"
echo_info "using workdir: {{workdir}}"
echo_info "using prefix: {{prefix}}"
echo_info "using n_cores: {{n_cores}}"
echo_info "using yasp: {{yasp}}"
cd {{workdir}}
version=3.31.7
url=https://github.com/Kitware/CMake/releases/download/v{{version}}/cmake-{{version}}.tar.gz
local_file={{workdir}}/cmake_v{{version}}.tar.gz
{{yasp}} --download {{url}} --output {{local_file}}
srcdir={{workdir}}/cmake-{{version}}
if [ "x{{clean}}" == "True" ]; then
	rm -rf {{srcdir}}
	tar zxvf {{local_file}}
fi
[ ! -d "{{srcdir}}" ] && tar zxvf {{local_file}}
cd {{builddir}}

echo_info "using builddir: {{builddir}}"
echo_info "using srcdir: {{srcdir}}"

# Configure, build, and install
${srcdir}/configure --prefix={{prefix}} && make -j$(nproc) && make install