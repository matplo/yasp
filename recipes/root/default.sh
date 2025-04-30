#!/bin/bash

cd {{workdir}}
# version=6.28.12
version=6.30.06
url=https://root.cern/download/root_v{{version}}.source.tar.gz
local_file={{workdir}}/root_v{{version}}.tar.gz
{{yasp}} --download {{url}} --output {{local_file}}
srcdir={{workdir}}/root-{{version}}
#yasp --set srcsdir={{workdir}}/root-{{version}}
if [ "x{{clean}}" == "True" ]; then
	rm -rf {{srcdir}}
	tar zxvf {{local_file}}
fi
[ ! -d "{{srcdir}}" ] && tar zxvf {{local_file}}
cd {{builddir}}
# #{{srcdir}}/configure --prefix={{prefix}} && make -j {{n_cores}} && make install
# --with-python-include="$(python -c "from sysconfig import get_paths; info = get_paths(); print(info['include'])")"
# opts="-Dbuiltin_xrootd=ON -Dmathmore=ON -Dxml=ON -Dvmc=OFF -Dxrootd=OFF"
opts="-Dbuiltin_xrootd=OFF -Dxrootd=OFF -Dvmc=OFF -Dmathmore=ON -Dxml=ON -Dunfold=ON -Dbuiltin_vdt=ON"
cmake -DCMAKE_INSTALL_PREFIX={{prefix}} \
	-DCMAKE_BUILD_TYPE=Release \
	-DPython3_EXECUTABLE=$(which python3) \
	${opts} \
	{{srcdir}} && cmake --build . --target install -- -j {{n_cores}}
exit $?

# note to myself in the future:
# for cmake above 3.5, the following options are needed:
# 	-DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
# these will still not work...
# 	-Dbuiltin_davix=OFF -Ddavix=OFF \
# 	-Dbuiltin_tbb=OFF -Dtbb=OFF \
# 	-Dbuiltin_vdt=OFF -Dvdt=OFF \
# so compile with the cmake 3.31.7 made with yasp (recipe provided)
