#!/bin/bash

cd {{workdir}}
version=3.11.2

echo "[i] make sure you install some deps... - for CENTOS for example"
echo "sudo yum install yum-utils"
echo "sudo yum install libffi-devel sqlite-devel zlib zlib-devel "

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
echo "[i] fix for CentOS7"
echo "sudo yum install -y epel"
echo "sudo yum install -y openssl11-devel"
cd ${srcdir}
sed -i 's/PKG_CONFIG openssl /PKG_CONFIG openssl11 /g' configure
cd {{builddir}}
# cd Python-${PYTHON_VERSION}
${srcdir}/configure --prefix={{prefix}} --enable-shared --enable-optimizations \
	--enable-ipv6 LDFLAGS=-Wl,-rpath={{prefix}}/lib,--disable-new-dtags

make && make install
exit $?
