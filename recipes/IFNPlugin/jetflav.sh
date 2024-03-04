#!/bin/bash

function lib_suffix()
{
	# Get the operating system name
	os_name=$(uname -s)

	# Initialize the library suffix variable
	lib_suffix=""

	# Determine the suffix based on the operating system
	case "$os_name" in
		Linux)
			lib_suffix=".so"
			;;
		Darwin)
			lib_suffix=".dylib"
			;;
		CYGWIN*|MINGW*|MSYS*)
			lib_suffix=".dll"
			;;
		*)
			echo "Unsupported operating system: $os_name"
			echo "unknown"
			;;
	esac
	echo "$lib_suffix"
}

cd {{workdir}}
version=jetflav
url=git@github.com:jetflav/IFNPlugin.git
url=https://github.com/jetflav/IFNPlugin.git
local_file={{workdir}}/IFNPlugin.git
# {{yasp}} --download {{url}} --output {{local_file}}
git clone {{url}} {{local_file}}
srcdir={{local_file}}
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
fastjet_prefix=$(fastjet-config --prefix)
# this produces only static libs
make -j && make -j example && ./example < data/pythia8_Zq_vshort.dat && make -j check && make install

# add a command to make dynamic libs
if [ $? -eq 0 ]
then
	lib_suffix=$(lib_suffix)
	shlib=${fastjet_prefix}/lib/libIFNPlugin${lib_suffix}
	{{CXX}} -fPIC -shared -o ${shlib} *.o -Wl,-rpath,${fastjet_prefix}/lib -L${fastjet_prefix}/lib -lfastjettools -lfastjet
	# {{CXX}} -fPIC -shared -o ${shlib} *.o ${fjlibs}
	if [ -f ${shlib} ]; then
		echo "[i] shared lib created ${shlib}"
	else
		echo "[i] shared lib NOT created ${shlib}"
	fi
fi
exit $?
