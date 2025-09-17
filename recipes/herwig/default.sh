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

# Ensure that the required python modules are installed
python -m pip install cython six

chmod +x ./herwig-bootstrap
# {{builddir}}/herwig-bootstrap {{prefix}} -j {{n_cores}}
./herwig-bootstrap --help
# for module file - setup alias
# source ${HERWIGPATH}/bin/activate
# source ${HERWIGPATH}/bin/deactivate

# module load fastjet/3.4.0 HepMC2/2.06.11 LHAPDF6/6.5.3 pythia8/8308

# python -m pip install cython

mkdir -p {{prefix}}

opts=""

# Check for existing yasp builds to skip in the rivet build
if [ -d "${BOOST_DIR}" ]; then
    opts="${opts} --with-boost=${BOOST_DIR}"
fi

if [ -d "${FASTJET_DIR}" ]; then
    opts="${opts} --with-fastjet=${FASTJET_DIR}"

    # Herwig expects fragile libraries, explicitly check
    if [ -f "${FASTJET_DIR}/lib/libfastjetcontribfragile.so" ]; then
        opts="${opts} --with-fastjet_contrib=${FASTJET_DIR}"
    fi
fi

# Note: HepMC2 is not supported
if [ -d "${HEPMC3_DIR}" ]; then
    opts="${opts} --with-hepmc=${HEPMC3_DIR}"
fi

if [ -d "${LHAPDF6_DIR}" ]; then
    opts="${opts} --with-lhapdf=${LHAPDF6_DIR}"

    # Make sure that required PDFs are installed
    lhapdf install CT14lo CT14nlo
fi

if [ -d "${PYTHIA8_DIR}" ]; then
    opts="${opts} --with-pythia=${PYTHIA8_DIR}"
fi

if [ -d "${RIVET_DIR}" ]; then
    opts="${opts} --with-rivet=${RIVET_DIR}"

    # YODA is also built as part of rivet -- check and use if possible
    if [ -f "${RIVET_DIR}/lib/libYODA.so" ]; then
        opts="${opts} --with-yoda=${RIVET_DIR}"
    fi
fi

if [ -d "${EVTGEN_DIR}" ]; then
    opts="${opts} --with-evtgen=${EVTGEN_DIR}"
fi

# Herwig is built with GoSam, which defaults to a nonstandard version number: "2.1.1-4b98559"
# In order for the build to work properly, you need to use an older verison of setuptools,
python -m pip install setuptools==65.7.0
# or, you can use a newer version of GoSam (currently not working because of default params in bootstrap)
#opts="${opts} --gosam-version=2.1.2+c307997"
# For latest version you can see https://github.com/gudrunhe/gosam/releases

echo ""
echo "options:${opts}"
echo ""

./herwig-bootstrap -j {{n_cores}} ${opts} {{prefix}}

# Older versions of setuptools have security vulnerability for command injection, so restore updates:
python -m pip install --upgrade setuptools
