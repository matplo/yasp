#!/bin/bash

echo "This will just symlink yasp to {{prefix}}/bin directory"

mkdir -pv {{prefix}}/bin
rm {{prefix}}/bin/yasp
ln -sv {{yasp}} {{prefix}}/bin/yasp 
