#!/usr/bin/env python3

import re
import sys
import os
import argparse
from yasp import GenericObject

def do_replace(args):
	contents = [args.input]
	if args.file:
		with open(args.input) as f:
			contents = f.readlines()
	else:
		if len(args.input) <= 0:
			contents = sys.stdin.readlines()		
	new_contents = []
	for l in contents:
		newl = l
		for x in args.from_to:
			xfrom = x.split(args.separator)[0]
			xto = x.split(args.separator)[1]
			if xfrom in l:
				newl = newl.replace(xfrom, xto)
		new_contents.append(newl)
	if args.output:
		with open(args.output, 'w') as fout:
			fout.writelines(new_contents)
	else:
		sys.stdout.writelines(new_contents)

extra_help='''
usage examples:
	echo "something with a y" | le -r y::x
	echo "something with a y" | le -r ytox -s to
	le -fi some_file.txt -r y::x ala::kota -o some_other_file.txt
	le -i "ala ma kota" -r ma::miala
'''
def main():
	parser = argparse.ArgumentParser(epilog=extra_help, formatter_class=argparse.RawDescriptionHelpFormatter)
	parser.add_argument('-i', '--input', help='what to process', type=str, default='')
	parser.add_argument('-o', '--output', help='write to file', type=str, default='')
	parser.add_argument('-f', '--file', help='is input a file?', action='store_true', default=False)
	parser.add_argument('-r', '--from-to', help='define replacement from<separator>to', type=str, nargs='+', default='')  
	parser.add_argument('-s', '--separator', help='what separator to use for --from-to from<separator>to syntax - defaut is double character ::', type=str, default='::')
	args = parser.parse_args()
	do_replace(args)

if __name__=="__main__":
	_rv = main()
	exit(_rv)


