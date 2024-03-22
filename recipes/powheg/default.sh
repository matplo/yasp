#!/bin/bash

cd {{workdir}}
version="BOX-V2"

url=svn://powhegbox.mib.infn.it/trunk/POWHEG-{{version}}
srcdir={{workdir}}/POWHEG-{{version}}

# from https://powhegbox.mib.infn.it/#V2

revision="--revision n"
revision=""
if [ ! -d {{srcdir}} ]; then
	svn checkout ${revision} --username anonymous --password anonymous ${url} {{srcdir}}
else
	cd {{srcdir}}
	svn update 
	cd {{workdir}}
fi

if [ "0x$?" != "0x0" ]; then
	echo "[e] problem with svn for ${url} - $?"
	exit 1
fi

url_process_list=svn://powhegbox.mib.infn.it/trunk/User-Processes-V2
process_list=$(svn list ${revision} --username anonymous --password anonymous ${url_process_list} | tr -d ' ')

if [ "0x$?" != "0x0" ]; then
	echo "[e] problem with svn getting process list"
	exit 1
fi

plist_all=$(echo ${process_list} | tr '\n' ' ')
plist={{proc}}
if [ "${plist}" == "all" ]; then
	plist=${plist_all}
fi

if [ "${plist}" == "None" ]; then
	echo "[w] no processes specified - listing"
	echo "[i] to compile a process use --define proc=process_name1,process_name2,..."
	echo "    or --define proc=all"
	echo "${plist_all}"
	exit 0
fi

plist=(${plist//,/ })

for p in ${plist[@]}; do
	cd {{workdir}}
	if [ "0x$?" == "0x0" ]; then
	    echo "[i] getting $p"
		if [ -d "{{srcdir}}/${p}" ]; then
			cd {{srcdir}}/${p}
			svn up ${revision} --username anonymous --password anonymous
		else
			svn co ${revision} --username anonymous --password anonymous svn://powhegbox.mib.infn.it/trunk/User-Processes-V2/${p} {{srcdir}}/${p}
		fi
		if [ "0x$?" == "0x0" ]; then
			cd {{srcdir}}/${p}
			echo "[i] building $p in $PWD"		
			cp -v Makefile Makefile.patched
			if [ "{{yasp.os}}" == "Darwin" ]; then
				sed -i '' 's/\$(DEBUG) -c/\$(DEBUG) -std=c++11 -c/g' Makefile.patched
			else
				sed -i.bak 's/\$(DEBUG) -c/\$(DEBUG) -std=c++11 -c/g' Makefile.patched
			fi
			make -f Makefile.patched pwhg_main
			mkdir -p {{prefix}}/bin
			cp -v pwhg_main {{prefix}}/bin/pwhg_${p}
			if [ "0x$?" == "0x0" ]; then
				echo "[i] $p build successful"
			else
				echo "[e] error building $p"
				exit 1
			fi
		else
			echo "[e] error getting $p"
			exit 1
		fi
	else
		echo "[e] problem with $p"
		exit 1
	fi
done

cd {{workdir}}

echo "[i] copying POWHEG-BOX-V2 to {{prefix}}"
rsync -avp {{srcdir}}/* {{prefix}}/
if [ "0x$?" != "0x0" ]; then
	echo "[e] problem with rsync"
	exit 1
fi

echo "[i] done"
