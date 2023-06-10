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

# deal with yasprepl.py
mkdir -pv {{python_dest_path}}/yasp/yasprepl
ln -sv {{yasp.yasp_src_dir}}/yasprepl.py {{python_dest_path}}/yasp/yasprepl/__init__.py

# deal with yasprepl.py
mkdir -pv {{python_dest_path}}/yasp/util
touch {{python_dest_path}}/yasp/util/__init__.py
ln -sv {{yasp.yasp_src_dir}}/util/cppyyhelper.py {{python_dest_path}}/yasp/util/
