#!/bin/bash

# path: recipes/bundle/hepbase.sh

version="default"

source ${YASP_DIR}/src/util/bash/util.sh

separator "setting up hepbase"
note "version: ${version}"

cd ${YASP_DIR}

cd {{workdir}}
echo $PWD
module list

clean_opt={{clean}}
echo_warning "clean requested: ${clean_opt}"
exit 1

function install_hepbase_module()
{
	local pack_name=$1
	if [ "x${pack_name}" == "x" ]; then
		echo_error "pack name not set"
		exit 1
	fi
	local has_module=$2
	shift 2
	local options=$@
	if [ "x${has_module}" == "x" ]; then
		echo_error "has module not set"
		exit 1
	fi
	echo_info "installing [${pack_name}] with options [${options}] and has_module [${has_module}]"
	if [ "x${has_module}" == "xTrue" ]; then
		yasp -mi ${pack_name} ${options}
		[ "0x$?" != "0x0" ] && exit 1
		module load ${pack_name}
		[ "0x$?" != "0x0" ] && exit 1
		return
	fi
	if [ "x${has_module}" == "xFalse" ]; then
		yasp -i ${pack_name} ${options}
		[ "0x$?" != "0x0" ] && exit 1
		return
	fi
	echo_error "failed to install ${pack_name} - missing has_module setting"
	exit 1
}

dry="--dry-run"
install_hepbase_module fastjet/default 	True 	--opt version=3.4.2		${dry}
install_hepbase_module fjcontrib/1.054 	False 	--opt version=1.054		${dry} 
install_hepbase_module jetflav/default 	False 							${dry}
install_hepbase_module HepMC2/default 	True 	--opt version=2.06.11	${dry}
install_hepbase_module HepMC3/default 	True 	--opt version=3.2.7		${dry}
install_hepbase_module LHAPDF6/6.5.4 	True 	--opt version=6.5.4		${dry}
install_hepbase_module root/default 	True 	--opt version=6.30.06	${dry}
install_hepbase_module pythia8/default 	True 	--opt version=8.311		${dry}
install_hepbase_module sherpa/2.2.15 	True 	--opt version=2.2.15 	${dry}
