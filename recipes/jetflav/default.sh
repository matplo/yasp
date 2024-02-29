#!/bin/bash

# First check for FastJet
fjconfig=$(which fastjet-config)
if [ ! -e "${fjconfig}" ]; then
	echo "[e] no fastjet-config [${fjconfig} ] this will not work"
	exit -1
else
	echo "[i] using ${fjconfig}"
fi

# IFNPlugin  https://github.com/jetflav/IFNPlugin
cd {{workdir}}
url_IFN=https://github.com/jetflav/IFNPlugin/archive/refs/heads/main.zip
local_file_IFN={{workdir}}/IFNPlugin.zip
{{yasp}} --download {{url_IFN}} --output {{local_file_IFN}}
unzip -o {{local_file_IFN}}
srcdir_IFN={{workdir}}/IFNPlugin
rm -rf {{srcdir_IFN}} && mv {{srcdir_IFN}}-main {{srcdir_IFN}}
cd {{srcdir_IFN}}
make -j {{n_cores}} && make -j {{n_cores}} check && make install
# Check example
#make -j {{n_cores}} example && ./example < {{srcdir_IFN}}/data/pythia8_Zq_vshort.dat

# GHSAlgo  https://github.com/jetflav/GHSAlgo
cd {{workdir}}
url_GHS=https://github.com/jetflav/GHSAlgo/archive/refs/heads/master.zip
local_file_GHS={{workdir}}/GHSAlgo.zip
{{yasp}} --download {{url_GHS}} --output {{local_file_GHS}}
unzip -o {{local_file_GHS}}
srcdir_GHS={{workdir}}/GHSAlgo
rm -rf {{srcdir_GHS}} && mv {{srcdir_GHS}}-master {{srcdir_GHS}}
cd {{srcdir_GHS}}
make -j {{n_cores}} all && make install
#make -j {{n_cores}} check  # Test is failing! // Open issue on GitHub
# Check example
#make -j {{n_cores}} example && ./example < {{srcdir_GHS}}/data/pythia8_Zq_vshort.dat

# SDFlavPlugin  https://github.com/jetflav/SDFlavPlugin
cd {{workdir}}
url_SDF=https://github.com/jetflav/SDFlavPlugin/archive/refs/heads/master.zip
local_file_SDF={{workdir}}/SDFlavPlugin.zip
{{yasp}} --download {{url_SDF}} --output {{local_file_SDF}}
unzip -o {{local_file_SDF}}
srcdir_SDF={{workdir}}/SDFlavPlugin
rm -rf {{srcdir_SDF}} && mv {{srcdir_SDF}}-master {{srcdir_SDF}}
cd {{srcdir_SDF}}
make -j {{n_cores}} all
# Check example -- no working make check at the moment...
make -j {{n_cores}} example
./run < {{srcdir_SDF}}/data/*.dat > example.test_out
diff example.ref example.test_out > example.diff

# CMPPlugin  https://github.com/jetflav/CMPPlugin
cd {{workdir}}
url_CMP=https://github.com/jetflav/CMPPlugin/archive/refs/heads/master.zip
local_file_CMP={{workdir}}/CMPPlugin.zip
{{yasp}} --download {{url_CMP}} --output {{local_file_CMP}}
unzip -o {{local_file_CMP}}
srcdir_CMP={{workdir}}/CMPPlugin
rm -rf {{srcdir_CMP}} && mv {{srcdir_CMP}}-master {{srcdir_CMP}}
cd {{srcdir_CMP}}
make -j {{n_cores}} all
# Currently no utils/ on master... so copy from GHSAlgo
if [ ! -d "{{srcdir_CMP}}/utils" ]; then
    cp -rf {{srcdir_GHS}}/utils {{srcdir_CMP}}
fi
make -j {{n_cores}} check && make install

exit $?
