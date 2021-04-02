import argparse
import os
import sys

parser = argparse.ArgumentParser()
parser.add_argument(
    "--top", help="The name of the top module.", type=str, required=True)
parser.add_argument(
    "--output", help="The location where the yosys file should be created.", type=str, required=True)
parser.add_argument(
    "--flist", help="The path to a file containing the files.", type=str, required=True)
args = parser.parse_args()

template = """\
read_verilog {sources}
synth_ice40 -top {top}
"""


def main():
    flist = open(args.flist, 'r').read()
    yosys_file = open(args.output, 'w')
    yosys_file.write(template.format(top=args.top, sources=flist))
    yosys_file.close()


if __name__ == "__main__":
    main()
