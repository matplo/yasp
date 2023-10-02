#!/usr/bin/env python3

import os, stat
import argparse
import sys
import yasp
import yaml
import re

class YaspReplace(yasp.GenericObject):
	_default_config = os.path.join(yasp.get_this_directory(), '.yasp.yaml')
	_max_repl = 10000
	_defaults = {}
	def __init__(self, **kwargs):
		super(YaspReplace, self).__init__(**kwargs)
		self.set_defaults()
		self.configure_from_config(YaspReplace._default_config)
		if self.args:
			if self.args.use_config:
				self.configure_from_config(self.args.use_config)
			if type(self.args) == dict:
				self.configure_from_dict(self.args, ignore_none=True)
			else:
				self.configure_from_dict(self.args.__dict__)
		_output = self.process_replacements(self.input, self.file)
		# _outlines = [s.strip('\n') for s in _output]
		# print(_outlines)
		# self.write_output_file(self.output, _outlines, False)
		if self.show:
			print('[i] possible replacements:')
			for r in self.replacements:
				print('   ', r)
			return
		self.write_output_file(self.output, _output, False)

	def set_defaults(self):
		for d in YaspReplace._defaults:
			if self.__getattr__(d) is None:
				self.__setattr__(d, YaspReplace._defaults[d])
			else:
				print(self.__getattr__(d))

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
		return yasp.Yasp._continue

	def get_from_environment(self):
		_which = {}
		for w in _which:
			_what = _which[w]
			out, err, rc = self.exec_cmnd(f'which {_what}')
			if rc == 0:
				# print('[i] g++ is', out.decode('utf-8'))
				self.__setattr__(w, out.decode('utf-8').strip('\n'))

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

	def get_definitions_iter(self, _lines):
		ret_dict = {}
		for l in _lines:
			_d = self.get_definitions([l])
			ret_dict.update(_d)
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
			# print(f'-- checking for replacemend of {r} in {_replacements}')
			_tag = r[2:][:-2]
			if r in newl:
				try:
					_repls = _definitions[_tag+'=']
				except KeyError:
					if '.' in _tag:
						_tag = _tag.split('.')[1]
					_repls = str(self.__getattr__(_tag))
				if _repls is None:
					_repls = ""
				newl = newl.replace(r, _repls)
				replaced = True
		return newl, replaced

	def process_replacements(self, input_string, input_file):
		if input_file:
			_contents = self.get_file_contents(input_file)
		else:
			_contents = input_string.split(';')
		if self.verbose:
			print(f'[i] contents: {_contents}')
		if self.replacements is None:
			self.replacements = []
		self.replacements.extend(self.get_replacements(_contents))
		if self.verbose:
			print(f'[i] replacements: {self.replacements}')
		_definitions = self.get_definitions(_contents)
		if self.define:
			_defs_args = self.get_definitions_iter(self.define)
			_definitions.update(_defs_args)
		if self.verbose:
			print('[i] definitions:', _definitions)
		if self.verbose:
			print('[i] number of replacements found', len(self.replacements))
			print('   ', self.replacements)
		new_contents = []
		for l in _contents:
			newl = l
			replaced = True
			_rcount = 0
			while replaced:
				newl, replaced = self.replace_in_line(newl, _definitions, self.replacements)
				_rcount += 1
				if _rcount > YaspReplace._max_repl:
					print('[e] max replacement count exceeded - break here; something is off - circular replacement?')
					print('    duplication/circular dep in definitions <<tag>>= and replacement {{<<tag>>}} ?')
					print('[i] definitions:', _definitions)
					print(f'[i] replacements: {self.replacements}')
					for d in _definitions:
						for r in self.replacements:
							if d.replace('=','') == r.replace('{{', '').replace('}}', ''):
								print('[w] problematic candidates:', d, r)
					exit(-1)
			new_contents.append(newl)
		return new_contents

	def write_output_file(self, outfname, contents, executable=False):
		if outfname:
			with open(outfname, 'w') as f:
				f.writelines(contents)
			if executable:
				os.chmod(outfname, stat.S_IRWXU)
		else:
			sys.stdout.writelines(contents)
			sys.stdout.write('\n')
		if self.verbose:
			print('[i] written:', outfname, file=sys.stderr)


def add_arguments_to_parser(parser):
	parser.add_argument('-i', '--input', help='text to process', type=str, nargs='+', default='')
	parser.add_argument('-o', '--output', help='file to write to', type=str, default='')
	parser.add_argument('--define', help='define replacement', type=str, nargs='+', default='')
	parser.add_argument('-f', '--file', help='file to process or text', type=str, default=None)
	parser.add_argument('--use-config', help='use particular configuration file - default=$PWD/.yasp.yaml', default=None, type=str)
	parser.add_argument('-g', '--debug', help='print some extra info', action='store_true', default=False)
	parser.add_argument('--verbose', help='print some extra info', action='store_true', default=False)
	parser.add_argument('--show', help='show what`s possible', action='store_true', default=False)
	parser.add_argument('--dry-run', help='dry run - do not execute output script', action='store_true', default=False)


def main():
	parser = argparse.ArgumentParser()
	add_arguments_to_parser(parser)
	args = parser.parse_args()

	args.input = ';'.join([';'.join(s.split('\n')) for s in args.input])
	yr = YaspReplace(args=args)


if __name__=="__main__":
	_rv = main()
	exit(_rv)
