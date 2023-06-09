#!/bin/bash

echo "This will just symlink yasp to {{prefix}}/bin directory"

rm -rf {{prefix}}/bin
mkdir -pv {{prefix}}/bin
# ln -sv {{yasp}} {{prefix}}/bin/yasp 
ln -sv {{yasp.yasp_dir}}/*.py {{prefix}}/bin
ln -sv {{prefix}}/bin/yasp.py {{prefix}}/bin/yasp
ln -sv {{prefix}}/bin/yasprepl.py {{prefix}}/bin/yasprepl

rm -rf {{prefix}}/lib
# mkdir -pv {{prefix}}/lib/yasp/util
mkdir -pv {{prefix}}/lib/yasp

# ln -sv {{yasp}} {{prefix}}/lib/yasp/
ln -sv {{yasp}} {{prefix}}/lib/yasp/__init__.py
ln -sv {{yasp.yasp_dir}}/*.py {{prefix}}/lib/yasp
# echo "import yasp" > {{prefix}}/lib/yasp/__init__.py
# touch {{prefix}}/lib/yasp/yasp/__init__.py

yasp_dir=$(dirname {{yasp}})
# touch {{prefix}}/lib/yasp/yasp/util/__init__.py
# echo "from cppyyhelper import *" > {{prefix}}/lib/yasp/util/__init__.py
# echo "from util.cppyyhelper import *" >> {{prefix}}/lib/yasp/__init__.py
# ln -sv ${yasp_dir}/util/cppyyhelper.py {{prefix}}/lib/yasp/util/

ln -sv ${yasp_dir}/util/cppyyhelper.py {{prefix}}/lib/yasp/
