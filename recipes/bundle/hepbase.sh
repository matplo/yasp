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
echo_warning "[w] clean requested: ${clean_opt}"

function exit_with_error()
{
	echo_error "bailing out: $@"
	exit 1
}

function install_hepbase_module()
{
	# $1 is the pack name
	# $2 is has_module
	# $3 is build options
	local pack_name=$1
	if [ "x${pack_name}" == "x" ]; then
		exit_with_error "pack name not set"
	fi
	local has_module=$2
	shift 2
	local options=$@
	if [ "x${has_module}" == "x" ]; then
		exit_with_error "has module not set"
	fi
	echo_info "installing [${pack_name}] with options [${options}] and has_module [${has_module}]"
	if [ "x${has_module}" == "xTrue" ]; then
		yasp -mi ${pack_name} ${options}
		exit_with_error "isntallation ${pack_name} failed" $?
		module load ${pack_name}
		exit_with_error "module load ${pack_name} failed" $?
		return
	fi
	if [ "x${has_module}" == "xFalse" ]; then
		yasp -i ${pack_name} ${options}
		exit_with_error "isntallation ${pack_name} failed" $?
		return
	fi
	exit_with_error "failed to install ${pack_name} - missing has_module setting"
	exit 1
}

# dry="--dry-run"
dry=""
default_asnwer="--no"
opts="--opt clean=${clean_opt} ${dry} ${default_asnwer}"
install_hepbase_module fastjet/3.4.2 	True 	--opt version=3.4.2				${opts}
exit_with_error $?
install_hepbase_module fjcontrib/1.054 	False 	--opt version=1.054		${opts} 
exit_with_error $?
install_hepbase_module jetflav/default 	False 												${opts}
exit_with_error $?
install_hepbase_module HepMC2/default 	True 	--opt version=2.06.11		${opts}
exit_with_error $?
install_hepbase_module HepMC3/default 	True 	--opt version=3.2.7			${opts}
exit_with_error $?
install_hepbase_module LHAPDF6/6.5.4 	True 	--opt version=6.5.4				${opts}
exit_with_error $?
install_hepbase_module root/default 	True 	--opt version=6.30.06			${opts}
exit_with_error $?
install_hepbase_module pythia8/default 	True 	--opt version=8.311			${opts}
exit_with_error $?
install_hepbase_module sherpa/2.2.15 	True 	--opt version=2.2.15 			${opts}
exit_with_error $?
exit 0