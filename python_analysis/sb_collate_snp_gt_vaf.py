#!/usr/bin/env python3
"""Collate SNP genotype and VAF data from multiple files into a single file.

Read in VCFs from a sbfs mount and collate the SNP genotype and VAF data for downstream analysis
"""

import argparse
import csv
import sys
from typing import IO

from pysam import VariantFile, VariantRecord


def get_dbsnp_coords(dbsnp_path: str, rs_id_list: list[str], contig: str | None) -> dict[str, list]:
    """Get dbSNP coordinates from a VCF file.

    Args:
        dbsnp_path (str): Path to the dbSNP VCF file.
        rs_id_list (list[str]): List of rsIDs to check.
        contig (str | None): Contig to limit the search to. If None, search all contigs.

    Returns:
        dict[str, list]: Dictionary with rsID as key and a list of [chrom, pos] as value.

    """
    dbsnp_coord: dict[str, list] = {}
    with VariantFile(dbsnp_path, threads=4) as dbsnp_file:
        for record in dbsnp_file.fetch(contig):
            rs_id = record.id
            if rs_id in rs_id_list:
                dbsnp_coord[rs_id] = [record.chrom, record.pos, record.ref, record.alts]
    return dbsnp_coord


def parse_vcfs(dbsnp: dict[str, list], vcf_fname: str, out_file: IO) -> None:
    """Parse VCF files from a sbfs mount and collate the SNP genotype and VAF data.

    Args:
        dbsnp (dict[str, list]): Dictionary with rsID as key and a list of [chrom, pos] as value.
        vcf_fname (str): Path to the VCF file.
        out_file (IO): Output file handle to write the results to.

    """
    with VariantFile(vcf_fname, threads=4) as vcf_file:
        sample_id: str = vcf_file.header.samples[0]
        print(f"Processing {vcf_fname} for {sample_id}", file=sys.stderr)
        try:
            for rs_id in dbsnp:
                record: VariantRecord = vcf_file.fetch(
                    dbsnp[rs_id][0], dbsnp[rs_id][1], dbsnp[rs_id][1] + 1
                ).__next__()
                # We want it to either be a call in a ref block, or an already annotated rs_id
                if record.id is None or record.pos != dbsnp[rs_id][1] or (
                    record.alts is not None and record.alts[0] in dbsnp[rs_id][3]
                ):
                    # Get the genotype
                    gt: str = "/".join(map(str, record.samples[sample_id]["GT"]))
                    # Get the VAF
                    try:
                        if "AD" in record.samples[sample_id]:
                            vaf: float = (
                                record.samples[sample_id]["AD"][1] / record.samples[sample_id]["DP"]
                            )
                        else:
                            vaf = 0
                    except ZeroDivisionError as e:
                        print(
                            f"{e}. ZeroDivisionError for {sample_id} {rs_id} {record.pos}",
                            file=sys.stderr,
                        )
                        vaf = 0
                    # Print the results
                    print(
                        f"{sample_id}\t{rs_id}\t{dbsnp[rs_id][0]}\t{dbsnp[rs_id][1]}\t{gt}\t{vaf}",
                        file=out_file,
                    )
                else:
                    print(
                        f"Skipping {rs_id} {record.pos} in {vcf_fname}",
                        file=sys.stderr,
                    )
        except Exception as e:
            print(f"Error processing {vcf_fname}: {e}", file=sys.stderr)


def main():
    parser = argparse.ArgumentParser(
        description=(
            "Collate SNP genotype and VAF data from multiple files into a single file."
            "Prints to stdout"
        ),
    )
    parser.add_argument("-d", "--dbsnp", action="store", dest="dbsnp", help="path to dbsnp file")
    parser.add_argument(
        "-s",
        "--sb_mount",
        action="store",
        dest="sb_mount",
        help="Mount locations for sbfs files",
    )
    parser.add_argument(
        "-m",
        "--manifest",
        action="store",
        dest="manifest",
        help="CAVATICA VCF manifest",
    )
    parser.add_argument(
        "-r",
        "--rs_id_list",
        action="store",
        dest="rs_id_list",
        help="New-line separated list of rsIDs to check",
    )
    parser.add_argument(
        "-o",
        "--out_file",
        action="store",
        dest="out_file",
        help="output file name",
        default="results.tsv",
    )
    parser.add_argument(
        "-c",
        "--contig",
        action="store",
        dest="contig",
        help="If rs_ids come frm a single contig, list here to speed up processing",
    )

    args = parser.parse_args()
    print("Reading rs ID list and getting related dbSNP coordinates", file=sys.stderr)
    with open(args.rs_id_list) as rs_id_file:
        rs_id_list: list[str] = rs_id_file.read().splitlines()
    dbsnp: dict[str, list] = get_dbsnp_coords(args.dbsnp, rs_id_list, args.contig)

    with open(args.manifest) as manifest, open(args.out_file, "w") as out_file:
        # print header
        print("sample_id\trs_id\tchrom\tpos\tsample_genotype\tsample_vaf")
        manifest_file = csv.reader(manifest, delimiter="\t")
        head: list[str] = next(manifest_file)
        name_idx: int = head.index("name")
        for line in manifest_file:
            fname: str = line[name_idx]
            if not fname.endswith("tbi"):
                vcf_path: str = f"{args.sb_mount}/{fname}"
                parse_vcfs(dbsnp, vcf_path, out_file)


if __name__ == "__main__":
    main()
