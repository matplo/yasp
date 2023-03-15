#!/bin/bash

{{yasp}} -l

module use {{prefix}}/modules
module avail

for pack in yasp/current fastjet/3.4.0 fjcontrib/1.050 HepMC3/3.2.5 LHAPDF6/6.5.3 root/6.26.10 pythia8/8308
do
	module list
	{{yasp}} -i ${pack} -m
	if [ "0x$?" == "0x0" ]; then
		if [ -e "{{prefix}}/modules/${pack}" ]; then
			module load ${pack}
		fi
	else
		exit $?
	fi
done
