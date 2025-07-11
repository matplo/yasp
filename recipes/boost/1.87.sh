#!/bin/bash

cd {{workdir}}
version=1.87.0
version_underscores=$(echo "${version}" | tr . _)
url="https://archives.boost.io/release/{{version}}/source/boost_{{version_underscores}}.tar.gz"
local_file={{workdir}}/boost_{{version}}.tar.gz
{{yasp}} --download {{url}} --output {{local_file}}
tar zxvf {{local_file}}
srcdir={{workdir}}/boost_{{version_underscores}}

# Do the bootstrapping
# b2 must be built in source directory where .jam files are located
cd {{srcdir}}
./bootstrap.sh --help
{{srcdir}}/bootstrap.sh --prefix={{prefix}}

# Build Boost using b2
./b2 --help
./b2 install headers --prefix={{prefix}} --build-dir={{builddir}}

exit $?
