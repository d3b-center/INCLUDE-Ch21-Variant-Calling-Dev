#!/usr/bin/env python3
"""Rename samples in a file based on manifest file."""
import argparse

def main():
    parser = argparse.ArgumentParser(description="Rename samples in a file based on manifest file.")
    parser.add_argument("--input_file", help="Input file with sample names to rename")
    parser.add_argument("--manifest_file", help="Manifest file with old and new sample names")
    parser.add_argument("--old_key", help="field in manifest with old sample names", default="Kids First Biospecimen ID")
    parser.add_argument("--new_key", help="field in manifest with new sample names", default="aliquot_id")
    parser.add_argument("--output_file", help="Output file with renamed samples")

    args = parser.parse_args()

    # Read the manifest file into a dictionary
    rename_dict = {}
    with open(args.manifest_file, "r") as manifest_file:
        header = manifest_file.readline().split("\t")
        old_index = header.index(args.old_key)
        new_index = header.index(args.new_key)
        for line in manifest_file:
            fields = line.strip().split("\t")
            rename_dict[fields[old_index]] = fields[new_index]
    with open(args.input_file, "r") as input_file:
        header = input_file.readline()
        lines = input_file.readlines()
    with open(args.output_file, "w") as output_file:
        print(header, file=output_file, end="")
        for line in lines:
            fields = line.strip().split("\t")
            if fields[0] in rename_dict:
                fields[0] = rename_dict[fields[0]]
            output_file.write("\t".join(fields) + "\n")

if __name__ == "__main__":
    main()
