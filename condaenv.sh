#!/bin/bash

savedir=${PWD}

function thisdir()
{
	SOURCE="${BASH_SOURCE[0]}"
	while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
	  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
	  SOURCE="$(readlink "$SOURCE")"
	  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
	done
	DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
	echo ${DIR}
}
THISD=$(thisdir)

cd ${THISD}

export YASP_DIR=${THISD}
source ${THISD}/src/util/bash/util.sh
separator "This is yasp conda env at ${YASP_DIR}"

# check if conda is available
if ! command -v conda &> /dev/null; then
    # try module load conda
    if command -v module &> /dev/null; then
        echo_info "Trying to load conda module..."
        module load conda &> /dev/null
        if command -v conda &> /dev/null; then
            echo_info "Conda module loaded successfully."
        else
            echo_error "Failed to load conda module. Please ensure conda is installed and available in PATH."
            exit 1
        fi
    else
        echo_error "conda is not available in PATH. Please install conda first."
        exit 1
    fi
fi

# Function to check if a Python version is available in conda
function check_conda_python_version() 
{
    local python_version=$1

		# get the major version of Python from ${python_selected}
		python_version_major=$(echo "${python_version}" | cut -d'.' -f1)
		python_version_minor=$(echo "${python_version}" | cut -d'.' -f2)
		python_version_subminor=$(echo "${python_version}" | cut -d'.' -f3)

		# Construct the version string for conda
		# e.g., if python_version is "3.11", we want to check for "3.11"
		# If python_version is "3.11.13", we still want to check for "3.11"

		python_version_only=${python_version_major}.${python_version_minor}

    if [[ -z "$python_version" ]]; then
        error_error "No Python version specified"
        return 1
    fi
    
    # Check if conda is available
    if ! command -v conda &> /dev/null; then
        error_error "conda is not available in PATH"
        return 1
    fi
    
    echo_info "Checking if Python ${python_version} is available in conda..."
    
    # Try a dry-run of conda environment creation
		# Remove any existing temporary environment to avoid conflicts
		conda env remove --prefix ./temp-check-env &>/dev/null || true
		# Create a temporary environment to check the Python version
		# The --dry-run option simulates the creation without actually doing it
    if conda create --prefix ./temp-check-env python=${python_version_only} --dry-run --quiet &>/dev/null; then
        echo_info "✓ Python ${python_version_only} is available in conda"
        return 0
    else
        echo_error "✗ Python ${python_version_only} is not available in conda"
        echo_info "Available Python versions:"
        # conda search python | grep "^python " | awk '{print $2}' | sort -V | uniq | tail -10
				conda search "python=${python_version_major}.${python_version_minor}" | grep "^python " | awk '{print $2}' | sort -V | uniq | tail -10
        return 1
    fi
}
export -f check_conda_python_version

# Default Python version to use if not specified
cmnd="$@"
python_selected="3.11"
conda_env_name="conda_env_yasp"
conda_env_prefix="${YASP_DIR}/${conda_env_name}_python_${python_selected}"
# check if --python <version> is given at the command line
# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --name)
            if [[ -n "$2" ]] && [[ "$2" != --* ]]; then
                conda_env_name="$2"
                conda_env_prefix="${YASP_DIR}/${conda_env_name}_python_${python_selected}"
                echo_info "Conda environment name set to ${conda_env_name} with prefix ${conda_env_prefix}"
                shift 2 # remove the --name and version from the arguments
            else
                echo_error "No environment name specified after --name."
                exit 1
            fi
            ;;
        --python)
            if [[ -n "$2" ]] && [[ "$2" != --* ]]; then
                # check if the conda_env_prefix already exists
                if [[ -d "${conda_env_prefix}" ]]; then
                    echo_warning "Conda environment prefix ${conda_env_prefix} already exists - not checking if available on conda"
                else
                    # Check if the Python version is available in conda
                    if check_conda_python_version "$2"; then
                        python_selected="$2"
                        echo_info "Python version $2 verified and will be used for conda environment"
                    else
                        echo_error "Python version $2 not available in conda. Please specify a different version."
                        exit 1
                    fi
                fi
                shift 2 # remove the --python and version from the arguments
            else
                echo_error "No Python version specified after --python."
                exit 1
            fi
            ;;
        --first-run)
            first_run="yes"
            echo_info "First run flag set. Will perform initial setup."
            shift 1 # remove the --first-run from the arguments
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --python VERSION    Specify Python version (e.g., 3.11)"
            echo "  --name NAME         Specify conda environment name modifier (default: conda_env_yasp)"
            echo "  --first-run         Force initial setup (install dependencies, clone yasp repo)"
            echo "  --help, -h          Show this help message"
            exit 0
            ;;
        *)
            cmnd="$@"
            break
            ;;
    esac
done

cmnd="$@"

echo_info "Python selected: ${python_selected}"

create_env_cmd=""

