#!/bin/bash

echo "This will just symlink yasp to {{prefix}}/bin directory"

rm -rf {{prefix}}/bin
mkdir -pv {{prefix}}/bin
rm {{prefix}}/bin/yasp
ln -sv {{yasp}} {{prefix}}/bin/yasp 

rm -rf {{prefix}}/lib
mkdir -pv {{prefix}}/lib
touch {{prefix}}/lib/__init__.py
ln -sv {{yasp}} {{prefix}}/lib
