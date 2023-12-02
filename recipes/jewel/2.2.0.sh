#!/bin/bash

cd {{workdir}}
version=2.2.0
url=https://jewel.hepforge.org/downloads/?f=jewel-{{version}}.tar.gz
local_file={{workdir}}/jewel-{{version}}.tar.gz
{{yasp}} --download {{url}} --output {{local_file}}

tar zxvf {{local_file}}
srcdir={{workdir}}/jewel-{{version}}

cd {{builddir}}

# has to edit the Makefile
# LHAPDF_PATH := /path/to/lhapdf

rsync -avp ${srcdir} .
echo $PWD
ls -ltr
cd $(basename ${srcdir})
echo $PWD
ls -ltr

now=$(date '+%Y-%m-%d-%M-%S')
if [ ! -e Makefile.orig ]; then
	cp -v Makefile Makefile.orig
fi
le -fi Makefile.orig -o Makefile -r /path/to/lhapdf::${LHAPDF6_DIR}/lib
le -fi Makefile -o Makefile -r /home/lhapdf/install/lib/::${LHAPDF6_DIR}/lib

if [ "{{rebuild}}" != "None" ]; then
	echo "make clean first... {{rebuild}}"
	make clean
fi

make

if [ "0x$?" == "0x0" ]; then
	mkdir -vp {{prefix}}/settings
	cp -v *.dat {{prefix}}/settings
	mkdir -vp {{prefix}}/info
	cp -v *.txt {{prefix}}/info
	cp -v README GUIDELINES {{prefix}}/info
	mkdir -vp {{prefix}}/bin
	cp -v jewel-{{version}}-* {{prefix}}/bin
fi
exit $?

