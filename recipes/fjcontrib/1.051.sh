#!/bin/bash

cd {{workdir}}
version=1.051
url=https://fastjet.hepforge.org/contrib/downloads/fjcontrib-{{version}}.tar.gz
local_file={{workdir}}/fjcontrib-{{version}}.tar.gz
{{yasp}} --download {{url}} --output {{local_file}}
tar zxvf {{local_file}}
srcdir={{workdir}}/fjcontrib-{{version}}
cd {{srcdir}}
fjconfig=$(which fastjet-config)
if [ ! -e "${fjconfig}" ]; then
	echo "[e] no fastjet-config [${fjconfig} ] this will not work"
	exit -1
else
	echo "[i] using ${fjconfig}"
fi
# the line below would use the default fj picked by yasp - not always what wanted...
#if [ -z "${fastjet_prefix}" ]; then
#	   fastjet_prefix=$({{yasp}} -q feature prefix -i fastjet)
#fi
# this produces only static libs
fjlibs=$(${fjconfig} --libs)
./configure --fastjet-config=${fjconfig} --prefix=${fastjet_prefix} && make -j {{n_cores}} all && make check && make install
# add a cmake for dynamic libs!
if [ $? -eq 0 ]
then
	make clean
	./configure --fastjet-config=${fjconfig} --prefix=${fastjet_prefix} CXXFLAGS=-fPIC && make -j {{n_cores}} all && make check && make install
	contribs=$(./configure --list)
	for c in ${contribs}
	do
		cd ${c}
		rm *example*.o
		shlib=${fastjet_prefix}/lib/lib${c}.so
		# {{CXX}} -fPIC -shared -o ${shlib} *.o -Wl,-rpath,${fastjet_prefix}/lib -L${fastjet_prefix}/lib -lfastjettools -lfastjet
		{{CXX}} -fPIC -shared -o ${shlib} *.o ${fjlibs}
		if [ -f ${shlib} ]; then
			echo "[i] shared lib created ${shlib}"
		else
			echo "[i] shared lib NOT created ${shlib}"
		fi
		cd {{srcdir}}
	done
fi
exit $?
