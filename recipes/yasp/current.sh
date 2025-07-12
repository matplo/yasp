#!/bin/bash

echo "This will just symlink yasp to {{prefix}}/bin directory"

rm -rf {{prefix}}/bin
mkdir -pv {{prefix}}/bin
# ln -sv {{yasp}} {{prefix}}/bin/yasp 
ln -sv {{yasp.yasp_src_dir}}/*.py {{prefix}}/bin
ln -sv {{prefix}}/bin/yasp.py {{prefix}}/bin/yasp
ln -sv {{prefix}}/bin/yasprepl.py {{prefix}}/bin/yasprepl
ln -sv {{prefix}}/bin/yaspreplstring.py {{prefix}}/bin/yaspreplstring
ln -sv {{prefix}}/bin/lre.py {{prefix}}/bin/lre
ln -sv {{prefix}}/bin/le.py {{prefix}}/bin/le

rm -rf {{prefix}}/lib
python_dest_path={{prefix}}/lib/{{python_site_packages_subpath}}

# deal with yasp.py
mkdir -pv {{python_dest_path}}/yasp
ln -sv {{yasp.yasp_src_dir}}/yasp.py {{python_dest_path}}/yasp/__init__.py

for pack in yasprepl cppyyhelper yaspreplstring
do
	mkdir -pv {{python_dest_path}}/yasp/${pack}
	ln -sv {{yasp.yasp_src_dir}}/${pack}.py {{python_dest_path}}/yasp/${pack}/__init__.py
done

echo "[i] {{python_site_packages_subpath}}"
echo "[i] {{python_dest_path}}"

{{yasp.yasp_src_dir}}/yasp.py -q feature venv_type
# if [[ -z "${VIRTUAL_ENV}" ]]; then
# 	echo "[i] Not running within a virtual environment"
# 	{{yasp.yasp_src_dir}}/yasp.py -q feature venv_type
# else
if [[ -n "${VIRTUAL_ENV}" ]] || [[ -n "${CONDA_PREFIX}" ]]; then
	[[ -n "${VIRTUAL_ENV}" ]] &&  echo "[i] Running within a virtual environment at ${VIRTUAL_ENV}"
	[[ -n "${CONDA_PREFIX}" ]] && echo "[i] Running within a conda environment at ${CONDA_PREFIX}" && VIRTUAL_ENV=${CONDA_PREFIX}
	echo "[i] Running within a virtual environment at ${VIRTUAL_ENV}"
	python_dest_path=${VIRTUAL_ENV}/lib/{{python_site_packages_subpath}}
	# deal with yasp.py
	mkdir -pv ${python_dest_path}/yasp
	ln -sfv {{yasp.yasp_src_dir}}/yasp.py ${python_dest_path}/yasp/__init__.py
	{{yasp.yasp_src_dir}}/yasp.py -q feature venv_type
	for pack in yasprepl cppyyhelper yaspreplstring
	do
		mkdir -pv ${python_dest_path}/yasp/${pack}
		ln -sfv {{yasp.yasp_src_dir}}/${pack}.py ${python_dest_path}/yasp/${pack}/__init__.py
	done
fi
