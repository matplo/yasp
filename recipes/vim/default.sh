#!/bin/bash

cd {{workdir}}
version=dev
url=https://github.com/vim/vim.git

srcdir={{workdir}}/vim
if [ -d ${srcdir} ]; then
	cd ${srcdir}
	git pull
else
	git clone ${url}
fi
echo "[i] source dir is ${srcdir}"

cd {{builddir}}
cp -r ${srcdir} .
cd ./vim
./configure --prefix={{prefix}} && make -j {{n_cores}} && make install
exit $?
