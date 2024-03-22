#!/bin/bash


cd {{workdir}}
version=dev
url=https://github.com/dpiparo/vdt.git

srcdir={{workdir}}/vdt
if [ -d ${srcdir} ]; then
	cd ${srcdir}
	git pull
else
	git clone ${url}
fi
echo "[i] source dir is ${srcdir}"

cd {{builddir}}

cmake -DCMAKE_INSTALL_PREFIX={{prefix}} -DCMAKE_PROJECT_VERSION=0.{{version}} -B{{builddir}} ${srcdir} && make -j {{n_cores}} && make install

exit $?
