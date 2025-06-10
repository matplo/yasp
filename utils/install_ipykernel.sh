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

python -m ipykernel install --user --name=sbox_ml_visual --display-name "sbox_ml_visual"

if [ $? -eq 0 ]; then
		echo "[i] Kernel installed successfully."
		jupyter kernelspec list
else
		echo "Failed to install kernel."
		exit 1
fi