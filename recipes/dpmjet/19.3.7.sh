#!/bin/bash

cd {{workdir}}
version=19.3.7
url=https://github.com/DPMJET/DPMJET/archive/refs/tags/v{{version}}.tar.gz
local_file={{workdir}}/dpmjet-{{version}}.tar.gz
{{yasp}} --download {{url}} --output {{local_file}}
tar zxvf {{local_file}}
srcdir={{workdir}}/dpmjet-{{version}}
if [ ! -d $srcdir ]; then
	srcdir={{workdir}}/DPMJET-{{version}}
fi

if [ -d $srcdir ]; then
	echo "DPMJET source directory exists"
else
	echo "DPMJET source directory does not exist"
	exit 1
fi

if ! command -v f77 &> /dev/null; then
    echo "f77 not found, using gfortran instead."
    FC=gfortran
else
    FC=f77
fi

export FC
$FC --version

# build in source
# cd {{builddir}}
echo {{srcdir}}
cd {{srcdir}}
make -j {{n_cores}} exe

bresult=$?
if [ $bresult -eq 0 ]; then
		echo "DPMJET build successful"
		echo "installing..."
		mkdir -p {{prefix}}/bin
		cp -r {{srcdir}}/bin/* {{prefix}}/bin
		mkdir -p {{prefix}}/lib
		cp -r {{srcdir}}/lib/* {{prefix}}/lib
		mkdir -p {{prefix}}/include
		cp -r {{srcdir}}/include/* {{prefix}}/include
fi
# Run example
# bin/DPMJET < examples/dpmjet/ppLHC.inp
exit $bresult
