import yasp
import sys
import os
import cppyy 

    
class YaspCppyyHelper(yasp.GenericObject):
	_instance = None
	def __new__(cls):
		if cls._instance is None:
			print('[i] Creating YaspCppyyHelper singleton.', file=sys.stderr)
			cls._instance = super(YaspCppyyHelper, cls).__new__(cls)
		return cls._instance

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

	def load(self, packages=[], libs=[], headers=[]):
		if self.loaded_packages is None:
			self.loaded_packages = []
		if self.loaded_libs is None:
			self.loaded_libs = []
		for p in packages:
			if p not in self.loaded_packages:
				self.cppyy_add_paths(p)
				self.loaded_packages.append(p)
		for fn in headers:
			print('[i] Including header:', fn, file=sys.stderr)
			cppyy.include(fn)			
		for p in libs:
			if p not in self.loaded_libs:
				cppyy.load_library(p)
				self.loaded_libs.append(p)

	def get(self, symbol = '', verbose=False):
		try:
			if verbose:
				print('[i] returning symbol ' + symbol)
			return getattr(cppyy.gbl, symbol)
		except AttributeError:
			if verbose:
				print('[e] symbol ' + symbol + ' not found')
		return None
