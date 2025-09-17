#!/usr/bin/env python3

import os, stat
import argparse
import sys
import shlex
import subprocess
import re
import shutil
import fnmatch
import yaml
import tempfile
import tqdm
import threading
import multiprocessing
import copy
import json

debug = False
class GenericObject(object):
	max_chars = 1000

	def __init__(self, **kwargs):
		for key, value in kwargs.items():
			self.__setattr__(key, value)
		if self.init_ignore_none is None:
			self.init_ignore_none = True
		if self.args:
			self.configure_from_dict(self.args.__dict__, self.init_ignore_none)
		if self.init_dict:
			self.configure_from_dict(self.init_dict, self.init_ignore_none)
		if self.init_json:
			self.configure_from_json(self.init_json, self.init_ignore_none)
		if self.init_yaml:
			self.configure_from_yaml(self.init_yaml, self.init_ignore_none)

	def configure_from_args(self, **kwargs):
		for key, value in kwargs.items():
			if self.ignore_none and value is None:
				continue
			self.__setattr__(key, value)

	def configure_from_dict(self, d, ignore_none=None):
		if ignore_none is None:
			ignore_none = self.init_ignore_none
		for k in d:
			if ignore_none and d[k] is None:
				continue
			self.__setattr__(k, d[k])

	def configure_from_json(self, js, ignore_none=None):
		if ignore_none is None:
			ignore_none = self.init_ignore_none
		d = json.loads(js)
		for k in d:
			if ignore_none and d[k] is None:
				continue
			self.__setattr__(k, d[k])

	def configure_from_yaml(self, yml, ignore_none=None):
		if ignore_none is None:
			ignore_none = self.init_ignore_none
		d = None
		if type(yml) is str:
			yml = yml.encode("utf-8")
			if os.path.exists(yml):
				with open(yml, 'r') as _f:
					yml = _f.read()
		try:
			d = yaml.safe_load(yml)
		except yaml.YAMLError as e:
			print(f'[e] yaml error: {e}')
		except yaml.constructor.ConstructorError as e:
			print(f'[e] yaml constructor error: {e}')
		if not isinstance(d, dict):
			raise ValueError(f"Invalid YAML input - got {type(d)} but expected a list.", d)
			return
		for k in d:
			if ignore_none and d[k] is None:
				continue
			self.__setattr__(k, d[k])

	def __getattr__(self, key):
		try:
			return self.__dict__[key]
		except KeyError:
			pass
		self.__setattr__(key, None)
		return self.__getattr__(key)

	def __str__(self) -> str:
		s = []
		s.append('[i] {} ({})'.format(str(self.__class__).split('.')[1].split('\'')[0], id(self)))
		for a in self.__dict__:
			if a[0] == '_':
				continue
			sval = str(getattr(self, a))
			if len(sval) > self.max_chars:
				sval = sval[:self.max_chars - 4] + '...'
			s.append('   {} = {}'.format(str(a), sval))
		return '\n'.join(s)

	def __repr__(self) -> str:
		return self.__str__()

	def __getitem__(self, key):
		return self.__getattr__(key)

	def __iter__(self):
		_props = [a for a in self.__dict__ if a[0] != '_']
		return iter(_props)


class ConfigData(GenericObject):
	def __init__(self, **kwargs):
		super(ConfigData, self).__init__(**kwargs)
		if self.args:
			self.configure_from_dict(self.args.__dict__)
		self.verbose = self.debug


class YaspSingletonData(GenericObject):
	_instance = None
	def __new__(cls):
		if cls._instance is None:
			global debug
			if debug:
				print('[yasp-i] Creating YaspSingletonData singleton.', file=sys.stderr)
			cls._instance = super(YaspSingletonData, cls).__new__(cls)
			cls._instance.cppyy_paths = []
		return cls._instance

	def cppyy_add_paths(self, spath):
		if self.cppyy_paths is None:
			self.cppyy_paths = []
		if os.path.exists(spath):
			if spath not in self.cppyy_paths:
				self.cppyy_paths.append(spath)
		else:
			if self.verbose or debug:
				print(f'[w] unable to add {spath} to cppyy include path')


def in_jupyter_notebook():
    try:
        from IPython import get_ipython
        shell = get_ipython().__class__.__name__
        if shell == 'ZMQInteractiveShell':
            return True   # Jupyter notebook or qtconsole
        elif shell == 'TerminalInteractiveShell':
            return False  # Terminal running IPython
        else:
            return False  # Other type (?)
    except Exception:
        return False      # Probably standard Python interpreter
      
      
def get_this_directory():
	_this_file = os.path.dirname(os.path.realpath(os.path.abspath(__file__)))
	return _this_file


def find_files(rootdir='.', pattern='*'):
	return [os.path.join(rootdir, filename)
			for rootdir, dirnames, filenames in os.walk(rootdir)
			for filename in filenames
			if fnmatch.fnmatch(filename, pattern)]


def find_dirs(rootdir='.', pattern='*'):
		return [os.path.join(rootdir, dirname)
						for rootdir, dirnames, _ in os.walk(rootdir)
						for dirname in dirnames
						if fnmatch.fnmatch(dirname, pattern)]


# return dictionary where a=value can be more words 23
def get_eq_val(s):
	ret_dict = {}
	if s is None:
		return ret_dict
	if len(s) < 1:
		return ret_dict
	regex = r"[\w]+="
	matches = re.findall(regex, s, re.MULTILINE)
	return matches


def is_iterable(o):
	try:
		_ = iter(o)
	except TypeError as te:
		return False
	return True

def is_subscriptable(o):
	try:
		_ = o[0]
	except TypeError as te:
		return False
	return True

def get_python_lib_dir():
		"""
		Get the Python library directory using sysconfig or distutils as a fallback.
		"""
		try:
				# Try to get the library directory using sysconfig
				import sysconfig
				lib_dir = sysconfig.get_config_var("LIBDIR")
				if lib_dir:
						return lib_dir
		except ImportError:
				pass

		try:
				# Fallback to distutils if sysconfig is not available or fails
				from distutils.sysconfig import get_config_var
				lib_dir = get_config_var("LIBDIR")
				if lib_dir:
						return lib_dir
		except ImportError:
				pass

		# Final fallback: return the directory of the Python executable
		return os.path.dirname(sys.executable)

def get_python_include_dir():
		"""
		Get the Python library directory using distutils.
		"""
		try:
				from distutils.sysconfig import get_python_inc
				return get_python_inc()
		except ImportError:
				pass

		return ""


import subprocess
import sys
import os
import tempfile

