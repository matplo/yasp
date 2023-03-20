#!/bin/bash

{{yasp}} -l

softprefix=$({{yasp}} -q feature prefix)

module use ${softprefix}/modules
module avail

# for pack in fastjet/3.4.0 fjcontrib/1.051 HepMC3/3.2.5 LHAPDF6/6.5.3 root/6.26.10 pythia8/8308
for pack in fastjet fjcontrib HepMC3 LHAPDF6 root pythia8
do
	module list
	{{yasp}} -i ${pack} -m
	if [ "0x$?" == "0x0" ]; then
		if [ -e "${softprefix}/modules/${pack}" ]; then
			echo "[i] loading module ${pack}"
			module load ${pack}
			module list
		else
			echo "[w] module ${softprefix}/modules/${pack} does not exist - but that may be ok."
		fi
	else
		echo "[i] build of ${pack} exited with $?"
		exit -1
	fi
done
