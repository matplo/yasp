#!/bin/bash

# path: recipes/bundle/sherpa2x.sh

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
	# $1 is selection - just check if this is in selected list
	# $2 is the pack name
	# $3 is has_module
	# $4 is build options
	local selection=$1
	local pack_name=$2
	if [ "x${pack_name}" == "x" ]; then
		[ "0x$?" != "0x0" ] && exit_with_error "pack name not set"
	fi
	if [ "x${selection}" != "xall" ]; then
		if [[ "${selection}" =~ "${pack_name}" || "${selection}" =~ "all" ]]; then
			echo_info "installing ${pack_name}"
		else
			echo_info "skipping ${pack_name}"
			return 0
		fi
	fi
	separator "installing ${pack_name}"
	local has_module=$3
	shift 3
	local options=$@
	if [ "x${has_module}" == "x" ]; then
		[ "0x$?" != "0x0" ] && exit_with_error "has module not set"
	fi
	echo_info "-- options [${options}] and has_module [${has_module}]"
	if [ "x${has_module}" == "xTrue" ]; then
		module list
		yasp -mi ${pack_name} ${options}
		[ "0x$?" != "0x0" ] && exit_with_error "install ${pack_name} failed" $?
		if [[ "--clean" =~ "${options}" || "--cleanup" =~ "${options}" ]]; then
			echo_info "just clean up ${pack_name}"
		else
			module load ${pack_name}
			[ "0x$?" != "0x0" ] && exit_with_error "module load ${pack_name} failed" $?
		fi
		return 0
	fi
	if [ "x${has_module}" == "xFalse" ]; then
		module list
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
selection="all"
if [ "x{{select}}" != "xNone" ]; then
	selection="{{select}}"
fi
separator "installing hepbase modules"
echo_info "selection is ${selection}"
echo_error "opts are ${opts}"

# sherpa2x wont work with fj 3.4.2 - use of depreciated code
install_package ${selection} fastjet/3.4.1 		True 			${opts} --workdir=${this_workdir} --prefix=${this_prefix} --opt version=3.4.1
install_package ${selection} fjcontrib/1.054 	False 		${opts} --workdir=${this_workdir} --prefix=${this_prefix} --opt version=1.054  #make_check=True 
install_package ${selection} jetflav/default 	False 										
install_package ${selection} HepMC2/default 	True 			${opts} --workdir=${this_workdir} --prefix=${this_prefix} --opt version=2.06.11
install_package ${selection} LHAPDF6/6.5.4 		True 			${opts} --workdir=${this_workdir} --prefix=${this_prefix} --opt version=6.5.4
install_package ${selection} root/6.26.10 		True 			${opts} --workdir=${this_workdir} --prefix=${this_prefix} --opt version=6.26.10
install_package ${selection} HepMC3/default 	True 			${opts} --workdir=${this_workdir} --prefix=${this_prefix} --opt version=3.2.7
install_package ${selection} pythia8/8310		 	True 			${opts} --workdir=${this_workdir} --prefix=${this_prefix} --opt version=8310
install_package ${selection} sherpa/2.2.15 		True 			${opts} --workdir=${this_workdir} --prefix=${this_prefix} --opt version=2.2.15 cxx14=true

if [[ ! -z "{{clean}}" ]]; then
	echo_info "just clean up - no super module creation"
else
	module_name=$(basename $(dirname ${this_prefix}))/$(basename ${this_prefix})
	note "making a super module: ${module_name}"
	yasp --mm ${module_name} 
fi
[ "0x$?" != "0x0" ] && exit_with_error $?
exit 0
