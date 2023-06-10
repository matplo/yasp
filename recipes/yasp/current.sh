#!/bin/bash

echo "This will just symlink yasp to {{prefix}}/bin directory"

rm -rf {{prefix}}/bin
mkdir -pv {{prefix}}/bin
# ln -sv {{yasp}} {{prefix}}/bin/yasp 
ln -sv {{yasp.yasp_src_dir}}/*.py {{prefix}}/bin
ln -sv {{prefix}}/bin/yasp.py {{prefix}}/bin/yasp
ln -sv {{prefix}}/bin/yasprepl.py {{prefix}}/bin/yasprepl

rm -rf {{prefix}}/lib
python_dest_path={{prefix}}/lib/{{python_site_packages_subpath}}

# deal with yasp.py
mkdir -pv {{python_dest_path}}/yasp
ln -sv {{yasp.yasp_src_dir}}/yasp.py {{python_dest_path}}/yasp/__init__.py

for pack in yasprepl cppyyhelper
do
	mkdir -pv {{python_dest_path}}/yasp/${pack}
	ln -sv {{yasp.yasp_src_dir}}/${pack}.py {{python_dest_path}}/yasp/${pack}/__init__.py
done
