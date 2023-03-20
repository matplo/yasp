#!/bin/bash
cd {{workdir}}
version=6.5.3
url=https://lhapdf.hepforge.org/downloads/?f=LHAPDF-{{version}}.tar.gz
local_file={{workdir}}/LHAPDF-{{version}}.tar.gz
{{yasp}} --download {{url}} --output {{local_file}}
tar zxvf {{local_file}}
srcdir={{workdir}}/LHAPDF-{{version}}

# cd {{builddir}}
# {{srcdir}}/configure --prefix={{prefix}} ${other_opts} && make -j {{n_cores}} && make install
cd {{srcdir}}
./configure --prefix={{prefix}} ${other_opts} --with-python-sys-prefix && make -j {{n_cores}} && make install

excode=$?

if [ ! "0x${excode}" == "0x0" ]; then
	_system=$(uname -s)
	if [ "${_system}" == "Darwin" ]; then
		echo "[i] work around for MacOsX - if the build of the python tool fails try (and run install again):"
		libdir=$(python -c "import sysconfig; print(sysconfig.get_config_var('LIBDIR'));")
		echo "ln -s ${libdir}/../../../../Python.framework ${libdir}"
	fi
fi

if [ "0x${excode}" == "0x0" ]; then
	# example for installing PDFs
	# lhapdf install CT10nlo
	# or - here just for a test...
	wget http://lhapdfsets.web.cern.ch/lhapdfsets/current/CT10nlo.tar.gz -O- | tar xz -C {{prefix}}/share/LHAPDF
fi

exit ${excode}
