#!/bin/bash

kernel_name=$(echo $CONDA_DEFAULT_ENV | sed 's/\//-/g' | sed 's/ //g' | sed 's/--/_/g' | sed 's/-/_/g' | sed 's/^_//g' | sed 's/_$//g')
kernel_display_name=${kernel_name}

echo "Installing IPython kernel for conda environment: ${kernel_name}"

conda install -y conda-forge::ipykernel
if [ $? -ne 0 ]; then
		echo "Failed to install ipykernel"
		exit 1
fi

python -m ipykernel install --user --name ${kernel_name} --display-name "${kernel_display_name}" --env LD_LIBRARY_PATH ${LD_LIBRARY_PATH}:\${LD_LIBRARY_PATH} --env PYTHONPATH ${PYTHONPATH}:\${PYTHONPATH} --env PATH ${PATH}:\${PATH} --env CONDA_PREFIX ${CONDA_PREFIX}:\${CONDA_PREFIX} --env CONDA_DEFAULT_ENV ${CONDA_DEFAULT_ENV}:\${CONDA_DEFAULT_ENV} --env YASP_VENV_SH ${YASP_VENV_SH} --env YASP_VENV_TYPE ${YASP_VENV_TYPE}

if [ $? -ne 0 ]; then
		echo "Failed to install ipykernel"
		exit 1
fi

echo "IPython kernel installed successfully for conda_env_yasp_python_3.11"

