#!/bin/bash

export RUGITREPO=https://gitlab.cern.ch/RooUnfold/RooUnfold.git
roounfold_version=master

#ezrasru=$(get_opt "ezra" $@)
#if [ ! -z ${ezrasru} ]; then
#    export RUGITREPO=https://gitlab.cern.ch/elesser/RooUnfold.git
#    roounfold_version=master
#fi

echo "[i] Using RooUnfold at ${RUGITREPO} ${roounfold_version}"
echo "    version=${roounfold_version}"

cd {{workdir}} && rm -rf RooUnfold
git clone ${RUGITREPO}
srcdir={{workdir}}/RooUnfold
build_dir={{workdir}}/build
if [ ! {{roounfold_version}} == master ]; then
    git checkout {{roounfold_version}}
fi
cd {{build_dir}}
cmake {{srcdir}} -DCMAKE_INSTALL_PREFIX={{prefix}} -DCMAKE_BUILD_TYPE=Release
#make -j {{n_cores}}
cmake --build . --target install -- -j {{n_cores}}

exit $?
