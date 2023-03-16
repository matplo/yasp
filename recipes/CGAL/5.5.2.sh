#!/bin/bash

cd {{workdir}}
version=5.5.2
url=https://github.com/CGAL/cgal/releases/download/v{{version}}/CGAL-{{version}}.tar.xz
local_file={{workdir}}/CGAL-{{version}}.tar.xz
{{yasp}} --download {{url}} --output {{local_file}}
tar xvf {{local_file}}
srcdir={{workdir}}/CGAL-{{version}}

cd {{builddir}}
cmake -DCMAKE_INSTALL_PREFIX={{prefix}} -DCMAKE_BUILD_TYPE=Release ${srcdir} && make -j {{n_cores}} install 		  # configure CGAL and # install CGAL

if [ "0x$?" == "0x0" ]; then
	if [ -d "examples/Triangulation_2" ]; then
		cd examples/Triangulation_2                                                       # go to an example directory
		cmake -DCGAL_DIR={{prefix}}/lib/CGAL -DCMAKE_BUILD_TYPE=Release .  && make -j {{n_cores}} # configure the examples and # build the examples
	fi
fi
exit $?
