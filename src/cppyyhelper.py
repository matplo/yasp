import yasp
import sys
import os
import cppyy 
import subprocess

def is_running_in_jupyter():
    try:
        from IPython import get_ipython
        _get_ipy = get_ipython()
        if _get_ipy is None:
          return False
        if 'IPKernelApp' in get_ipython().config:
            return True
    except ImportError:
        pass
    return False

def add_to_ld_library_path(path):
		if 'LD_LIBRARY_PATH' in os.environ:
				if path not in os.environ['LD_LIBRARY_PATH'].split(':'):
					os.environ['LD_LIBRARY_PATH'] = path + ':' + os.environ['LD_LIBRARY_PATH']
		else:
				os.environ['LD_LIBRARY_PATH'] = path

        
class YaspCppyyHelper(yasp.GenericObject):
	_instance = None
	def __new__(cls):
		if cls._instance is None:
			if yasp.debug:
				print('[yasp-i] Creating YaspCppyyHelper singleton.', file=sys.stderr)
			cls._instance = super(YaspCppyyHelper, cls).__new__(cls)
			cls._instance.jupyter = is_running_in_jupyter()
			if cls._instance.jupyter:
				print('[yasp-i] Running in Jupyter:', cls._instance.jupyter, file=sys.stderr)
		return cls._instance


	def reload_yasp_cppyy_paths(self):
		if yasp.debug:
			print('[yasp-i] Reloading YaspCppyyHelper paths', file=sys.stderr)
		_data = yasp.YaspSingletonData()
		if self.paths_include is None:
			self.paths_include = []
		for _path in _data.cppyy_paths:
			cppyy.add_include_path(_path)
		gSys = cppyy.gbl.gSystem
		for _path in sys.path:
			if os.path.isdir(_path):
				add_to_ld_library_path(_path)
				cppyy.add_library_path(_path)
				if gSys is not None:
					gSys.AddDynamicPath(_path)
    # make sure python lib dir is in the path
		_python_lib_dir = yasp.get_python_lib_dir()
		cppyy.add_library_path(_python_lib_dir)
		if gSys is not None:
			gSys.AddDynamicPath(_python_lib_dir)
  
	def cppyy_add_paths(self, *packages):
		if self.paths_include is None:
			self.paths_include = []
		if self.paths_lib is None:
			self.paths_lib = []
		for pfix in yasp.features('prefix', *packages):
			if pfix is None:
				continue
			_include_path = os.path.join(pfix, 'include')
			_lib_path = os.path.join(pfix, 'lib')
			_lib64_path = os.path.join(pfix, 'lib64')
			if os.path.isdir(_include_path):
				if _include_path not in self.paths_include:
					cppyy.add_include_path(_include_path)
					self.paths_include.append(_include_path)
			if os.path.isdir(_lib_path):
				if _lib_path not in self.paths_lib:
					cppyy.add_library_path(_lib_path)
					self.paths_lib.append(_lib_path)
			if os.path.isdir(_lib64_path):
				if _lib64_path not in self.paths_lib:
					cppyy.add_library_path(_lib64_path)
					self.paths_lib.append(_lib64_path)

	def find_lib_candidate_in_sys_path(self, libname):
		_lname = os.path.basename(libname)
		extensions = ['.so', '.dll', '.dylib', '.sl', '.dl', '.a']
		paths_to_search = sys.path
		for path in paths_to_search:
				for ext in extensions:
						candidate = os.path.join(path, _lname + ext)
						if os.path.isfile(candidate):
								return candidate
		_lname = 'lib' + os.path.basename(libname)
		for path in paths_to_search:
				for ext in extensions:
						candidate = os.path.join(path, _lname + ext)
						if os.path.isfile(candidate):
								return candidate
		return None

	def show_linked_libraries(self, lib_path):
			try:
					result = subprocess.run(['ldd', lib_path], capture_output=True, text=True, check=True)
					print(result.stdout)
			except subprocess.CalledProcessError as e:
					print(f"Error running ldd on {lib_path}: {e}", file=sys.stderr)

	def load_dependencies(self, slib_path):
			if yasp.debug:
				print('[yasp-i] Loading dependencies for:', slib_path)
			try:
					if os.path.isfile(slib_path) is False:
						lib_path = os.path.basename(slib_path)
						lib_path = self.find_lib_candidate_in_sys_path(lib_path)
						if lib_path is None:
								print(f"[w] ::load dependencies: Could not find library {slib_path}", file=sys.stderr)
								return
					else:
						lib_path = slib_path
					result = subprocess.run(['ldd', lib_path], capture_output=True, text=True, check=True)
					for line in result.stdout.splitlines():
							parts = line.split()
							if len(parts) >= 3 and parts[1] == '=>':
									dep_path = parts[2]
									if 'not' in  parts[2] and 'found' in parts[3]:
										dep_path = parts[0].strip()
									try:
											cppyy.load_library(dep_path)
											if yasp.debug:
												print(f"[yasp-i] Loaded dependency: {dep_path}")
									except Exception as e:
											print(f"[yasp-error] Failed to load dependency: {dep_path}, error: {e}", file=sys.stderr)
			except subprocess.CalledProcessError as e:
					print(f"Error running ldd on {lib_path}: {e}", file=sys.stderr)
            
	def load(self, packages=[], libs=[], headers=[]):
		self.reload_yasp_cppyy_paths()
		if self.loaded_packages is None:
			self.loaded_packages = []
		if self.loaded_libs is None:
			self.loaded_libs = []
		for p in packages:
			if p not in self.loaded_packages:
				self.cppyy_add_paths(p)
				self.loaded_packages.append(p)
			# check if env variable YASP_PACKAGE_DIR is set
			_pack_upper_case = p.upper()
			_yasp_package_dir = os.environ.get(f'YASP_{_pack_upper_case}_DIR', None)
			if _yasp_package_dir is not None:
				_include_path = os.path.join(_yasp_package_dir, p, 'include')
				_lib_path = os.path.join(_yasp_package_dir, p, 'lib')
				_lib64_path = os.path.join(_yasp_package_dir, p, 'lib64')
				if yasp.debug:
					print('[yasp-i] Adding YASP_PACKAGE_DIR:', _yasp_package_dir, file=sys.stderr)
				if os.path.isdir(_include_path):
					if _include_path not in self.paths_include:
						cppyy.add_include_path(_include_path)
						self.paths_include.append(_include_path)
				if os.path.isdir(_lib_path):
					if _lib_path not in self.paths_lib:
						cppyy.add_library_path(_lib_path)
						self.paths_lib.append(_lib_path)
				if os.path.isdir(_lib64_path):
					if _lib64_path not in self.paths_lib:
						cppyy.add_library_path(_lib64_path)
						self.paths_lib.append(_lib64_path)
		for fn in headers:
			if yasp.debug:
				print('[yasp-i] Including header:', fn, file=sys.stderr)
			cppyy.include(fn)			
		for p in libs:
			if p not in self.loaded_libs:
				loaded = False
				try:
					cppyy.load_library(p)
					self.loaded_libs.append(p)
					loaded = True
				except Exception as e:
					print('[yasp-error] Failed to load library:', p, e, file=sys.stderr)
				if loaded is False:
					# try to find the library in the system path
					_candidate = self.find_lib_candidate_in_sys_path(p)
					if _candidate is not None:
						if yasp.debug:
							print('[yasp-i] Trying to load library:', _candidate, 'instead of', p, file=sys.stderr)
						if self.jupyter:
							self.load_dependencies(_candidate)
						#_load_ret = cppyy.gbl.gSystem.Load(_candidate)
						# print('[yasp-i] Load return:', _load_ret, file=sys.stderr)
						cppyy.load_library(_candidate)
						self.loaded_libs.append(p)
					else:
						print('[yasp-warn] No candidate found for:', p, file=sys.stderr)

	def get(self, symbol = '', verbose=False):
		try:
			x = getattr(cppyy.gbl, symbol)
			if x is not None:
				if verbose or yasp.debug:
					print('[yasp-i] returning symbol ' + symbol, x)
				return x
		except AttributeError:
			if verbose or yasp.debug:
				print('[yasp-warn] symbol ' + symbol + ' not found')
		return None
