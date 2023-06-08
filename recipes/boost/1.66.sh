#!/bin/bash

#!/bin/bash

cd {{workdir}}
version=1_66_0
url="https://boostorg.jfrog.io/artifactory/main/release/1.66.0/source/boost_{{version}}.tar.gz"
local_file={{workdir}}/boost_{{version}}.tar.gz
{{yasp}} --download {{url}} --output {{local_file}}
tar zxvf {{local_file}}
srcdir={{workdir}}/boost-{{version}}



exit $?
