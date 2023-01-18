#!/bin/bash

cd {{workdir}}
version=1.050
url=https://fastjet.hepforge.org/contrib/downloads/fjcontrib-{{version}}.tar.gz
local_file={{workdir}}/fjcontrib-{{version}}.tar.gz
{{yasp}} --download {{url}} --output {{local_file}}
tar zxvf {{local_file}}
srcdir={{workdir}}/fjcontrib-{{version}}
cd {{srcdir}}
# this produces only static libs
./configure --fastjet-config={{prefix}}/bin/fastjet-config --prefix={{prefix}} && make -j {{n_cores}} all && make check && make install
# add a cmake for dynamic libs!
if [ $? -eq 0 ] 
then
	make clean 
	./configure --fastjet-config={{prefix}}/bin/fastjet-config --prefix={{prefix}} CXXFLAGS=-fPIC && make -j {{n_cores}} all && make check && make install
	contribs=$(./configure --list)
	for c in ${contribs}
	do
		cd ${c}
		rm *example*.o
		shlib={{prefix}}/lib/lib${c}.so
		{{CXX}} -fPIC -shared -o ${shlib} *.o -Wl,-rpath,{{prefix}}/lib -L{{prefix}}/lib -lfastjettools -lfastjet
		if [ -f ${shlib} ]; then
			echo "[i] shared lib created ${shlib}"
		else
			echo "[i] shared lib NOT created ${shlib}"
		fi
		cd {{srcdir}}	
	done
fi
exit $?
