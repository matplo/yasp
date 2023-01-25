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
	_this_file = os.path.dirname(os.path.realpath(os.path.abspath(__file__)))
	return _this_file


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
	max_chars = 500
	def __init__(self, **kwargs):
		for key, value in kwargs.items():
			self.__setattr__(key, value)

	def configure_from_args(self, **kwargs):
		for key, value in kwargs.items():
			self.__setattr__(key, value)

	def configure_from_dict(self, d, ignore_none=False):
		for k in d:
			if d[k] is None:
				continue
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
			if len(sval) > self.max_chars:
				sval = sval[:self.max_chars-4] + '...'
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
	_same_prefix = False
	_this_file = os.path.abspath(__file__)
	_yasp_dir = get_this_directory()
	_prog_name = os.path.splitext(os.path.basename(__file__))[0]
	_default_config = os.path.join(get_this_directory(), '.yasp.yaml')
	_default_recipe_dir = os.path.join(get_this_directory(), 'recipes')
	_default_prefix = os.path.join(os.getenv('HOME'), _prog_name)
	_default_workdir = os.path.join(os.getenv('HOME'), _prog_name, '.workdir')
	_defaults = {
			f'{_prog_name}' : _this_file,
            'default_config' : _default_config,
            'recipe_dir' : _default_recipe_dir,
            'prefix' : _default_prefix,
            'workdir' : _default_workdir,
			'download_command' : 'wget --no-check-certificate',
			'python' : os.path.abspath(os.path.realpath(sys.executable)),
			'yasp_dir' : _yasp_dir,
			'python_version' : f'{sys.version_info.major}.{sys.version_info.minor}',
			'python_site_packages_subpath' : f'python{sys.version_info.major}.{sys.version_info.minor}/site-packages'
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
		self.verbose = self.debug
		self.get_known_recipes()
		if self.handle_cmnd_args() == Yasp._break:
			self.no_install = True
			return
		if self.download:
			self.exec_download()
			self.no_install = True
			return
		self.base_prefix 	= self.prefix
		self.base_workdir 	= self.workdir
		self.run()

	def set_defaults(self):
		for d in Yasp._defaults:
			if self.__getattr__(d) is None:
				self.__setattr__(d, Yasp._defaults[d])
			else:
				print(self.__getattr__(d))

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
			_ignore_keys = ['debug', 'list', 'cleanup', 'install', 'download', "redownload", 'yes', 'module', 'module_only',
					'dry_run', 'configure', 'use_config', 'clean', 'output', 'args', 'known_recipes', 'used_config', 'verbose', 'query']
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
			# self.recipe = self.recipe.replace('-', '/')
			self.recipe = self.recipe.replace('==', '/')
			self.recipe_file = os.path.join(self.recipe_dir, self.recipe)
			if os.path.isdir(self.recipe_file):
				_candidates = find_files(self.recipe_file, '*.sh')
				self.recipe_file = sorted(_candidates)[0]
				self.recipe = os.path.splitext(self.recipe_file.replace(self.recipe_dir, '').lstrip('/'))[0]
			if not os.path.isfile(self.recipe_file):
				_split = os.path.splitext(self.recipe)
				if _split[1] != '.sh':
					self.recipe_file = self.recipe_file + '.sh'


	def user_confirm(self, what, default_answer, acceptable_answers=['yes', 'no', 'y', 'n']):
		_answer = '?'
		if self.yes:
			return 'yes'
		acceptable_answers.append(default_answer)
		while _answer.lower() not in acceptable_answers:
			_answer = str(input(f'[q] {what} {acceptable_answers} [default={default_answer}]?')).lower().strip()
			if len(_answer) < 1:
				_answer = default_answer
		if _answer == 'y':
			_answer = 'yes'
		if _answer == 'n':
			_answer = 'no'
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
					print('[e] recipe file', self.recipe_file, 'does not exist or not a file', file=sys.stderr)
					self.valid = False
					continue
				else:
					if self.verbose:
						print('[i] script specified exists:', self.recipe_file, file=sys.stderr)
					self.valid = True
				self.workdir = os.path.join(self.base_workdir, self.recipe)
				self.builddir = os.path.join(self.workdir, 'build')
				self.output_script = os.path.join(self.workdir, 'build.sh')
				if self.same_prefix is False:
					self.prefix = os.path.join(self.prefix, self.recipe)
				if self.valid:
					self.module_recipe = self.recipe_file.replace('.sh', '.module')
					self.build_script_contents = self.process_replacements(self.recipe_file)
					self.build_script_contents = self.process_yasp_tags(self.build_script_contents)
					self.build_script_contents = self.process_replacements(self.recipe_file) # yes has to do it twice
					if os.path.isfile(self.module_recipe):
						self.module_output_fname = os.path.join(self.base_prefix, 'modules', self.recipe.replace('.sh', ''))
						self.module_contents = self.process_replacements(self.module_recipe)
						self.module_contents = self.process_yasp_tags(self.module_contents)
						self.module_contents = self.process_replacements(self.module_recipe) # yes has to do it twice
						self.module_dir = os.path.dirname(self.module_output_fname)
					self.makedirs()
					if self.cleanup:
						self.do_cleanup()
						continue
					if self.clean:
						self.do_clean()
						continue
					if self.dry_run or self.query:
						if self.dry_run:
							print(f'[i] this is dry run - stopping before executing {self.output_script}')
							print(self, file=sys.stderr)
						continue

					if self.module_only:
						if self.module_output_fname:
							self.write_output_file(self.module_output_fname, self.module_contents, executable=False)
						continue

					# execute the shell build script
					self.write_output_file(self.output_script, self.build_script_contents, executable=True)
					_p = None
					try:
						_p = subprocess.run([self.output_script], check=True)
					except subprocess.CalledProcessError as exc:
						print(f"{self.output_script} returned {exc.returncode}\n{exc}")
					if _p:
						print(f'[i] {self.output_script} returned {_p.returncode}')

					if self.module and self.module_output_fname:
						self.write_output_file(self.module_output_fname, self.module_contents, executable=False)

	def rm_dir_with_confirm(self, sdir):
		if os.path.isdir(sdir):
			if self.user_confirm(f'remove {sdir}', 'y') == 'yes':
				if self.dry_run:
					print(f'[i] not removing since dry run is flag is set to: {self.dry_run}')
				else:
					print(f'[w] removing {sdir}')
					shutil.rmtree(sdir)

	def do_clean(self):
		if self.module_dir:
			self.rm_dir_with_confirm(self.module_dir)
		self.rm_dir_with_confirm(self.builddir)
		self.rm_dir_with_confirm(self.prefix)

	def do_cleanup(self):
		self.rm_dir_with_confirm(self.workdir)

	def makedirs(self):
		if self.module_dir:
			os.makedirs(self.module_dir, exist_ok=True)
		os.makedirs(self.builddir, exist_ok=True)
		if os.makedirs(self.workdir, exist_ok=True):
			os.chdir(self.workdir)

	def get_file_contents(self, fname):
		_contents = []
		with open(fname, 'r') as f:
			_contents = f.readlines()
		return _contents

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
				if _repls is None:
					_repls = ""
				newl = newl.replace(r, _repls)
				replaced = True
		return newl, replaced

	def process_replacements(self, input_file):
		_contents = self.get_file_contents(input_file)
		_definitions = self.get_definitions(_contents)
		if self.verbose:
			print('[i] definitions:', _definitions)
		if self.replacements is None:
			self.replacements = []
		self.replacements.extend(self.get_replacements(_contents))
		if self.verbose:
			print('[i] number of replacements found', len(self.replacements))
			print('   ', self.replacements)
		new_contents = []
		for l in _contents:
			newl = l
			replaced = True
			while replaced:
				newl, replaced = self.replace_in_line(newl, _definitions, self.replacements)
			new_contents.append(newl)
		return new_contents

	def write_output_file(self, outfname, contents, executable=False):
		with open(outfname, 'w') as f:
			f.writelines(contents)
		# if self.verbose:
		print('[i] written:', outfname, file=sys.stderr)
		if executable:
			os.chmod(outfname, stat.S_IRWXU)

	def exec_cmnd(self, cmnd, shell=False):
		if self.verbose:
			print('[i] calling', cmnd, file=sys.stderr)
		args = shlex.split(cmnd)
		try:
			p = subprocess.Popen(args, shell=shell, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
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

	def extract_shell_var(self, s):
		_var = s.split('=')[0].split()[-1]
		_shell_expr = s.split('=')[1]
		_value = _shell_expr
		return _var, _value
  
	def process_yasp_tags(self, slines):
		_rv = []
		for l in slines:
			# stay passive - do not replace anything
			_rv.append(l)
			if l.split(' ')[0] == '#yasp':
				if l.split(' ')[1] == '--shell-var':
					_rest = ' '.join(l.split(' ')[1:]).strip('\n')
					_var, _cmnd = self.extract_shell_var(_rest)
					if self.verbose:
						print('extracted:', _cmnd, file=sys.stderr)
					out, err, rc = self.exec_cmnd(_cmnd, shell=True)
					if err or rc != 0:
						print(f'[e] extract {_var} failed', file=sys.stderr)
						print(f'{err}', file=sys.stderr)
					else:
						_val = out.decode('utf-8').strip('\n')
						self.__setattr__(_var, _val)
						_rv.append(f'# yasp var imported: {_var}={_val}')
			if l.split(' ')[0] == '#yasp':
				if l.split(' ')[1] == '--set':
					_rest = ' '.join(l.split(' ')[1:]).strip('\n')
					_var, val = self.extract_shell_var(_rest)
					if self.verbose:
						print('extracted:', _cmnd, file=sys.stderr)
					self.__setattr__(_var, _val)					
		return _rv

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
		if self.redownload:
			if os.path.isfile(self.output):
				os.remove(self.output)
		if os.path.isfile(self.output):
			return 0
		print(f'[i] downloading {self.download}', file=sys.stderr)
		_opt = '-O'
		if 'wget' in self.download_command:
			_opt = '-O'
		if 'curl' in self.download_command:
			_opt = '-o'
		out, err, rc = self.exec_cmnd('{} {} {} {}'.format(self.download_command, _opt, self.output, self.download))
		if rc > 0 or self.verbose:
			print('[i] returning error={}'.format(rc), file=sys.stderr)
			print(' download output:', out, file=sys.stderr)
			print(' download error :', err, file=sys.stderr)
		if os.path.isfile(self.output):
			print('[i] output file:', self.output, file=sys.stderr)
		return rc


def yasp_feature(what, args={}):
	sb = Yasp(args=args)
	try:
		rv = sb.__getattr__(what)
	except:
		rv = None
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

def main():
	parser = argparse.ArgumentParser()
	# group = parser.add_mutually_exclusive_group(required=True)
	parser.add_argument('--configure', help='set and write default configuration', default=False, action='store_true')
	parser.add_argument('--use-config', help='use particular configuration file - default=$PWD/.yasp.yaml', default=None, type=str)
	parser.add_argument(f'--{Yasp._prog_name}', help=f'point to {Yasp._prog_name}.py executable - default: this script')
	parser.add_argument('--cleanup', help='clean the main workdir (downloaded and build items)', action='store_true', default=False)
	parser.add_argument('-i', '--install', help='name of the recipe to process', type=str, nargs='+')
	parser.add_argument('-d', '--download', help='download file', type=str)
	parser.add_argument('--clean', help='start from scratch', action='store_true', default=False)
	parser.add_argument('--redownload', help='redownload even if file already there', action='store_true', default=False)
	parser.add_argument('--dry-run', help='dry run - do not execute output script', action='store_true', default=False)
	parser.add_argument('--recipe-dir', help='dir where recipes info sit - default: {}'.format(Yasp._default_recipe_dir), type=str)
	parser.add_argument('-o', '--output', help='output definition - for example for download', default='default.output', type=str)
	parser.add_argument('--prefix', help='prefix of the installation {}'.format(Yasp._default_prefix))
	parser.add_argument('--same-prefix', help='if this is true all install will go into the same prefix - default is {}/package-with-version'.format(Yasp._same_prefix), action='store_true', default=False)
	parser.add_argument('-w', '--workdir', help='set the work dir for the setup - default is {}'.format(Yasp._default_workdir), type=str)
	parser.add_argument('-g', '--debug', '--verbose', help='print some extra info', action='store_true', default=False)
	parser.add_argument('-l', '--list', help='list recipes', action='store_true', default=False)
	parser.add_argument('--download-command', help='overwrite download command - default is wget; could be curl', type=str, default=None)
	parser.add_argument('-q', '--query', help='query for a feature or files or directory for a file - join with feature <name> files <pattern> or dirs <pattern> (where file located) to match a query - "PseudoJet.hh" for example', type=str, default=None, nargs=2)
	parser.add_argument('-y', '--yes', help='answer yes to any questions - in particular, on --clean so', action='store_true', default=False)
	parser.add_argument('-m', '--module', help='write module file', action='store_true', default=False)
	parser.add_argument('--module-only', help='write module file and exit', action='store_true', default=False)
	parser.add_argument('--use-python', help='specify python executable - default is current {}'.format(sys.executable), default=sys.executable)
	args = parser.parse_args()

	sb = Yasp(args=args)
 
	if os.path.samefile(os.path.abspath(os.path.realpath(sys.executable)), sb.python) is False:
		print('[w] looks like yasp called with different python than configured with...', file=sys.stderr)
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

	# if args.install or args.debug:
	if args.debug:
		print(sb)

	# sb.run()


if __name__=="__main__":
	_rv = main()
	exit(_rv)
