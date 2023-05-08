#!/bin/bash

cd {{workdir}}
version=head
#yasp --set version=6.26.10
url=https://github.com/acts-project/acts
srcdir={{workdir}}/acts-{{version}}

[ -d "{{srcdir}}" ] && git clone {{url}} acts-{{version}}


if [ "x{{clean}}" == "True" ]; then
	rm -rf {{srcdir}}
fi

[ ! -d "{{srcdir}}" ] && exit -1
cd {{srcdir}}
git pull

cd {{builddir}}
# opts="-Dbuiltin_xrootd=OFF -Dmathmore=ON -Dxml=ON -Dvmc=OFF -Dxrootd=OFF"
opts="-DACTS_BUILD_FATRAS=ON -DACTS_BUILD_EXAMPLES=ON"
cmake -DCMAKE_INSTALL_PREFIX={{prefix}} \
	-DCMAKE_BUILD_TYPE=Release \
	${opts} \
	{{srcdir}} && cmake --build . --target install -- -j {{n_cores}}
exit $?

