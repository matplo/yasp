#!/bin/bash

cd {{workdir}}
version=3.10.13

export PYTHON_VERSION=${version}
export PYTHON_MAJOR=3

url=https://www.python.org/ftp/python/{{version}}/Python-{{version}}.tgz
local_file={{workdir}}/Python-{{version}}.tgz
{{yasp}} --download {{url}} --output {{local_file}}
srcdir={{workdir}}/Python-{{version}}
#yasp --set srcsdir={{workdir}}/root-{{version}}
if [ "x{{clean}}" == "True" ]; then
	rm -rf {{srcdir}}
	tar zxvf {{local_file}}
fi
[ ! -d "{{srcdir}}" ] && tar zxvf {{local_file}}

cd ${srcdir}
# sed -i 's/PKG_CONFIG openssl /PKG_CONFIG openssl11 /g' configure
cd {{builddir}}
# cd Python-${PYTHON_VERSION}
${srcdir}/configure --prefix={{prefix}} --enable-shared --enable-optimizations \
	--enable-ipv6 LDFLAGS=-Wl,-rpath={{prefix}}/lib,--disable-new-dtags

make -j {{n_cores}} && make install
exit $?
