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

def get_this_directory():
	return os.path.dirname(os.path.abspath(__file__))


def find_files(rootdir='.', pattern='*'):
    return [os.path.join(rootdir, filename)
            for rootdir, dirnames, filenames in os.walk(rootdir)
            for filename in filenames
            if fnmatch.fnmatch(filename, pattern)]


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


class GenericObject(object):
	def __init__(self, **kwargs):
		for key, value in kwargs.items():
			self.__setattr__(key, value)

	def configure_from_args(self, **kwargs):
		for key, value in kwargs.items():
			self.__setattr__(key, value)

	def configure_from_dict(self, d):
		for k in d:
			self.__setattr__(k, d[k])

	def __getattr__(self, key):
		try:
			return self.__dict__[key]
		except:
			pass
		self.__setattr__(key, None)
		return self.__getattr__(key)

	def __str__(self) -> str:
		s = []
		s.append('[i] {}'.format(str(self.__class__).split('.')[1].split('\'')[0]))
		for a in self.__dict__:
			if a[0] == '_':
				continue
			sval = str(getattr(self, a))
			if len(sval) > 200:
				sval = sval[:200]
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


class Yasp(GenericObject):
	_break = 'stop'
	_continue = 'continue'

	_defaults = {
		
	}

	def __init__(self, **kwargs):
		super(Yasp, self).__init__(**kwargs)
		self.set_defaults()
		if self.args:
			if self.args.use_config:
				_cfg_filename = self.args.use_config
			else:
				_cfg_filename = self.args.default_config
			self.configure_from_config(_cfg_filename)
			if type(self.args) == dict:
				self.configure_from_dict(self.args)
			else:
				self.configure_from_dict(self.args.__dict__)
		if self.yasp is None:
			self.yasp = __file__
		self.verbose = self.debug
		self.get_known_recipes()
		if self.handle_cmnd_args() == Yasp._break:
			return
		if self.download:
			self.exec_download()
			return
		self.process_install()
  
	def set_defaults(self):

	def process_install(self):
		self.recipe = self.install
		self.fix_recipe_scriptname()
		if self.recipe:
			self.get_from_environment()
			# handle the script
			if not os.path.isfile(self.recipe_file):
				print('[e] recipe file', self.recipe_file, 'does not exist or not a file', file=sys.stderr)
				self.valid = False
				return
			else:
				if self.verbose:
					print('[i] script specified exists:', self.recipe_file, file=sys.stderr)
				self.valid = True
			self.workdir = os.path.join(self.workdir, self.recipe)
			self.builddir = os.path.join(self.workdir, 'build')
			self.output_script = os.path.join(self.workdir, 'build.sh')

	def get_known_recipes(self):
		self.known_recipes = []
		files = find_files(self.recipe_dir, '*.sh')
		for fn in files:
			recipe = os.path.splitext(fn.replace(self.recipe_dir + '/', ''))[0]
			self.known_recipes.append(recipe)

	def handle_cmnd_args(self):
		if self.list:
			self.get_known_recipes()
			for r in self.known_recipes:
				print(' ', r)
			return Yasp._break

		if self.configure:
			_out_dict = {}
			_ignore_keys = ['debug', 'list', 'cleanup', 'install', 'download',
					'dry_run', 'configure', 'use_config', 'clean', 'output', 'args', 'known_recipes', 'used_config', 'verbose']
			for k in self.__dict__:
				if k in _ignore_keys:
					continue
				_out_dict[k] = self.__dict__[k]
			_cfg_filename = self.default_config
			if self.use_config:
				_cfg_filename = self.use_config
			with open(_cfg_filename, 'w') as f:
				_ = yaml.dump(_out_dict, f)
			print('[i] config written to', _cfg_filename, file=sys.stderr)
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
		_which = { 'CXX': 'g++'}
		for w in _which:
			_what = _which[w]
			out, err, rc = self.exec_cmnd(f'which {_what}')
			if rc == 0:
				# print('[i] g++ is', out.decode('utf-8'))
				self.__setattr__(w, out.decode('utf-8').strip('\n'))
		self.n_cores = os.cpu_count()

	def fix_recipe_scriptname(self):
		if self.recipe:
			self.recipe = self.recipe.replace('-', '/')
			self.recipe_file = os.path.join(self.recipe_dir, self.recipe)
			if os.path.isdir(self.recipe_file):
				_candidates = find_files(self.recipe_file, '*.sh')
				self.recipe_file = sorted(_candidates)[0]
				self.recipe = os.path.splitext(self.recipe_file.replace(self.recipe_dir, '').lstrip('/'))[0]
			if not os.path.isfile(self.recipe_file):
				_split = os.path.splitext(self.recipe)
				if _split[1] != '.sh':
					self.recipe_file = self.recipe_file + '.sh'

	def run(self):
		if self.recipe:
			if self.valid:
				self.makedirs()
				self.make_replacements()
				if self.dry_run:
					print(f'[i] this is dry run - stopping before executing {self.output_script}')
				else:
					_p = None
					try:
						_p = subprocess.run([self.output_script], check=True)
					except subprocess.CalledProcessError as exc:
						print(f"{self.output_script} returned {exc.returncode}\n{exc}")
					if _p:
						print(f'[i] {self.output_script} returned {_p.returncode}')

	def makedirs(self):
		if self.clean:
			if os.path.exists(self.workdir):
				shutil.rmtree(self.workdir)
		if os.makedirs(self.workdir, exist_ok=True):
			os.chdir(self.workdir)
		os.makedirs(self.builddir, exist_ok=True)

	def get_contents(self):
		with open(self.recipe_file, 'r') as f:
			# self.contents = [_l.strip('\n') for _l in f.readlines()]
			self.contents = f.readlines()
		return self.contents

	def get_definitions(self, _lines):
		ret_dict = {}
		s = ''.join(_lines)
		if len(s) < 1:
			return ret_dict
		if len(s) < 1:
			return ret_dict
		regex = r"[\w]+="
		matches = re.finditer(regex, s, re.MULTILINE)
		for m in matches:
			_tag = m.group(0)
			for l in _lines:
				if l[:len(_tag):] == _tag:
					ret_dict[_tag] = l[len(_tag):].strip('\n')
		return ret_dict

	def get_replacements(self, _lines):
		regex = r"{{[a-zA-Z0-9_]+}}*"
		matches = re.finditer(regex, ''.join(_lines), re.MULTILINE)
		rv_matches = []
		for m in matches:
			if m.group(0) not in rv_matches:
				rv_matches.append(m.group(0).strip('\n'))
		return rv_matches

	def replace_in_line(self, l, _definitions, _replacements):
		replaced = False
		newl = l
		for r in _replacements:
			_tag = r[2:][:-2]
			if r in newl:
				try:
					_repls = _definitions[_tag+'=']
				except KeyError:
					_repls = str(self.__getattr__(_tag))
				newl = newl.replace(r, _repls)
				replaced = True
		return newl, replaced

	def make_replacements(self):
		_contents = self.get_contents()
		_definitions = self.get_definitions(_contents)
		if self.verbose:
			print('[i] definitions:', _definitions)
		_replacements = self.get_replacements(_contents)
		if self.verbose:
			print('[i] number of replacements found', len(_replacements))
			print('   ', _replacements)
		new_contents = []
		for l in _contents:
			newl = l
			replaced = True
			while replaced:
				newl, replaced = self.replace_in_line(newl, _definitions, _replacements)
			new_contents.append(newl)
		with open(self.output_script, 'w') as f:
			f.writelines(new_contents)
		if self.verbose:
			print('[i] written:', self.output_script, file=sys.stderr)
		os.chmod(self.output_script, stat.S_IRWXU)
		pass

	def exec_cmnd(self, cmnd):
		if self.verbose:
			print('[i] calling', cmnd, file=sys.stderr)
		args = shlex.split(cmnd)
		try:
			p = subprocess.Popen(args, shell=False, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
			out, err = p.communicate()
		except OSError as e:
			out = 'Failed.'
			err = ('Error #{0} : {1}').format(e[0], e[1])
		rc = p.returncode
		if self.verbose:
			print('    out:',out, file=sys.stderr)
			print('    err:',err, file=sys.stderr)
			print('     rc:', rc, file=sys.stderr)
		return out, err, rc

	def test_exec(self):
		if self.verbose:
			print('[i] checking bash syntax', self.recipe_file)
		out, err, rc = self.exec_cmnd('bash -n ' + self.recipe_file)
		if rc == 0:
			return True
		if rc > 0:
			return False
		return rc

	def exec_download(self):
		os.chdir(self.workdir)
		if self.verbose:
			print('[i] current dir:', os.getcwd(), file=sys.stderr)
		if self.clean:
			if os.path.isfile(self.output):
				os.remove(self.output)
		if os.path.isfile(self.output):
			return 0
		print(f'[i] downloading {self.download}', file=sys.stderr)
		out, err, rc = self.exec_cmnd('curl -o {} {}'.format(self.output, self.download))
		if rc > 0:
			print('[i] returning error={}'.format(rc), file=sys.stderr)
		if self.verbose:
			print(' download output:', out, sys.stderr)
			print(' download error :', err, sys.stderr)
		if os.path.isfile(self.output):
			print('[i] output file:', self.output, file=sys.stderr)
		return rc


def main():
	parser = argparse.ArgumentParser()
	# group = parser.add_mutually_exclusive_group(required=True)
	_prog_name = os.path.splitext(os.path.basename(__file__))[0]
	_default_config = os.path.join(os.path.dirname(__file__), '.yasp.yaml')
	_default_recipe_dir = os.path.join(get_this_directory(), 'recipes')
	_default_prefix = os.path.join(os.getenv('HOME'), _prog_name) # os.path.join(get_this_directory(), 'software')
	_default_workdir = os.path.join(os.getenv('HOME'), _prog_name, '.workdir')
	parser.add_argument('--configure', help='set and write default configuration', default=False, action='store_true')
	parser.add_argument('--use-config', help='use particular configuration file - default=$PWD/.yasp.yaml', default=None, type=str)
	parser.add_argument('--default-config', help='default config', default=_default_config, type=str)
	parser.add_argument(f'--{_prog_name}', help=f'point to {_prog_name}.py executable - default: this script', default=__file__)
	parser.add_argument('--cleanup', help='clean the main workdir (downloaded and build items)', action='store_true', default=False)
	parser.add_argument('-i', '--install', help='name of the recipe to process', type=str)
	parser.add_argument('-d', '--download', help='download file', type=str)
	parser.add_argument('--clean', help='start from scratch', action='store_true', default=False)
	parser.add_argument('--dry-run', help='dry run - do not execute output script', action='store_true', default=False)
	parser.add_argument('--recipe-dir', help='dir where recipes info sit - default: {}'.format(_default_recipe_dir), default=_default_recipe_dir, type=str)
	parser.add_argument('-o', '--output', help='output definition - for example for download', default='default.output', type=str)
	parser.add_argument('--prefix', help='prefix of the installation {}'.format(_default_prefix), default=_default_prefix)
	parser.add_argument('-w', '--workdir', help='set the work dir for the setup - default is {}'.format(_default_workdir), default='{}'.format(_default_workdir), type=str)
	parser.add_argument('-g', '--debug', '--verbose', help='print some extra info', action='store_true', default=False)
	parser.add_argument('-l', '--list', help='list recipes', action='store_true', default=False)
	args = parser.parse_args()
 
	sb = Yasp(args=args)
	if args.cleanup:
		if os.path.exists(sb.workdir):
			shutil.rmtree(sb.workdir)
		return

	if args.install or args.debug:
		print(sb)

	sb.run()

	# parse the build.sh and identify the parameters that could be overwritten - have to be in the form {{}}
	# replace those found in either
	# - config file
	# - in the current environment (!)
	# do not process if some variables are NOT DEFINED!

if __name__=="__main__":
	_rv = main()
	exit(_rv)
