#!/usr/bin/env python3

import re
import sys
import os
import argparse

def do_replace(args):
	pattern = None
	finput = None
	replacement = None

	def get_replacements(_lines, _defs):
		regex = r"{{[a-zA-Z0-9_]+}}"
		matches = re.finditer(regex, ''.join(_lines), re.MULTILINE)
		rv_matches = []
		for m in matches:
			if m.group(0) not in rv_matches:
				if m.group(0).strip('\n') in _defs.keys():
					rv_matches.append(m.group(0).strip('\n'))
		return rv_matches

	finput = None
	if os.path.exists(args.input):
		finput = args.input
	if finput:
		torepl = []
		with open(finput, 'r') as f:
			content = f.readlines()
		output = content
		definitions={}
		for d in args.define:
			definitions['{{x}}'.replace('x', d.split('=')[0])] = d.split('=')[1]
		torepl = get_replacements(content, definitions)
		# nesting
		do_repl = 1
		while do_repl < 100:
			do_repl += 1
			new_content = []
			for l in content:
				lnew = l
				for r in torepl:
					for d in definitions:
						if r == d:
							lnew = lnew.replace(r, definitions[d])
				new_content.append(lnew)
			content = new_content
			output = new_content
			torepl = get_replacements(content, definitions)
			if len(torepl) < 1:
				break
		for l in output:
			print(l.strip('\n'))

def main():
	parser = argparse.ArgumentParser()
	parser.add_argument('input', help='name of the recipe to process', type=str)
	parser.add_argument('--define', help='define replacement', type=str, nargs='+', default='')  
	args = parser.parse_args()
	do_replace(args)

if __name__=="__main__":
	_rv = main()
	exit(_rv)

