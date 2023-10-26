#!/bin/bash

cd {{workdir}}
version=3.1.8
url=https://gitlab.com/hepcedar/rivetbootstrap/raw/{{version}}/rivet-bootstrap
local_file={{workdir}}/rivet-bootstrap
{{yasp}} --download {{url}} --output {{local_file}}
chmod +x {{local_file}}
echo "[i] boostrap file is at {{local_file}}"

cd {{builddir}}

export BUILD_PREFIX={{builddir}}
export INSTALL_PREFIX={{prefix}}
njobs=$(yasp -q feature cpu_count)
export MAKE="make -j${njobs}"
export CMAKE="cmake"

if [ "{{dev}}" != "None" ]; then
	echo "[i] setting INSTALL_RIVETDEV to 1"
	export INSTALL_RIVETDEV=1
fi

if [ "{{bootstrap}}" == "None" ] || [ "{{bootstrap}}" == "true" ]; then
	{{local_file}}
	else
	echo "[w] requested not to run bootstrap"
fi

force_jewel_flag={{force_jewel}}

if [ "{{jewel}}" != "None" ]; then
    if [ -e "{{builddir}}/Rivet-{{version}}/src/Projections/SubtractedJewelEvent.cc" ]; then
	echo "[w] detected JEWEL routines - overwrite with --define force_jewel=true"
    else
	force_jewel_flag="true"
    fi
    if [ ${force_jewel_flag} == "true" ]; then
	echo "[i] get the jewel subtraction {{jewel}} - ${force_jewel_flag}:{{force_jewel}}"
	echo "$PWD"
	jewel_out={{workdir}}/jewel_ConstSubProjection.tar
	{{yasp}} --download https://jewel.hepforge.org/files/ConstSubProjection.tar --output ${jewel_out}
	ls -ltr ${jewel_out}
	mkdir {{workdir}}/jewel_ConstSubProjection
	tar xvf ${jewel_out} -C {{workdir}}/jewel_ConstSubProjection
	ls -ltr {{workdir}}/jewel_ConstSubProjection
	cp -v {{workdir}}/jewel_ConstSubProjection/*.cc {{builddir}}/Rivet-{{version}}/src/Projections/
	cp -v {{workdir}}/jewel_ConstSubProjection/*.hh {{builddir}}/Rivet-{{version}}/include/Rivet/Projections/
	cc_code=$(cd {{workdir}}/jewel_ConstSubProjection/ && ls *.cc)
	echo "${cc_code}"
	cc_code="SubtractedJewelEvent.cc SubtractedJewelFinalState.cc"
	makefile_to_modify={{builddir}}/Rivet-{{version}}/src/Projections/Makefile.am
	now=$(date '+%Y-%m-%d-%M-%S')
	already_modified=$(cat ${makefile_to_modify} | grep SubtractedJewelEvent.cc)
	if [ -z "${already_modified}" ]; then
		cp -v ${makefile_to_modify} "${makefile_to_modify}-${now}"
		yaspreplstring -f ${makefile_to_modify} -o ${makefile_to_modify} --define FastJets.cc="FastJets.cc ${cc_code}"
	else
		echo "[w] NOT MODIFYING THE AM FILE - already modified"
	fi
    fi
    cd {{builddir}}/Rivet-{{version}} && autoreconf -i && make -j${njobs} && make install
fi

exit $?
