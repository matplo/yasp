#!/bin/bash

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

_venv=$(pipenv --venv)
echo ${_venv}
if [ -d "${_venv}" ]; then
	if [ -z "$@" ]; then
		pipenv shell
	else
		pipenv run $@
	fi
else
	current_python_version=$(python3 -c "import sys; print('.'.join([str(s) for s in sys.version_info[:3]]));")
	pipenv --python ${current_python_version}
	pipenv install pyyaml 
	pipenv run ./yasp.py --configure $@
	pipenv run ./yasp.py --install yasp -m
	pipenv shell
fi

cd ${savedir}