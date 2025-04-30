#!/bin/bash

source ${YASP_DIR}/src/util/bash/util.sh

separator "fastjet from GITLAB repository"
echo_info "version: {{version}}"
echo_warning "this is a development version - use at your own risk"
echo_info "using workdir: {{workdir}}"
echo_info "using prefix: {{prefix}}"
echo_info "using n_cores: {{n_cores}}"

cd {{workdir}}
version=master
url=https://gitlab.com/fastjet/fastjet.git
# local_file={{workdir}}/fastjet-{{version}}.tar.gz
# {{yasp}} --download {{url}} --output {{local_file}}
# tar zxvf {{local_file}}

echo "[i] Using FastJet at ${url} {{version}}"
echo "fastjet-version is:" fastjet-{{version}}

cd {{workdir}} && rm -rf fastjet-{{version}}
git clone ${url} fastjet-{{version}}
srcdir={{workdir}}/fastjet-{{version}}
build_dir={{workdir}}/build

if [ "{{version}}" != "master" ]; then
		cd {{srcdir}}
		git checkout tags/{{version}} -b {{version}}
fi

#srcdir={{workdir}}/fastjet-{{version}}

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

#{{srcdir}}/configure --prefix={{prefix}} ${cgal_opt} ${other_opts} && make -j {{n_cores}} && make install

# if we are on macos we need to add path to coreutils
os=$(uname -s)
if [ "${os}" == "Darwin" ]; then
	echo_warning "you may need: brew install libtool automake autoconf"
	#cgal_opt="--enable-cgal-header-only --with-cgaldir=${CGAL_DIR}"
	#other_opts="--enable-allcxxplugins --enable-allplugins"
	#other_opts="${other_opts} --with-gslinc=/opt/homebrew/Cellar/gsl/2.7.2/include"
	#other_opts="${other_opts} --with-gsllib=/opt/homebrew/Cellar/gsl/2.7.2/lib"
	brew_libtool_dir=/opt/homebrew/opt/libtool/libexec/gnubin
	if [ -d ${brew_libtool_dir} ]; then
		echo "adding ${brew_libtool_dir} to path"
		PATH="${brew_libtool_dir}:$PATH"
	else
		echo_error "not adding ${brew_libtool_dir} to path - does not exist - stop here"
	fi
fi

cd {{srcdir}}
git submodule init
git submodule update
# ./autogen.sh --prefix={{prefix}} ${cgal_opt} ${other_opts} 
autoreconf --install --force
cd plugins/SISCone/siscone; autoreconf --install; cd ../../..

rm -rfv {{builddir}}
cd {{builddir}}
{{srcdir}}/configure --prefix={{prefix}} ${cgal_opt} ${other_opts} && make -j {{n_cores}} && make install

# && make -j {{n_cores}} && make install

# cd {{builddir}}
# {{srcdir}}/configure --prefix={{prefix}} ${cgal_opt} ${other_opts} && make -j {{n_cores}} && make install

exit $?
