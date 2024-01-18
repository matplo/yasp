#!/bin/bash

cd {{workdir}}
version=default
url=https://herwig.hepforge.org/downloads/herwig-bootstrap
local_file={{workdir}}/herwig-bootstrap
{{yasp}} --download {{url}} --output {{local_file}}
# chmod +x {{local_file}}
# {{local_file}} \\ 
#     --with-fastjet3={{fastjet_prefix}} \\
#     --with-lhapdf6={{lhapdf_prefix}} \\
#     --with-thepeg={{thepeg_prefix}} \\
#     --with-hepmc2={{hepmc_prefix}} \\
#     --with-gsl={{gsl_prefix}} \\
#     --with-boost={{boost_prefix}} \\
#     --prefix={{prefix}}
cd {{builddir}}
cp -v {{local_file}} .
chmod +x ./herwig-bootstrap
# {{builddir}}/herwig-bootstrap {{prefix}} -j {{n_cores}} 
./herwig-bootstrap --help
# for module file - setup alias
# source ${HERWIGPATH}/bin/activate
# source ${HERWIGPATH}/bin/deactivate

# module load fastjet/3.4.0 HepMC2/2.06.11 LHAPDF6/6.5.3 pythia8/8308

# python -m pip install cython

mkdir -p {{prefix}}

# opts="--with-fastjet=${FASTJET_DIR} --with-fastjet_contrib=${FASTJET_DIR} --with-lhapdf=${LHAPDF6_DIR} --with-hepmc=${HEPMC3_DIR} --with-pythia=${PYTHIA8_DIR}"
#note: we do not do make fragile install for fastjet_contrib and herwig expects that
opts="--with-fastjet=${FASTJET_DIR} --with-lhapdf=${LHAPDF6_DIR} --with-hepmc=${HEPMC3_DIR} --with-pythia=${PYTHIA8_DIR}"
echo "options: ${opts}"

./herwig-bootstrap -j {{n_cores}} ${opts} {{prefix}} 
