#!/bin/bash

kernel_name=$(echo $CONDA_DEFAULT_ENV | sed 's/\//-/g' | sed 's/ //g' | sed 's/--/_/g' | sed 's/-/_/g' | sed 's/^_//g' | sed 's/_$//g')
kernel_display_name=${kernel_name}

echo "Installing IPython kernel for conda environment: ${kernel_name}"

# first check if ipykernel is already installed
if python -c "import ipykernel" &> /dev/null; then
	echo "ipykernel package is already installed"
else
	echo "ipykernel package is not installed, installing now with conda"
	conda install -y conda-forge::ipykernel
	if [ $? -ne 0 ]; then
		echo "Failed to install ipykernel with conda"
		exit 1
	fi
fi	

if [ $? -ne 0 ]; then
		echo "Failed to install ipykernel"
		exit 1
fi

# find all the YASP_XYZ_DIR variables and add them to the environment
extra_envs=""

# Use process substitution instead of pipe to avoid subshell
while read -r line; do
    echo "Found environment variable: $line"
    var_name=$(echo $line | cut -d '=' -f 1)
    echo "Variable name: $var_name"
    var_value=$(echo $line | cut -d '=' -f 2-)
    echo "Variable value: $var_value"
    extra_envs="--env $var_name $var_value $extra_envs"
    echo "Extra environment variable added: $var_name $var_value -> $extra_envs"
done < <(env | grep -E '^YASP_[A-Z0-9_]+_DIR=')

echo "Extra environment variables: $extra_envs"

python -m ipykernel install --user --name ${kernel_name} --display-name "${kernel_display_name}" --env LD_LIBRARY_PATH ${LD_LIBRARY_PATH}:\${LD_LIBRARY_PATH} --env PYTHONPATH ${PYTHONPATH}:\${PYTHONPATH} --env PATH ${PATH}:\${PATH} --env CONDA_PREFIX ${CONDA_PREFIX}:\${CONDA_PREFIX} --env CONDA_DEFAULT_ENV ${CONDA_DEFAULT_ENV}:\${CONDA_DEFAULT_ENV} --env YASP_VENV_SH ${YASP_VENV_SH} --env YASP_VENV_TYPE ${YASP_VENV_TYPE} $extra_envs

if [ $? -ne 0 ]; then
		echo "Failed to install ipykernel"
		exit 1
fi

echo "IPython kernel installed successfully for conda_env_yasp_python_3.11"

