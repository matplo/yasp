#!/bin/bash

source ${YASP_DIR}/src/util/bash/util.sh

export RUGITREPO=https://gitlab.cern.ch/RooUnfold/RooUnfold.git
version=master

#ezrasru=$(get_opt "ezra" $@)
#if [ ! -z ${ezrasru} ]; then
#    export RUGITREPO=https://gitlab.cern.ch/elesser/RooUnfold.git
#    version=master
#fi

separator "RooUnfold"
echo_info "[i] Using RooUnfold at ${RUGITREPO} {{version}}"
echo_info "    version={{version}}"

cd {{workdir}} && rm -rf RooUnfold
git clone ${RUGITREPO}
srcdir={{workdir}}/RooUnfold
build_dir={{workdir}}/build
if [ "{{version}}" != "master" ]; then
    cd {{srcdir}}
    echo_warning "checking out version {{version}}"
    git checkout tags/{{version}} -b {{version}}-dev
fi
cd {{build_dir}}
cmake {{srcdir}} -DCMAKE_INSTALL_PREFIX={{prefix}} -DCMAKE_BUILD_TYPE=Release
#make -j {{n_cores}}
cmake --build . --target install -- -j {{n_cores}}

exit $?
