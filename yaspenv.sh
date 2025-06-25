#!/bin/bash

interactive=
while getopts "i" opt; do
  	case $opt in
		i)
			interactive="yes"
			;;
		\?)
			echo "Invalid option: -$OPTARG" >&2
			exit 1
			;;
	esac
done
shift $(( OPTIND-1 ))

savedir=${PWD}

function thisdir()
{
	SOURCE="${BASH_SOURCE[0]}"
	while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
	  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
	  SOURCE="$(readlink "$SOURCE")"
	  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
	done
	DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
	echo ${DIR}
}
THISD=$(thisdir)

cd ${THISD}


# echo "[current dir:] ${THISD}"

venvdir=${THISD}/venvyasp
cmnd=$@

first_run=""
if [ ! -d ${venvdir} ]; then
	echo "[i] creating venv"
	python_exec=$(which python3)
	current_python_version=$(python3 -c "import sys; print('.'.join([str(s) for s in sys.version_info[:3]]));")
	current_python_version_major=$(python3 -c "import sys; print('.'.join([str(s) for s in sys.version_info[:2]]));")
	if [ ${current_python_version_major} != "3.11" ]; then
		echo "[w] python version ${current_python_version} is not 3.11 - trying to see if you have 3.11"
		python_exec=$(which python3.11)
		if [ "x${python_exec}" == "x" ]; then
			python_exec=$(which python3)
			echo "[w] python3.11 not found - trying to continue with ${python_exec}"
		else
			echo "[i] found python3.11 at ${python_exec} - continuing with this one."
		fi
	fi

	venv_cmnd=""
	${python_exec} -m virtualenv -h 2>&1 >> /dev/null
	if [ "x$?" != "x0" ]; then
		echo "[w] no virtualenv - trying venv"
		${python_exec} -m venv -h 2>&1 >> /dev/null
		if [ "x$?" != "x0" ]; then
			echo "[w] ${python_exec} -m venv -h returned $?"
		else
			venv_cmnd="venv"
		fi
	else
		venv_cmnd="virtualenv"
	fi

	if [ -z "${venv_cmnd}" ]; then
		echo "[e] do not know how to setup virtual environment... bailing out."
		exit -1
	fi

	${python_exec} -m ${venv_cmnd} ${venvdir}
	first_run="yes"
fi

tmpfile=$(mktemp)
if [ -d ${venvdir} ]; then
	echo "export PS1=\"\e[32;1m[\u\e[31;1m@\h\e[32;1m]\e[34;1m\w\e[0m\n> \"" > ${tmpfile}
	if [ -e "$HOME/.bashrc" ]; then
		echo "source $HOME/.bashrc" >> ${tmpfile}
	fi
	if [ -e "$HOME/.bash_profile" ]; then
		echo "source $HOME/.bash_profile" >> ${tmpfile}
	fi
	echo "source ${venvdir}/bin/activate" >> ${tmpfile}
	if [ "x${first_run}" == "xyes" ]; then
		echo "[i] first run? ${first_run}"
		echo "python -m pip install --upgrade pip" >> ${tmpfile}
		echo "python -m pip install pyyaml find_libpython tqdm" >> ${tmpfile}
		echo "${THISD}/src/yasp.py -i yasp -m" >> ${tmpfile}
	fi
	if [ ! -e "${THISD}/.venvstartup.sh" ]; then
		echo "module use ${THISD}/software/modules" > ${THISD}/.venvstartup.sh
		# echo "module avail" >> ${THISD}/.venvstartup.sh
		echo "module load yasp" >> ${THISD}/.venvstartup.sh
		echo "module list" >> ${THISD}/.venvstartup.sh
		echo "source ${THISD}/src/util/bash/util.sh" >> ${THISD}/.venvstartup.sh
		echo "source ${THISD}/src/util/bash/bash_completion.sh" >> ${THISD}/.venvstartup.sh
		# echo "export CLING_STANDARD_PCH=${THISD}/.pch" >> ${THISD}/.venvstartup.sh
		# echo "mkdir -pv CLING_STANDARD_PCH" >> ${THISD}/.venvstartup.sh
	fi
	echo "source ${THISD}/.venvstartup.sh" >> ${tmpfile}
	echo "cd ${savedir}" >> ${tmpfile}
	if [ -z "${cmnd}" ]; then
		/bin/bash --init-file ${tmpfile} -i
	else
		echo "[i] exec ${tmpfile}" >&2
		echo "${cmnd}" >> ${tmpfile}
		chmod +x ${tmpfile}
		if [ -n "$interactive" ]; then
			/bin/bash --init-file ${tmpfile} -i
		else
			${tmpfile}
		fi
	fi
	ecode=$?
	#-s < .activate
fi

#_venv=$(pipenv --venv)
#echo ${_venv}
#if [ -d "${_venv}" ]; then
#	if [ -z "$@" ]; then
#		pipenv shell
#	else
#		pipenv run $@
#	fi
#else
#	current_python_version=$(python3 -c "import sys; print('.'.join([str(s) for s in sys.version_info[:3]]));")
#	pipenv --python ${current_python_version}
#	pipenv install pyyaml
#	pipenv run ./yasp.py --configure $@
#	pipenv run ./yasp.py --install yasp -m
#	pipenv shell
#fi

cd ${savedir}
exit $ecode