# launch shell and execute module load command specified by the user with the yaspenv command and return how the PYTHONPATH has changed
def get_command_output(command):
	# Execute the command in a shell and capture the output
	result = subprocess.run(command, shell=True, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
	stdout_string = result.stdout.strip()
	stderr_string = result.stderr.strip()
	# print('debug : command:', command)
	# print('debug : stdout:', stdout_string)
	# print('debug : stderr:', stderr_string)
	return stdout_string

def get_pythonpath_change(command_first, command_second):
	first_pythonpath = get_command_output(command_first)
	second_pythonpath = get_command_output(command_second)
	old_paths = set(first_pythonpath.split(os.pathsep))
	new_paths = set(second_pythonpath.split(os.pathsep))
	added_paths = new_paths - old_paths
	removed_paths = old_paths - new_paths
	return added_paths, removed_paths
		
#def yaspenv_PYTHONPATH(command):
def add_to_pythonpath(command, cppyy_include=False):
	global debug
	# make two tmp files:
	# one with the command and
	# one without it
	# pass it to the get_pythonpath_change function
	tmp_file_1 = tempfile.NamedTemporaryFile(delete=False).name
	tmp_file_2 = tempfile.NamedTemporaryFile(delete=False).name
	with open(tmp_file_1, 'w') as f:
		f.write('module list\necho $PYTHONPATH\n')
	# make file executable
	os.chmod(tmp_file_1, 0o755)
	with open(tmp_file_2, 'w') as f:
		f.write(f'module list\n{command} \nmodule list\necho $PYTHONPATH\n')
	os.chmod(tmp_file_2, 0o755)
	_yaspenv_sh_exec = yaspenv_sh_exec()
	if _yaspenv_sh_exec is None:
		print("[e] yaspenv.sh not found")
		return None, None
	if debug:
		print('[yasp-i] using env shell at', _yaspenv_sh_exec)
		print('[yasp-i] executing:', f'{_yaspenv_sh_exec} {tmp_file_1}')
		print('[yasp-i] executing:', f'{_yaspenv_sh_exec} {tmp_file_2}')
	added_paths, removed_paths = get_pythonpath_change(f'{_yaspenv_sh_exec} {tmp_file_1}', f'{_yaspenv_sh_exec} {tmp_file_2}')
	# manipulate sys.path to add the new paths
	for path in added_paths:
		if debug:
			print(f"[i] Adding {path} to sys.path")
		sys.path.append(path)
		if cppyy_include:
			_inc_path = os.path.join(os.path.dirname(path), 'include')
			YaspSingletonData().cppyy_add_paths(_inc_path)
	for path in removed_paths:
		if debug:
			print(f"[i] Removing {path} from sys.path")
		while path in sys.path:
			sys.path.remove(path)
	return added_paths, removed_paths

def module_load(module_name):
	_, _ = add_to_pythonpath(f'module load {module_name}')

def module_load_cppyy(module_name, from_dir=None):
	module_cmnd = f'module load {module_name}'
	if from_dir is not None:
		module_cmnd = f'module use {from_dir}; {module_cmnd}'
	_, _ = add_to_pythonpath(module_cmnd, cppyy_include=True)

def module_unload(module_name):
	_, _ = add_to_pythonpath(f'module unload {module_name}')
	
# Example usage
# command = "yaspenv.sh module load bundle/hepbase && echo $PYTHONPATH"
# added_paths, removed_paths = add_to_pythonpath('module load bundle/hepbase')
# print("Added PYTHONPATHs:", added_paths)
# print("Removed PYTHONPATHs:", removed_paths)


def shell_exec(command):
	process = subprocess.run(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
	stdout = process.stdout
	stderr = process.stderr
	return process.returncode, stdout, stderr

def exec_cmnd_thread(cmnd, verbose, shell):
	# _args = shlex.split(cmnd)
	if verbose:
		print('[yasp-i] calling', cmnd, file=sys.stderr)
	try:
		# p = subprocess.Popen(_args, shell=shell, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
		# out, err = p.communicate()
		# rc = p.returncode
		p = subprocess.run(cmnd, shell=shell, check=True, capture_output=True)
		p.check_returncode()
		if p:
			if verbose:
				print('[yasp-i] result of: ' + str(p.args) + '\n    out:\n' + str(p.stdout.decode('utf-8')) + '\n    err:\n' + str(p.stderr.decode('utf-8')) + '\n     rc: ' + str(p.returncode),  file=sys.stderr)
			return p
	except OSError as e:
		out = f'[e] failed to execute: f{_args}'
		if is_subscriptable(e):
			err = '- Error #{0} : {1}'.format(e[0], e[1])
		else:
			err = f'- Error {e}'
			rc = 255
	except subprocess.CalledProcessError as e:
		print('\n[error] result of: ' + str(e.cmd) + '\n    out:\n' + e.stdout.decode('utf-8') + '\n    err:\n' + e.stderr.decode('utf-8') + '\n     rc: ' + str(e.returncode),  file=sys.stderr)

	return None


def exec_cmnd_thread_pout(cmnd, verbose, shell, poutname):
	# _args = shlex.split(cmnd)
	pout = open(poutname, 'w')
	if verbose:
		print('[yasp-i] calling', cmnd, file=sys.stderr)
	try:
		# p = subprocess.Popen(_args, shell=shell, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
		# out, err = p.communicate()
		# rc = p.returncode
		p = subprocess.run(cmnd, shell=shell, check=True, capture_output=False, stdout=pout, stderr=pout)
		p.check_returncode()
		if p:
			if verbose:
				# print('[yasp-i] result of: ' + str(p.args) + '\n    out:\n' + str(p.stdout.decode('utf-8')) + '\n    err:\n' + str(p.stderr.decode('utf-8')) + '\n     rc: ' + str(p.returncode),  file=sys.stderr)
				print('[yasp-i] result of: ' + str(p.args) + '\n     rc: ' + str(p.returncode),  file=sys.stderr)
			return p
	except OSError as e:
		out = f'[e] failed to execute: f{cmnd}'
		if is_subscriptable(e):
			err = '- Error #{0} : {1}'.format(e[0], e[1])
		else:
			err = f'- Error {e}'
			rc = 255
	except subprocess.CalledProcessError as e:
		# print('\n[error] result of: ' + str(e.cmd) + '\n    out:\n' + e.stdout.decode('utf-8') + '\n    err:\n' + e.stderr.decode('utf-8') + '\n     rc: ' + str(e.returncode),  file=sys.stderr)
		print('\n[error] executing: ' + str(e.cmd) + '\n see: ' + poutname + '\n')
	pout.close()
	return None


class ThreadExec(GenericObject):
	def __init__(self, **kwargs):
		super(ThreadExec, self).__init__(**kwargs)
		if self.args:
			self.configure_from_dict(self.args.__dict__)
		if self.verbose:
			print(self)
		if self.n_jobs is None:
			self.n_jobs = multiprocessing.cpu_count() * 2
		print('[yasp-i] setting max number of jobs to', self.n_jobs)
		if self.fname:
			with open(self.fname) as f:
				lines = f.readlines()
				self.exec_list(lines)
		else:
			print('[yasp-i] exec file unspecified')

	def count_threads_alive(self, threads):
		_count = len([thr for thr in threads if thr.is_alive()])
		return _count

	def exec_list(self, lcommands = []):
		threads = list()
		logname_base = tempfile.mkstemp(suffix = '.yasp.tmp_log')
		os.close(logname_base[0])
		lognames = [logname_base[1] + '{}'.format(ilc) for ilc in range(len(lcommands))]
		# _ = [os.close(f[0]) for f in logs]
		print('[yasp-i] log for line N goes to {}N'.format(logname_base[1]))
		pbar_l = tqdm.tqdm(lcommands, desc='threads launched')
		pbar_c = tqdm.tqdm(lcommands, desc='threads completed')
		for ilc, lc in enumerate(lcommands):
			# x = threading.Thread(target=exec_cmnd_thread, args=(lc, self.verbose, True))
			# print(f'\n[i] log for line {ilc} goes to {lognames[ilc]}')
			x = threading.Thread(target=exec_cmnd_thread_pout, args=(lc, self.verbose, True, lognames[ilc]))
			threads.append(x)
			x.start()
			pbar_l.update(1)
			while self.count_threads_alive(threads) >= self.n_jobs:
			# while self.count_threads_alive(threads) >= multiprocessing.cpu_count() * 2:
				_ = [thr.join(0.1) for thr in threads if thr.is_alive()]
				pbar_c.n = len(lcommands) - self.count_threads_alive(threads)
				pbar_c.update(0)
				if self.count_threads_alive(threads) > 0:
					pbar_l.n = self.count_threads_alive(threads)
					pbar_l.update(0)
					_ = [thr.join(0.1) for thr in threads if thr.is_alive()]
					pbar_c.n = len(lcommands) - self.count_threads_alive(threads)
					pbar_c.update(0)
		while self.count_threads_alive(threads) > 0:
			pbar_l.n = len(lcommands)
			pbar_l.update(0)
			_ = [thr.join(0.1) for thr in threads if thr.is_alive()]
			pbar_c.n = len(lcommands) - self.count_threads_alive(threads)
			pbar_c.update(0)
		pbar_l.close()
		pbar_c.close()

def get_os_name():
	if sys.platform == "linux" or sys.platform == "linux2":
		return "linux"
	elif sys.platform == "darwin":
		return "darwin"
	elif sys.platform == "win32":
		return "win32"
	return sys.platform

def get_venv_type():
    """Check if running in conda, venv, or system Python"""
    
    # Check for conda
    if 'CONDA_DEFAULT_ENV' in os.environ:
        # print(f"🐍 Running in Conda environment: {os.environ['CONDA_DEFAULT_ENV']}")
        # print(f"   Conda prefix: {os.environ.get('CONDA_PREFIX', 'Not set')}")
        return 'conda'
    
    # Check for virtual environment (venv/virtualenv)
    if hasattr(sys, 'real_prefix') or (hasattr(sys, 'base_prefix') and sys.base_prefix != sys.prefix):
        # print(f"🐍 Running in virtual environment")
        # print(f"   Virtual env prefix: {sys.prefix}")
        # print(f"   Base Python prefix: {sys.base_prefix}")
        return 'venv'
    
    # Check if we're in a yasp environment specifically
    if 'YASP_DIR' in os.environ or any('yasp' in path.lower() for path in sys.path):
        # print(f"🚀 Running in YASP environment")
        # print(f"   Python executable: {sys.executable}")
        return 'yasp'
    
    # print(f"🐍 Running in system Python")
    # print(f"   Python executable: {sys.executable}")
    return 'system'

def yaspenv_sh_exec(yasp_dir=None):
	# get env $YASP_VENV_SH
	yaspenv_sh = os.getenv('YASP_VENV_SH')
	if yaspenv_sh:
		if os.path.exists(yaspenv_sh):
			return yaspenv_sh
		else:
			print(f'[w] YASP_VENV_SH environment variable points to {yaspenv_sh} but it does not exist.', file=sys.stderr)
			return None
	# if not set, try to find it in the YASP_DIR
	if yasp_dir is None:
		yasp_dir = os.path.abspath(os.path.join(get_this_directory(), '..'))
	yaspenv_sh = os.path.join(yasp_dir, 'yaspenv.sh')
	if get_venv_type() == 'conda':
		yaspenv_sh = os.path.join(yasp_dir, 'condaenv.sh')
	if os.path.exists(yaspenv_sh):
		return yaspenv_sh
	return None

##### START OF YASP CLASS #####
class Yasp(GenericObject):
	_break = 'stop'
	_continue = 'continue'
	_same_prefix = False
	_this_file = os.path.abspath(__file__)
	_yasp_dir = os.path.abspath(os.path.join(get_this_directory(), '..'))
	_yasp_src_dir = get_this_directory()
	_prog_name = os.path.splitext(os.path.basename(__file__))[0]
	_default_config = os.path.join(_yasp_dir, '.yasp.yaml')
	_default_recipe_dir = os.path.join(_yasp_dir, 'recipes')
	# _default_prefix = os.path.join(os.getenv('HOME'), _prog_name)
	_default_prefix = os.path.join(_yasp_dir, 'software')
	# _default_workdir = os.path.join(os.getenv('HOME'), _prog_name, '.workdir')
	_default_workdir = os.path.join(_yasp_dir, '.workdir')
	_current_dir = os.path.realpath(os.getcwd())
	_defaults = {
		f'{_prog_name}' : _this_file,
		'default_config' : _default_config,
		'current_dir' : _current_dir,
		'recipe_dirs' : [_default_recipe_dir],
		'prefix' : _default_prefix,
		'workdir' : _default_workdir,
		'download_command' : 'wget --no-check-certificate',
		'python' : os.path.abspath(os.path.realpath(sys.executable)),
		'yasp_dir' : _yasp_dir,
		'yasp_src_dir' : _yasp_src_dir,
		'python_version' : f'{sys.version_info.major}.{sys.version_info.minor}',
		'python_version_no_dot' : f'{sys.version_info.major}{sys.version_info.minor}',
		'python_site_packages_subpath' : f'python{sys.version_info.major}.{sys.version_info.minor}/site-packages',
		'python_libdir' : get_python_lib_dir(),
		'python_includedir' : get_python_include_dir(),
		'os' : get_os_name(),
		'cpu_count' : multiprocessing.cpu_count(),
		'error' : False,
		'venv_type': get_venv_type(),
		'venv_exec_sh': yaspenv_sh_exec(_yasp_dir)
	}

	def __init__(self, **kwargs):
		super(Yasp, self).__init__(**kwargs)
		self.set_defaults()
		self.configure_from_config(Yasp._default_config)
		if self.args:
			if self.args.use_config:
				self.configure_from_config(self.args.use_config)
			if type(self.args) == dict:
				self.configure_from_dict(self.args, ignore_none=True)
			else:
				self.configure_from_dict(self.args.__dict__)
		if self.add_recipe_dir:
			for recipe_dir in self.add_recipe_dir:
				recipe_dir = str(recipe_dir)
				if os.path.isdir(recipe_dir):
					if recipe_dir not in self.recipe_dirs:
						self.recipe_dirs.append(recipe_dir)
		self.verbose = self.debug
		self.get_known_recipes()
		self.base_prefix 	= self.prefix
		self.base_workdir 	= self.workdir
		if self.handle_cmnd_args() == Yasp._break:
			self.no_install = True
			return
		self.process_yasp_define()
		if self.download:
			self.exec_download()
			self.no_install = True
		if self.execute:
			self.exec_execute()
			self.no_install = True
		self.error = self.run()

	def exec_execute(self):
		if not os.path.exists(self.execute):
			print(f'[e] file with commands to execute does not exist {self.execute}', file=sys.stderr)
			self.valid = False
			return Yasp._break
		self.get_from_environment()
		self.output_script_file, self.output_script = tempfile.mkstemp(suffix = '.yasp.tmp')
		print(f'[i] output will be {self.output_script} ...', file=sys.stderr)
		self.workdir = os.path.dirname(self.output_script)
		self.build_script_contents = self.process_replacements(self.execute)
		self.build_script_contents = self.process_yasp_tags(self.build_script_contents)
		self.build_script_contents = self.process_replacements(self.execute) # yes has to do it twice
		os.close(self.output_script_file)
		self.write_output_file(self.output_script, self.build_script_contents, executable=True)
		print(f'[i] executing {self.output_script} ... - parallel: {self.parallel}', file=sys.stderr)
		if self.parallel:
			_ = ThreadExec(fname=self.output_script, verbose=self.verbose, n_jobs=self.n_jobs)
		else:
			out, err, rc = self.exec_cmnd(self.output_script, shell=True)
			if rc != 0:
				print(f'    execution {self.output_script} returned: {rc}', file=sys.stderr)
			else:
				print(f'    execution returned:', rc, file=sys.stderr)

	def set_defaults(self):
		for d in Yasp._defaults:
			if self.__getattr__(d) is None:
				self.__setattr__(d, Yasp._defaults[d])
			else:
				print(self.__getattr__(d))

	def get_known_recipes(self):
		self.known_recipes = []
		for recipe_dir in self.recipe_dirs:
			files = find_files(recipe_dir, '*.sh')
			for fn in files:
				recipe = os.path.splitext(fn.replace(recipe_dir + '/', ''))[0]
				self.known_recipes.append(recipe)

	def handle_cmnd_args(self):
		if self.list:
			self.get_known_recipes()
			for r in self.known_recipes:
				print(' ', r)
			return Yasp._break

		if self.configure:
			_out_dict = {}
			_ignore_keys = ['debug', 'list', 'cleanup', 'install', 'download', "redownload", 'yes', 'module', 'module_only', 'execute',
					'dry_run', 'configure', 'use_config', 'clean', 'output', 'args', 'known_recipes', 'used_config', 'verbose', 'query']
			for k in self.__dict__:
				if k in _ignore_keys:
					continue
				_out_dict[k] = self.__dict__[k]
			_cfg_filename = self.default_config
			if self.use_config:
				_cfg_filename = self.use_config
			with open(_cfg_filename, "w") as f:
				_ = yaml.dump(_out_dict, f)
			print("[i] config written to", _cfg_filename, file=sys.stderr)
			return Yasp._break

		return Yasp._continue

	def configure_from_config(self, _cfg_filename):
		if os.path.isfile(_cfg_filename):
			with open(_cfg_filename) as f:
				_cfg_data = yaml.load(f, Loader=yaml.FullLoader)
				if _cfg_data is None:
					_cfg_data = {}
				for k in _cfg_data:
					self.__setattr__(k, _cfg_data[k])
				self.used_config_file = _cfg_filename
				self.used_config = _cfg_data
		return Yasp._continue

	def get_from_environment(self):
		_which = {"CXX": "g++"}
		for w in _which:
			_what = _which[w]
			out, err, rc = self.exec_cmnd(f"which {_what}")
			if rc == 0:
				# print('[yasp-i] g++ is', out.decode('utf-8'))
				self.__setattr__(w, out.decode("utf-8").strip("\n"))
		if self.n_cpu is None:
			self.n_cpu = os.cpu_count()
		if self.n_cores is None:
			self.n_cores = self.n_cpu
		else:
			self.n_cpu = self.n_cores
		if self.n_jobs is None:
			self.n_jobs = self.n_cpu
		else:
			self.n_cpu = self.n_jobs
			self.n_cores = self.n_jobs

	def fix_recipe_scriptname(self):
		if self.recipe:
			for recipe_dir in self.recipe_dirs:
				recipe_dir = os.path.abspath(recipe_dir)
				# self.recipe = self.recipe.replace('-', '/')
				self.recipe = self.recipe.replace("==", "/")
				self.recipe_file = os.path.join(recipe_dir, self.recipe)
				if os.path.isdir(self.recipe_file):
					_candidates = find_files(self.recipe_file, "*.sh")
					self.recipe_file = sorted(_candidates, reverse=True)[0]
					self.recipe = os.path.splitext(self.recipe_file.replace(recipe_dir, "").lstrip("/"))[0]
				if not os.path.isfile(self.recipe_file):
					_split = os.path.splitext(self.recipe)
					if _split[1] != ".sh":
						self.recipe_file = self.recipe_file + ".sh"
				if os.path.exists(self.recipe_file):
					self.recipe_dir = recipe_dir
					break

	def user_confirm(
		self, what, default_answer, acceptable_answers=["yes", "no", "y", "n"]):
		_answer = "?"
		if self.yes:
			return "yes"
		if self.no:
			return "no"
		acceptable_answers.append(default_answer)
		while _answer.lower() not in acceptable_answers:
			_answer = (str(input(f"[q] {what} {acceptable_answers} [default={default_answer}]?")).lower().strip())
			if len(_answer) < 1:
				_answer = default_answer
		if _answer == "y":
			_answer = "yes"
		if _answer == "n":
			_answer = "no"
		return _answer

	def run(self):
		if self.no_install:
			return
		if self.install is None:
			return
		if type(self.install) is str:
			self.install = [self.install]
		for _recipe in self.install:
			self.prefix = self.base_prefix
			self.recipe = _recipe
			self.fix_recipe_scriptname()
			if self.recipe:
				self.get_from_environment()
				# handle the script
				if not os.path.isfile(self.recipe_file):
					print(
						"[e] recipe file",
						self.recipe_file,
						"does not exist or not a file",
						file=sys.stderr,
					)
					self.valid = False
					continue
				else:
					if self.verbose:
						print(
							"[i] script specified exists:",
							self.recipe_file,
							file=sys.stderr,
						)
					self.valid = True
				self.workdir = os.path.join(self.base_workdir, self.recipe)
				self.builddir = os.path.join(self.workdir, "build")
				self.output_script = os.path.join(self.workdir, "build.sh")
				if self.same_prefix is False:
					self.prefix = os.path.join(self.prefix, self.recipe)
				if self.valid:
					self.module_recipe = self.recipe_file.replace(".sh", ".module")
					self.build_script_contents = self.process_replacements(
						self.recipe_file
					)
					self.build_script_contents = self.process_yasp_tags(
						self.build_script_contents
					)
					self.build_script_contents = self.process_replacements(
						self.recipe_file
					)  # yes has to do it twice
					if os.path.isfile(self.module_recipe):
						self.module_output_fname = os.path.join(
							self.base_prefix, "modules", self.recipe.replace(".sh", "")
						)
						self.module_contents = self.process_replacements(
							self.module_recipe
						)
						self.module_contents = self.process_yasp_tags(
							self.module_contents
						)
						self.module_contents = self.process_replacements(
							self.module_recipe
						)  # yes has to do it twice
						self.module_dir = os.path.dirname(self.module_output_fname)
					if self.cleanup or self.clean:
						if self.cleanup:
							self.do_cleanup()
						if self.clean:
							self.do_clean()
						continue
					self.makedirs()
					if self.dry_run or self.query or self.show:
						if self.dry_run:
							if self.verbose:
								print(
									f"[i] this is dry run - stopping before executing {self.output_script}",
									file=sys.stderr,
								)
								print(self, file=sys.stderr)
						if self.show:
							print(
								f"[i] this is dry run - stopping before executing {self.output_script} - here it is:",
								file=sys.stderr,
							)
							for s in self.build_script_contents:
								print(s.rstrip(), file=sys.stderr)
							if self.module_contents:
								print(
									f"\n[i] this is dry run - module {self.module_output_fname} - is:",
									file=sys.stderr,
								)
								for s in self.module_contents:
									print(s.rstrip(), file=sys.stderr)
						continue

					if self.module_only:
						if self.module_output_fname:
							self.write_output_file(
								self.module_output_fname,
								self.module_contents,
								executable=False,
							)
						continue

					if os.path.isdir(self.prefix):
						if self.user_confirm(f"installation prefix already exists {self.prefix} - continue", "y") == "yes":
							if self.dry_run:
								print(f"[i] not removing since dry run is flag is set to: {self.dry_run}")
						else:
							continue

					# execute the shell build script
					self.write_output_file(
						self.output_script, self.build_script_contents, executable=True
					)
					_p = None
					_error = False
					try:
						_p = subprocess.run([self.output_script], check=True)
					except subprocess.CalledProcessError as exc:
						print(f"[e] {self.output_script} returned {exc.returncode}\n{exc}")
						_error = True
					if _p:
						print(f"[i] {self.output_script} returned {_p.returncode}")

					if not _error:
						if self.module and self.module_output_fname:
							self.write_output_file(
								self.module_output_fname,
								self.module_contents,
								executable=False,
							)
					else:
						return _error

	def rm_dir_with_confirm(self, sdir):
		if os.path.isdir(sdir):
			if self.user_confirm(f"remove {sdir}", "y") == "yes":
				if self.dry_run:
					print(
						f"[i] not removing since dry run is flag is set to: {self.dry_run}"
					)
				else:
					print(f"[w] removing {sdir}")
					shutil.rmtree(sdir)

	def do_clean(self):
		if self.module_dir:
			self.rm_dir_with_confirm(self.module_dir)
		if self.builddir:
			self.rm_dir_with_confirm(self.builddir)
		if self.srcdir:
			self.rm_dir_with_confirm(self.srcdir)
		if self.prefix:
			self.rm_dir_with_confirm(self.prefix)

	def do_cleanup(self):
		if self.workdir:
			self.rm_dir_with_confirm(self.workdir)

	def makedirs(self):
		if self.module_dir:
			os.makedirs(self.module_dir, exist_ok=True)
		os.makedirs(self.builddir, exist_ok=True)
		if os.makedirs(self.workdir, exist_ok=True):
			os.chdir(self.workdir)

	def get_file_contents(self, fname):
		_contents = []
		with open(fname, "r") as f:
			_contents = f.readlines()
		return _contents

	def get_definitions(self, _lines):
		ret_dict = {}
		s = "".join(_lines)
		if len(s) < 1:
			return ret_dict
		if len(s) < 1:
			return ret_dict
		regex = r"[\w]+="
		matches = re.finditer(regex, s, re.MULTILINE)
		for m in matches:
			_tag = m.group(0)
			for l in _lines:
				if l[: len(_tag) :] == _tag:
					ret_dict[_tag] = l[len(_tag) :].strip("\n")
		if self.definitions is None:
			self.definitions = ret_dict
		else:
			self.definitions.update(ret_dict)
		ret_dict = self.definitions
		return ret_dict

	def get_definitions_iter(self, _lines):
		ret_dict = {}
		if _lines is None:
			return ret_dict
		for l in _lines:
			_d = self.get_definitions([l])
			ret_dict.update(_d)
		return ret_dict

	def get_replacements(self, _lines):
		regex = r"{{[a-zA-Z0-9_]+}}*"
		matches = re.finditer(regex, "".join(_lines), re.MULTILINE)
		rv_matches = []
		for m in matches:
			if m.group(0) not in rv_matches:
				rv_matches.append(m.group(0).strip("\n"))
		return rv_matches

	def get_replacements_yasp_dot(self, _lines):
		regex = r"{{yasp\.[a-zA-Z0-9_]+}}*"
		matches = re.finditer(regex, "".join(_lines), re.MULTILINE)
		rv_matches = []
		for m in matches:
			if m.group(0) not in rv_matches:
				rv_matches.append(m.group(0).strip("\n"))
		return rv_matches

	def replace_in_line(self, l, _definitions, _replacements):
		replaced = False
		newl = l
		for r in _replacements:
			# print(f'-- checking for replacemend of {r} in {l}')
			_tag = r[2:][:-2]
			if r in newl:
				try:
					_repls = _definitions[_tag + "="]
				except KeyError:
					if "." in _tag:
						_tag = _tag.split(".")[1]
					_repls = str(self.__getattr__(_tag))
				if _repls is None:
					_repls = ""
				newl = newl.replace(r, _repls)
				replaced = True
		return newl, replaced

	def process_yasp_define(self):
		_defs_args = self.get_definitions_iter(self.yasp_define)
		for _k in _defs_args:
			_val = _defs_args[_k]
			k = _k.split("=")[0]
			# print(k.strip('='), '=', _val)
			if ":" in _val:
				_type = _val.split(":")[0]
				_val = _val.split(":")[1]
				if _type == "int":
					_val = int(_val)
				if _type == "float":
					_val = float(_val)
				if _type == "str":
					_val = str(_val)
			self.__setattr__(k, _val)
			print(f"{k} = [{self.__getattr__(k)}]")

	def process_replacements(self, input_file):
		_contents = self.get_file_contents(input_file)
		if self.replacements is None:
			self.replacements = []
		self.replacements.extend(self.get_replacements(_contents))
		self.replacements.extend(self.get_replacements_yasp_dot(_contents))
		_definitions = self.get_definitions(_contents)
		if self.define:
			_defs_args = self.get_definitions_iter(self.define)
			_definitions.update(_defs_args)
		if self.verbose:
			print("[i] definitions:", _definitions)
		if self.verbose:
			print("[i] number of replacements found", len(self.replacements))
			print("   ", self.replacements)
		new_contents = []
		for l in _contents:
			newl = l
			replaced = True
			while replaced:
				newl, replaced = self.replace_in_line(
					newl, _definitions, self.replacements
				)
			new_contents.append(newl)
		return new_contents

	def write_output_file(self, outfname, contents, executable=False):
		with open(outfname, "w") as f:
			f.writelines(contents)
		# if self.verbose:
		print("[i] written:", outfname, file=sys.stderr)
		if executable:
			os.chmod(outfname, stat.S_IRWXU)

	def exec_cmnd(self, cmnd, shell=False):
		if self.verbose:
			print("[i] calling", cmnd, file=sys.stderr)
		_args = shlex.split(cmnd)
		try:
			p = subprocess.Popen(
				_args, shell=shell, stdout=subprocess.PIPE, stderr=subprocess.PIPE
			)
			out, err = p.communicate()
			rc = p.returncode
		except OSError as e:
			out = f"[e] failed to execute: f{_args}"
			if is_subscriptable(e):
				err = "- Error #{0} : {1}".format(e[0], e[1])
			else:
				err = f"- Error {e}"
			rc = 255
		if self.verbose:
			print("    out:", out, file=sys.stderr)
			print("    err:", err, file=sys.stderr)
			print("     rc:", rc, file=sys.stderr)
		return out, err, rc

	def extract_shell_var(self, s):
		_var = s.split("=")[0].split()[-1]
		_shell_expr = s.split("=")[1]
		_value = _shell_expr
		return _var, _value

	def process_yasp_tags(self, slines):
		_rv = []
		for l in slines:
			# stay passive - do not replace anything
			_rv.append(l)
			if l.split(" ")[0] == "#yasp":
				if l.split(" ")[1] == "--shell-var":
					_rest = " ".join(l.split(" ")[1:]).strip("\n")
					_var, _cmnd = self.extract_shell_var(_rest)
					if self.verbose:
						print(f'[i] extracted: "{_cmnd}"', file=sys.stderr)
					out, err, rc = self.exec_cmnd(_cmnd, shell=True)
					if err or rc != 0:
						print(
							f'[e] extract {_var} using bash var "{_cmnd}" failed',
							file=sys.stderr,
						)
						print(f"    error is: {err}", file=sys.stderr)
					else:
						_val = out.decode("utf-8").strip("\n")
						_ns, _replaced = self.replace_in_line(
							[_val], [], self.replacements
						)
						if _replaced:
							_val = _ns
						self.__setattr__(_var, _val)
						_rv.append(f"# yasp var imported: {_var}={_val}")
				if l.split(" ")[1] == "--exec":
					_rest = " ".join(l.split(" ")[1:]).strip("\n")
					_var, _cmnd = self.extract_shell_var(_rest)
					if self.verbose:
						print(f'[i] extracted: "{_cmnd}"', file=sys.stderr)
					out, err, rc = self.exec_cmnd(_cmnd, shell=False)
					if err or rc != 0:
						print(
							f'[e] extract {_var} using bash var "{_cmnd}" failed',
							file=sys.stderr,
						)
						print(f"    error is: {err}", file=sys.stderr)
					else:
						_val = out.decode("utf-8").strip("\n")
						_ns, _replaced = self.replace_in_line(
							[_val], [], self.replacements
						)
						if _replaced:
							_val = _ns
						self.__setattr__(_var, _val)
						_rv.append(f"# yasp var imported: {_var}={_val}")
				if l.split(" ")[1] == "--set":
					_rest = " ".join(l.split(" ")[1:]).strip("\n")
					_var, _val = self.extract_shell_var(_rest)
					_ns, _replaced = self.replace_in_line([_val], [], self.replacements)
					if _replaced:
						_val = _ns
					if self.verbose:
						print("extracted:", _val, file=sys.stderr)
					self.__setattr__(_var, _val)
		return _rv

	def test_exec(self):
		if self.verbose:
			print("[i] checking bash syntax", self.recipe_file)
		out, err, rc = self.exec_cmnd("bash -n " + self.recipe_file)
		if rc == 0:
			return True
		if rc > 0:
			return False
		return rc

	def exec_download(self):
		os.chdir(self.workdir)
		if self.verbose:
			print("[i] current dir:", os.getcwd(), file=sys.stderr)
		if self.redownload:
			if os.path.isfile(self.output):
				os.remove(self.output)
		if os.path.isfile(self.output):
			return 0
		print(f"[i] downloading {self.download}", file=sys.stderr)
		_opt = "-O"
		if "wget" in self.download_command:
			_opt = "-O"
		if "curl" in self.download_command:
			_opt = "-o"
		out, err, rc = self.exec_cmnd(
			"{} {} {} {}".format(
				self.download_command, _opt, self.output, self.download
			)
		)
		if rc > 0 or self.verbose:
			print("[i] returning error={}".format(rc), file=sys.stderr)
			print(" download output:", out, file=sys.stderr)
			print(" download error :", err, file=sys.stderr)
		if os.path.isfile(self.output):
			print("[i] output file:", self.output, file=sys.stderr)
		return rc

	def find_files(self, fname):
		return find_files(self.prefix, fname)

	def find_dirs_files(self, fname):
		_dirs = [os.path.dirname(f) for f in find_files(self.prefix, fname)]
		dirs = []
		for d in _dirs:
			if d not in dirs:
				dirs.append(d)
		return dirs

	def module_load(module_name):
		_, _ = add_to_pythonpath(f'module load {module_name}')

	def module_unload(module_name):
		_, _ = add_to_pythonpath(f'module unload {module_name}')

###### END OF YASP CLASS ######

def yasp_feature(what, args={}):
	sb = Yasp(args=args)
	if sb.valid is False:
		return ''
	if '.' in what:
		_w = what.split('.')
		try:
			if '=' not in _w[1]:
				_w[1] = _w[1] + '='
			rv = sb.__getattr__(_w[0])[_w[1]]
		except:
			rv = None		
	else:
		try:
			rv = sb.__getattr__(what)
		except:
			rv = None
		if rv is None:
			rv = yasp_feature(f'definitions.{what}', args)
	return rv


def yasp_find_files(fname, args={}):
	sb = Yasp(args=args)
	rv = find_files(sb.prefix, fname)
	for s in rv:
		if sb.workdir in s:
			rv.remove(s)
	return rv


def yasp_find_files_dirnames(fname, args={}):
	sb = Yasp(args=args)
	files = find_files(sb.prefix, fname)
	# make unique list
	rv = [os.path.dirname(f) for f in files]
	urv = []
	for d in rv:
		if d not in urv:
			urv.append(d)
	for s in urv:
		if sb.workdir in s:
			urv.remove(s)
	return urv


def add_arguments_to_parser(parser):
	# group = parser.add_mutually_exclusive_group(required=True)
	parser.add_argument('--configure', help='set and write default configuration', default=False, action='store_true')
	parser.add_argument('--use-config', help='use particular configuration file - default=$PWD/.yasp.yaml', default=None, type=str)
	parser.add_argument(f'--{Yasp._prog_name}', help=f'point to {Yasp._prog_name}.py executable - default: this script')
	parser.add_argument('--cleanup', help='clean the main workdir (downloaded and build items)', action='store_true', default=False)
	parser.add_argument('-i', '-r', '--install', '--recipes', help='name of the recipe to process', type=str, nargs='+')
	parser.add_argument('-d', '--download', help='download file', type=str)
	parser.add_argument('--define', '--opt', help='define replacement', type=str, nargs='+', default='')
	parser.add_argument('--yasp-define', help='define yasp properties', type=str, nargs='+', default='')
	parser.add_argument('--clean', help='start from scratch', action='store_true', default=False)
	parser.add_argument('--redownload', help='redownload even if file already there', action='store_true', default=False)
	parser.add_argument('--dry-run', help='dry run - do not execute output script', action='store_true', default=False)
	parser.add_argument('--show', help='dry run - show the output script', action='store_true', default=False)
	parser.add_argument('--recipe-dir', help='dir where recipes info sit - default: {}'.format(Yasp._default_recipe_dir), type=str)
	parser.add_argument('--add-recipe-dir', help='add dir where recipes info sit', type=str, nargs='+')
	parser.add_argument('-o', '--output', help='output definition - for example for download', default='default.output', type=str)
	parser.add_argument('--prefix', help='prefix of the installation {}'.format(Yasp._default_prefix))
	parser.add_argument('--same-prefix', help='if this is true all install will go into the same prefix - default is {}/package-with-version'.format(Yasp._same_prefix), action='store_true', default=False)
	parser.add_argument('-w', '--workdir', help='set the work dir for the setup - default is {}'.format(Yasp._default_workdir), type=str)
	parser.add_argument('-g', '--debug', '--verbose', help='print some extra info', action='store_true', default=False)
	parser.add_argument('-l', '--list', help='list recipes', action='store_true', default=False)
	parser.add_argument('--download-command', help='overwrite download command - default is wget; could be curl', type=str, default=None)
	parser.add_argument('-q', '--query', help='query for a feature or files or directory for a file - join with feature <name> files <pattern> or dirs <pattern> (where file located) to match a query - "PseudoJet.hh" for example', type=str, default=None, nargs=2)
	parser.add_argument('-y', '--yes', help='answer yes to any questions - in particular, on --clean so', action='store_true', default=False)
	parser.add_argument('--no', help='answer no to any questions - in particular, on --clean so', action='store_true', default=False)
	parser.add_argument('-m', '--module', help='write module file', action='store_true', default=False)
	parser.add_argument('--module-only', help='write module file and exit', action='store_true', default=False)
	parser.add_argument('--use-python', help='specify python executable - default is current {}'.format(sys.executable), default=sys.executable)
	parser.add_argument('--make-module', '--mm', help='make a module from current set of loaded modules', type=str, default="")
	parser.add_argument('-e', '--execute', help='execute commands from a file', type=str, default='')
	parser.add_argument('-p', '--parallel', help='execute commands from a file concurently', action='store_true', default=False)


def str_to_args(s):
	parser = argparse.ArgumentParser(prog='none')
	add_arguments_to_parser(parser)
	args = parser.parse_args(s.split())
	return args


def dry_yasp_from_str(s=''):
	args = str_to_args(s + ' --dry-run')
	return Yasp(args=args)


def yasp_args(*argv):
	s = ' '.join(argv)
	parser = argparse.ArgumentParser(prog='none')
	add_arguments_to_parser(parser)
	args = parser.parse_args(s.split())
	return args


def features(what, *packages):
	features = []
	for _pack in packages:
		sargs = f'-r {_pack} --dry-run'
		sb = dry_yasp_from_str(sargs)
		if sb.error:
			return None
		try:
			rv = sb.__getattr__(what)
		except:
			rv = None
		if rv:
			features.append(rv)
	return features


def yasp_find_files_dirnames_in_packages(files, *packages):
	_dirs = []
	file_list = []
	if type(files) is str:
		file_list = [files]
	else:
		for fn in files:
			file_list.append(fn)
	for p in packages:
		if len(p) < 1:
			continue
		y = dry_yasp_from_str(f"-r {p}")
		for fn in file_list:
			print('-- looking for', fn, 'in', p)
			_ds = y.find_dirs_files(fn)
			for _d in _ds:
				if _d not in _dirs:
					_dirs.append(_d)
	return _dirs

def check_if_same_file(args):
	_args = copy.deepcopy(args)
	if _args.install:
		_args.install = None
	sb = Yasp(args=_args)
	if os.path.samefile(os.path.abspath(os.path.realpath(sys.executable)), sb.python) is False:
		print('[yasp-warn] looks like yasp called with different python than configured with...', file=sys.stderr)
		print('    this python is [', sys.executable, 	']', file=sys.stderr)
		print('    yasp python is [', sb.python, 		']', file=sys.stderr)
		if sb.user_confirm('execute with yasp python?', 'y') == 'yes':
			cmnd = '{} {}'.format(sb.python, ' '.join(sys.argv))
			print(f'[i] executing: {cmnd}')
			out, err, rc = sb.exec_cmnd(cmnd)
			print(out)
			exit(rc)
		else:
			exit(1)


def check_if_file_is_module_file(fname):
	if not os.path.isfile(fname):
		return False
	with open(fname, 'r') as f:
		for line in f:
			if '#%Module' in line:
				return True
	return False


def add_module_paths(module_name):
	# get from yasp where are the modules
	prefix = yasp_feature('prefix')
	# find all dirs endig with modules
	candidate_dirs = find_dirs(rootdir=prefix, pattern='modules')
	candidate_modules = []
	for candidate_dir in candidate_dirs:
		# find all modules in this dir
		found_files = find_files(rootdir=candidate_dir, pattern='*')
		for module in found_files:
			if '/' in module_name:
				if module.endswith(module_name) and check_if_file_is_module_file(module):
					candidate_modules.append(module)
			else:
				if os.path.dirname(module).endswith(module_name) and check_if_file_is_module_file(module):
					candidate_modules.append(module)
	print('-i- found candidate modules:', candidate_modules)
	# check which one has the latest modification date
	# and return the path to it
	latest_module = None
	latest_modification = 0
	for cm in candidate_modules:
		_m = os.path.getmtime(cm)
		if _m > latest_modification:
			latest_modification = _m
			latest_module = cm
	if latest_module is None:
		print('-w- no module found')
		return
	print('-i- latest module:', latest_module)
	# read the file and find DYLD_LIBRARY_PATH or LD_LIBRARY_PATH
	# and add it to the system path
	paths_to_add = []
	with open(latest_module, 'r') as f:
		for line in f:
			if 'DYLD_LIBRARY_PATH' in line or 'LD_LIBRARY_PATH' in line:
				path = line.split()[-1].strip()
				paths_to_add.append(path)
	# get unique paths
	paths_to_add = list(set(paths_to_add))
	for path in paths_to_add:
		if path not in sys.path:
			print('-i- adding path:', path)
			sys.path.append(path)
		else:
			print('-w- path already in sys.path:', path)
	if len(paths_to_add) == 0:
		print('-w- no paths to add')


def enable_module(module_name):
	add_module_paths(module_name)


def enable_modules(*args):
	for module_name in args:
		add_module_paths(module_name)


def main():
	parser = argparse.ArgumentParser()
	add_arguments_to_parser(parser)
	args = parser.parse_args()

	if not args.query:
		sb = Yasp(args=args)
	
	check_if_same_file(args = args)

	if args.query:
		q = args.query
		if q[0] == 'feature':
			print(yasp_feature(q[1], args), file=sys.stdout)
		if q[0] == 'files':
			_files = yasp_find_files(q[1], args)
			for fn in _files:
				print(fn, file=sys.stdout)
		if q[0] == 'dirs':
			_dirs = yasp_find_files_dirnames(q[1], args)
			for d in _dirs:
				print(d, file=sys.stdout)
		return

	if args.make_module:
		# determine what's the module command to use
		out, err, rc = sb.exec_cmnd('modulecmd python -t list')
		if rc == 0:
			mcmnd = 'modulecmd python -t'
		else:
			mcmnd = os.path.expandvars("$LMOD_CMD") + ' -t'
			_lmod_cmnd='{} list'.format(mcmnd)
			out, err, rc = sb.exec_cmnd(_lmod_cmnd)
			if rc == 0:
				print('[yasp-i] will use', mcmnd, 'as module command')
			else:
				print(f'[error] unable to use neither module command nor {mcmnd}', err)
				return 2
		modfname = os.path.join(sb.base_prefix, 'modules', args.make_module)
		print('[yasp-i] will write to:', modfname)
		print(f'[i] prefix: {sb.prefix}')
		module_use_path = os.path.join(sb.prefix, args.make_module, 'modules')
		if not os.path.isdir(module_use_path):
			module_use_path = os.path.join(sb.prefix, 'modules')
		print(f'[i] module use path to be added within the module: {module_use_path}')
		out, err, rc = sb.exec_cmnd(f'{mcmnd} list')
		if rc == 0:
			_sout = (out + err).decode('utf-8')
			if 'Currently Loaded Modulefiles:' in _sout:
				_sout = _sout.replace('Currently Loaded Modulefiles:', '')
			if 'No Modulefiles Currently Loaded.' in _sout:
				_sout = ''
			_modules_list0 = [m for m in _sout.split('\n') if len(m) > 0]
			_modules_list = [m for m in _modules_list0 if '_Module' not in m and 'export ' not in m and '=' not in m]
		else:
			print(f'[error] unable to use neither module command nor {mcmnd}', err)
			return 2
		_yasp_mods = []
		# print(sb.known_recipes)
		# for m in _modules_list:
		#	if m in sb.known_recipes:
		#		_yasp_mods.append(m)
		## print(_modules_list)
		# print('yasp modules loaded:', _yasp_mods)
		modules_to_load_full_path = []
		modules_to_load = []
		if 'modulecmd' in mcmnd:
			for m in _modules_list:
				out, err, rc = sb.exec_cmnd(f'{mcmnd} -t show {m}')
				_sout = (out + err).decode('utf-8')
				print(_sout)
				_dname = [s.split(m+':')[0] for s in _sout.split('\n') if m+':' in s][0]
				_fmodpath = [s.split(':')[0] for s in _sout.split('\n') if m+':' in s][0]
				if _fmodpath not in modules_to_load:
					if os.path.isfile(_fmodpath):
						modules_to_load_full_path.append(_fmodpath)
						modules_to_load.append(m)
				# print(m, 'from:', _dname, _fmodpath)
		else:
			modules_to_load = [m for m in _modules_list]
		if not os.path.isdir(os.path.dirname(modfname)):
			os.makedirs(os.path.dirname(modfname))
		with open(modfname, 'w') as f:
			print('#%Module', file=f)
			print(f'module use {module_use_path}', file=f)
			for m in modules_to_load:
				if 'yasp/current' == m:
					continue
				if args.make_module == m:
					continue
				print(f'module load {m}', file=f)
				print(f'module load {m}', file=sys.stderr)

	# if args.install or args.debug:
	if args.debug:
		print(sb)

	if sb.valid is False or sb.error:
		return 1
	# sb.run()


if __name__=="__main__":
	_rv = main()
	exit(_rv)
