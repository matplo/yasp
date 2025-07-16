#!/bin/bash

# make sure we are inside the virtual environment
if [ -z "$VIRTUAL_ENV" ]; then
		echo "[e] Please activate your virtual environment first."
		exit 1
fi

python -m pip install --upgrade pip

# if requirements.txt does not exist, exit with an error
if [ ! -f requirements.txt ]; then
	echo "[e] requirements.txt not found - making something up..."
	echo "[i] Creating a dummy requirements.txt file."
	ml_pack="jupyter ipykernel numpy pandas scikit-learn matplotlib seaborn tensorflow torch torchvision torchtext torchdata torchmetrics scipy scikit-image statsmodels xgboost lightgbm catboost mlflow pytorch-lightning optuna hyperopt ray dask pydantic fastapi streamlit gradio"
	jupyter_pack="jupyterlab ipykernel numpy pandas seaborn"
	for pack in ${jupyter_pack}; do
		echo "$pack" >> requirements.txt
	done
	echo "[i] Dummy requirements.txt created. Proceeding with installation."
	python -m pip install -r requirements.txt
else
	echo "[i] requirements.txt found. Proceeding with installation."
	python -m pip install -r requirements.txt
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

echo "IPython kernel installed successfully for ${kernel_name}"

# jupyter kernelspec list