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
opts="{{clean}} {{dry}} {{default}} --yasp-define n_cores={{n_cores}}"
selection="all"
if [ "x{{select}}" != "xNone" ]; then
	selection="{{select}}"
fi
separator "installing hepbase modules"
echo_info "selection is ${selection}"
note "opts are ${opts}"

rootspec=default

# check what the current version of cmake is
cmake_version=$(cmake --version | grep version | awk '{print $3}')
if [ "x${cmake_version}" == "x" ]; then
	echo_error "cmake version not set - exiting"
	exit 1
fi
# if cmake version is >= 4 then install the older version
cmake_version_major=$(echo ${cmake_version} | cut -d'.' -f1)
if [ "${cmake_version_major}" -ge 4 ]; then
	warning "cmake version is ${cmake_version} - installing older version"
	install_package ${selection} cmake/3.31.7 		True 			 	${opts} --workdir=${this_workdir} --prefix=${this_prefix}
else
	note "cmake version is ${cmake_version} - OK"
fi
# install_package ${selection} fastjet/3.4.2 		True 			 	${opts} --workdir=${this_workdir} --prefix=${this_prefix} --opt version=3.4.3
# install_package ${selection} fastjet/master 		True 			 	${opts} --workdir=${this_workdir} --prefix=${this_prefix}
install_package ${selection} fastjet/3.4.2 		True 			 	${opts} --workdir=${this_workdir} --prefix=${this_prefix} --opt version=3.5.1
# install_package ${selection} fjcontrib/1.054 	False 		 	${opts} --workdir=${this_workdir} --prefix=${this_prefix} --opt version=1.054  #make_check=True 
# install_package ${selection} fjcontrib/1.101 	False 		 	${opts} --workdir=${this_workdir} --prefix=${this_prefix} --opt version=1.101  #make_check=True
install_package ${selection} fjcontrib/mp 	False 		 	${opts} --workdir=${this_workdir} --prefix=${this_prefix}
# jetflav already in fjcontrib...
#install_package ${selection} jetflav/default 	False 										
install_package ${selection} HepMC2/default 	True 			 	${opts} --workdir=${this_workdir} --prefix=${this_prefix} --opt version=2.06.11
install_package ${selection} LHAPDF6/6.5.4 		True 			 	${opts} --workdir=${this_workdir} --prefix=${this_prefix} --opt version=6.5.5
install_package ${selection} root/{{rootspec}} 		True 			 	${opts} --workdir=${this_workdir} --prefix=${this_prefix} --opt version=6.36.00
install_package ${selection} HepMC3/default 	True 			 	${opts} --workdir=${this_workdir} --prefix=${this_prefix} --opt version=3.3.1
install_package ${selection} pythia8/default		 	True 			 	${opts} --workdir=${this_workdir} --prefix=${this_prefix} --opt version=8315
install_package ${selection} roounfold/default 	True 			${opts} --workdir=${this_workdir} --prefix=${this_prefix} --opt version=3.0.5
# install_package ${selection} roounfold/default 	True 			${opts} --workdir=${this_workdir} --prefix=${this_prefix} --opt version=2.1
install_package ${selection} dpmjet/19.3.7 			True 			${opts} --workdir=${this_workdir} --prefix=${this_prefix} --opt version=19.3.7
install_package ${selection} starlight/default 	True 			${opts} --workdir=${this_workdir} --prefix=${this_prefix} --opt clean_build=yes
# sherpa wont work with fj 3.4.2 and lower version of fj wont work with new root (cxx17)
# separator "sherpa" 
# install_package sherpa/2.2.15 		True 			 ${opts} --workdir=${this_workdir} --prefix=${this_prefix} --opt version=2.2.15 
# 
# this also seems not to work
# install_package ${selection} sherpa/2.2.15 		True 			${opts} --workdir=${this_workdir} --prefix=${this_prefix} --opt version=2.2.15 cxx17=true
# but a sequential installation works
# yasp -mi sherpa/2.2.15 --opt version=2.2.15 cxx14=true
# yasp -mi sherpa/2.2.15 --opt version=2.2.15 cxx17=true
# the 14 is working with fastjet...
# then the 17 is working with root

if [[ ! -z "{{clean}}" ]]; then
	echo_info "just clean up - no super module creation"
else
	module_name=$(basename $(dirname ${this_prefix}))/$(basename ${this_prefix})
	note "making a super module: ${module_name}"
	yasp --mm ${module_name} 
fi
[ "0x$?" != "0x0" ] && exit_with_error $?
exit 0
