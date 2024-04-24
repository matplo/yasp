#!/bin/bash

cd {{workdir}}
#version=3.3.3
version=3.4.1
url=http://fastjet.fr/repo/fastjet-{{version}}.tar.gz
local_file={{workdir}}/fastjet-{{version}}.tar.gz
{{yasp}} --download {{url}} --output {{local_file}}
tar zxvf {{local_file}}
srcdir={{workdir}}/fastjet-{{version}}

cd {{builddir}}
if [ -d "${CGAL_DIR}" ]; then
	# cgal_opt="--with-cgaldir=${CGAL_DIR} --enable-cgal-header-only"
	# echo "$CGAL_DIR"
	cgal_opt="--enable-cgal-header-only --with-cgaldir=${CGAL_DIR}"
else
	cgal_opt="--disable-cgal"
fi
other_opts="--enable-allcxxplugins --enable-allplugins"
# not enabling the swig interface --enable-pyext
#system=$(gcc -dumpmachine)
#echo "{{srcdir}}/configure --prefix={{prefix}} --build=${system} --host=${system} ${cgal_opt} ${other_opts} "
#{{srcdir}}/configure --prefix={{prefix}} --build=${system} --host=${system} ${cgal_opt} ${other_opts} && make -j {{n_cores}} && make install
{{srcdir}}/configure --prefix={{prefix}} ${cgal_opt} ${other_opts} && make -j {{n_cores}} && make install
exit $?
