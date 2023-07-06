#!/bin/bash

version=dev
url=https://gitlab.com/openloops/OpenLoops.git

srcdir={{builddir}}/OpenLoops
#{{workdir}}/OpenLoops
if [ -d {{srcdir}} ]; then
	cd {{srcdir}}
	git pull
else
	git clone ${url} {{srcdir}}
fi
echo "[i] source dir is {{srcdir}}"

cd {{srcdir}}
plist=all.coll
#plist=LHC.coll
rm basic_jj.coll
# https://openloops.hepforge.org/process_library.php
for proc in ppjj ppjjj ppjjjj
do
	echo ${proc} >> basic_jj.coll
done
plist=basic_jj.coll
${srcdir}/scons && ./openloops libinstall {{plist}} && ./openloops libinstall {{plist}} compile_extra=1 && ./openloops update
exit $?
