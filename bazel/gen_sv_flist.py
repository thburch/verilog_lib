import argparse
import os
import sys

parser = argparse.ArgumentParser()
parser.add_argument(
    "--output", help="The path to the output file.", type=str, required=True)
parser.add_argument("--srcs", help="The list of source files.",
                    type=str, nargs="+", required=True)
args = parser.parse_args()


def main():
    print(args.output)
    flist_file = open(args.output, 'w')
    flist_file.write(" ".join(args.srcs))
    flist_file.close()


if __name__ == "__main__":
    main()
