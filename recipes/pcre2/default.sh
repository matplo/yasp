#!/bin/bash

cd {{workdir}}

version=10.42
url=https://github.com/PCRE2Project/pcre2/releases/download/pcre2-10.42/pcre2-{{version}}.tar.gz

local_file={{workdir}}/pcre2-{{version}}.tar.gz
{{yasp}} --download {{url}} --output {{local_file}}
tar zxvf {{local_file}}
srcdir={{workdir}}/pcre2-{{version}}

cd {{srcdir}}
echo {{srcdir}}
# {{srcdir}}/configure --help
{{srcdir}}/configure --prefix={{prefix}} && make -j {{n_cores}} && make install
exit $?
