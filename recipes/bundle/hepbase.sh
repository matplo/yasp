#!/bin/bash

# path: recipes/bundle/hepbase.sh

version="default"
this_prefix="{{prefix}}"
this_workdir="{{workdir}}"
module use ${this_prefix}/modules

source ${YASP_DIR}/src/util/bash/util.sh

separator "setting up hepbase"
note "version: ${version}"

cd ${YASP_DIR}

cd {{workdir}}
echo $PWD
module list


function exit_with_error()
{
	echo_error "bailing out: $@"
	exit 1
}

function install_package()
{
	# $1 is the pack name
	# $2 is has_module
	# $3 is build options
	local pack_name=$1
	if [ "x${pack_name}" == "x" ]; then
		[ "0x$?" != "0x0" ] && exit_with_error "pack name not set"
	fi
	local has_module=$2
	shift 2
	local options=$@
	if [ "x${has_module}" == "x" ]; then
		[ "0x$?" != "0x0" ] && exit_with_error "has module not set"
	fi
	echo_info "installing [${pack_name}] with options [${options}] and has_module [${has_module}]"
	if [ "x${has_module}" == "xTrue" ]; then
		yasp -mi ${pack_name} ${options}
		[ "0x$?" != "0x0" ] && exit_with_error "install ${pack_name} failed" $?
		if [[ "--clean" =~ "${options}" ]]; then
			echo_info "just clean up ${pack_name}"
		else
			module load ${pack_name}
			[ "0x$?" != "0x0" ] && exit_with_error "module load ${pack_name} failed" $?
		fi
		return 0
	fi
	if [ "x${has_module}" == "xFalse" ]; then
		yasp -i ${pack_name} ${options}
		[ "0x$?" != "0x0" ] && exit_with_error "install ${pack_name} failed" $?
		return 0
	fi
	[ "0x$?" != "0x0" ] && exit_with_error "failed to install ${pack_name} - missing has_module setting"
	exit 1
}

# dry="--dry-run"
dry=""
clean=""
default=""
opts="{{clean}} {{dry}} {{default}}"
separator "installing hepbase modules"
separator "fastjet"
echo_error "opts are ${opts}"
install_package fastjet/3.4.2 		True 			 ${opts} --workdir=${this_workdir} --prefix=${this_prefix} --opt version=3.4.2
[ "0x$?" != "0x0" ] && exit_with_error $?
separator "fjcontrib"
install_package fjcontrib/1.054 	False 		 ${opts} --workdir=${this_workdir} --prefix=${this_prefix} --opt version=1.054  #make_check=True 
[ "0x$?" != "0x0" ] && exit_with_error $?
separator "jetflav"
install_package jetflav/default 	False 										
[ "0x$?" != "0x0" ] && exit_with_error $?
separator "hepmc2"
install_package HepMC2/default 	True 			 ${opts} --workdir=${this_workdir} --prefix=${this_prefix} --opt version=2.06.11
[ "0x$?" != "0x0" ] && exit_with_error $?
separator "lhapdf6"
install_package LHAPDF6/6.5.4 		True 			 ${opts} --workdir=${this_workdir} --prefix=${this_prefix} --opt version=6.5.4
[ "0x$?" != "0x0" ] && exit_with_error $?
separator "root"
install_package root/default 		True 			 ${opts} --workdir=${this_workdir} --prefix=${this_prefix} --opt version=6.30.06
[ "0x$?" != "0x0" ] && exit_with_error $?
separator "hepmc3"
install_package HepMC3/default 	True 			 ${opts} --workdir=${this_workdir} --prefix=${this_prefix} --opt version=3.2.7
[ "0x$?" != "0x0" ] && exit_with_error $?
separator "pythia8"
install_package pythia8/default 	True 			 ${opts} --workdir=${this_workdir} --prefix=${this_prefix} --opt version=8311
[ "0x$?" != "0x0" ] && exit_with_error $?
# sherpa wont work with fj 3.4.2 and lower version of fj wont work with new root (cxx17)
# separator "sherpa" 
# install_package sherpa/2.2.15 		True 			 ${opts} --workdir=${this_workdir} --prefix=${this_prefix} --opt version=2.2.15 
# [ "0x$?" != "0x0" ] && exit_with_error $?
module_name=$(basename $(dirname ${this_prefix}))/$(basename ${this_prefix})
note "making a super module: ${module_name}"
yasp --mm ${module_name} --prefix=${this_prefix}
[ "0x$?" != "0x0" ] && exit_with_error $?
exit 0