already_in_conda_env=""
# exit if we are already within a conda environment
if [[ -n "${CONDA_PREFIX}" ]]; then
    echo_warning "You are already in a conda environment: ${CONDA_PREFIX}"
    # echo_error "Please deactivate it first before running this script."
    # exit 1
    # if $@ is zero then exit
    if [[ $# -eq 0 ]]; then
        echo_error "No command provided. Exiting..."
        exit -1
    fi
    echo_info "assuming you just want execute a command..."
    already_in_conda_env="yes"
fi

if [[ -z "${already_in_conda_env}" ]]; then
    create_env_cmd="conda create --prefix ${conda_env_prefix} python=${python_selected} -y"
    # Check if the conda environment exists by checking the directory path
    if [[ -d "$conda_env_prefix" ]] && conda env list | grep -q "$conda_env_prefix"; then
        echo_info "✓ conda environment at ${conda_env_prefix} exists"
    else
        echo_warning "✗ conda environment ${conda_env_prefix} does not exist"
        echo_info "Creating conda environment with command: ${create_env_cmd}..."
        if ! ${create_env_cmd}; then
            echo_error "Failed to create conda environment. Please check the error messages above."
            exit 1
        else
            echo_info "Conda environment ${conda_env_prefix} created successfully."
            first_run="yes"
        fi
    fi
fi

# now do some magic
tmpfile=$(mktemp)
echo_info "Temporary file created at ${tmpfile}"
echo "export PS1=\"\e[32;1m[\u\e[31;1m@\h\e[32;1m]\e[34;1m\w\e[0m\n> \"" > ${tmpfile}
if [ -e "$HOME/.bashrc" ]; then
    echo "source $HOME/.bashrc" >> ${tmpfile}
fi
if [ -e "$HOME/.bash_profile" ]; then
    echo "source $HOME/.bash_profile" >> ${tmpfile}
fi

echo "conda activate ${conda_env_prefix}" >> ${tmpfile}
echo "[[ $? -ne 0 ]] && echo_error \"Failed to activate conda environment ${conda_env_prefix}. Please check if the environment exists and is valid.\" exit $?" >> ${tmpfile}

if [[ -n "${first_run}" ]]; then
    echo_warning "This is the first run of the conda environment setup..."
    echo "separator \"this is first run...\"" >> ${tmpfile}
    echo "conda install -y numpy pyyaml tqdm find-libpython" >> ${tmpfile}
    echo "${YASP_DIR}/src/yasp.py -i yasp -m" >> ${tmpfile}
    # echo "cd ${conda_env_prefix}" >> ${tmpfile}
    # Clone the yasp repository and install it in - no this should not be done
    # echo "git clone git@github.com:matplo/yasp.git" >> ${tmpfile}
    # echo "cd -" >> ${tmpfile}
    # echo "${conda_env_prefix}/yasp/src/yasp.py -i yasp -m" >> ${tmpfile}
    # since we are cloning the yasp repo within conda env lets make sure we take the recipes from this one - no - don't do this its confusing...
    # echo "module use ${conda_env_prefix}/yasp/software/modules" >> ${tmpfile}
    # echo "module load yasp" >> ${tmpfile}
    # echo "yasp --recipe-dir ${YASP_DIR}/recipes" >> ${tmpfile}
    echo "separator \"done with first run\"" >> ${tmpfile}
    # echo "cd -" >> ${tmpfile}
else
    echo_info "This is not the first run of the conda environment setup."
fi

venv_startup_file="${conda_env_prefix}/.venvstartup.sh"
if [ ! -e "${venv_startup_file}" ]; then
    echo_info "Creating ${venv_startup_file} file"
    # internal_yasp_dir=${conda_env_prefix}/yasp/software/modules
    internal_yasp_dir=${YASP_DIR}/software/modules
    echo "module use ${internal_yasp_dir}" > ${venv_startup_file}
    echo "module load yasp" >> ${venv_startup_file}
    echo "source ${YASP_DIR}/src/util/bash/util.sh" >> ${venv_startup_file}
    echo "source ${YASP_DIR}/src/util/bash/bash_completion.sh" >> ${venv_startup_file}
    echo "alias conda_env_cd=\"cd ${conda_env_prefix}\"" >> ${venv_startup_file}
    separator "conda:${conda_env_prefix}"
fi

echo "source ${venv_startup_file}" >> ${tmpfile}
echo "cd ${savedir}" >> ${tmpfile}

if [ -z "${cmnd}" ]; then
    /bin/bash --init-file ${tmpfile} -i
else
    echo_info "Executing command: ${cmnd}"
    echo_warning "Calling cmnd file ${tmpfile}" >&2
    echo "${cmnd}" >> ${tmpfile}
    chmod +x ${tmpfile}
    ${tmpfile}
fi

separator "conda:${conda_env_prefix} done."
exit 0

# Check if the conda environment was activated successfully
if [[ $? -ne 0 ]]; then
    echo_error "Failed to activate conda environment ${conda_env_prefix}. Please check if the environment exists and is valid."
    exit 1
fi
echo_info "Conda environment ${conda_env_prefix} activated successfully."
echo_info "python is $(which python)"
echo_info "python is $(python --version)"

cd ${savedir}
