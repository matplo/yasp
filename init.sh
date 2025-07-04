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

# check if pip tqdm pyyaml are installed
if ! python3 -c "import tqdm, yaml, find_libpython" &> /dev/null; then
		echo "Installing required Python packages..."
		python -m pip install --upgrade pip
		python -m pip install tqdm pyyaml find_libpython
		if [ $? -ne 0 ]; then
			echo "[e] Failed to install required Python packages. Please install them manually."
			exit 1
		fi
else
		echo "[i] Required Python packages are already installed."
fi

# check if yasp is installed
if ! ${THISD}/software/yasp/current/bin/yasp &> /dev/null; then
		echo "[i] yasp not found, installing..."
		${THISD}/src/yasp.py -i yasp -m
		if [ $? -ne 0 ]; then
			echo "[e] Failed to install yasp. Please install it manually."
			exit 1
		fi
else
		echo "[i] yasp is already installed at ${THISD}/software/yasp/current/bin/yasp"
fi

module use ${THISD}/software/modules
module load yasp
source ${THISD}/src/util/bash/util.sh
source ${THISD}/src/util/bash/bash_completion.sh

echo "[i] yasp environment initialized. You can now run yasp commands."
cd ${savedir}
