#!/bin/bash

mkdir -p {{prefix}}
cd {{prefix}}
version=6.34.08
# gcc version should be swapped for different Ubuntu versions
root_bin=root_v{{version}}.Linux-ubuntu22.04-x86_64-gcc11.4.tar.gz
url=https://root.cern/download/${root_bin}

local_file={{prefix}}/${root_bin}
{{yasp}} --download {{url}} --output ${local_file}
download_code=$?
tar zxf ${local_file} --strip-components 1
extr_code=$?
rm ${local_file}

if [[ $extr_code -ne 0 || $download_code -ne 0 ]]; then exit 1; fi