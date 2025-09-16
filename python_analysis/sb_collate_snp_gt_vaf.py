#!/usr/bin/env python3
"""Collate SNP genotype and VAF data from multiple files into a single file.

Read in VCFs from a sbfs mount and collate the SNP genotype and VAF data for downstream analysis
"""

import argparse
import csv
import sys
from concurrent.futures import ProcessPoolExecutor, as_completed
from typing import IO
from pysam import VariantFile, VariantRecord


def get_dbsnp_coords(
    dbsnp_path: str, rs_id_list: list[str] | None, contig: str | None
) -> dict[str, list]:
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
            if (rs_id_list and rs_id in rs_id_list) or rs_id not in dbsnp_coord:
                dbsnp_coord[rs_id] = [record.chrom, record.pos, record.ref, record.alts]
    return dbsnp_coord


def parse_vcfs(dbsnp: dict[str, list], vcf_fname: str, print_sample_id: str) -> list[str]:
    """Parse VCF files from a sbfs mount and collate the SNP genotype and VAF data.

    Args:
        dbsnp (dict[str, list]): Dictionary with rsID as key and a list of [chrom, pos] as value.
        vcf_fname (str): Path to the VCF file.
        out_file (IO): Output file handle to write the results to.

    """
    print_list: list[str] = []
    with VariantFile(vcf_fname, threads=4) as vcf_file:
        print(f"Processing {vcf_fname} for {print_sample_id}", file=sys.stderr)
        try:
            for rs_id in dbsnp:
                # format location as SAM region string as it's 1-based
                sam_region = f"{dbsnp[rs_id][0]}:{dbsnp[rs_id][1]}-{dbsnp[rs_id][1]}"
                for record in vcf_file.fetch(region=sam_region):
                    sample_id = record.samples.keys()[0]
                    # We want it to either be a call in a ref block, or an already annotated rs_id
                    if (
                        record.alts[0] == "<NON_REF>"
                        or (record.id is not None and record.id == rs_id)
                        or (
                            record.pos == dbsnp[rs_id][1]
                            and (record.alts is not None and record.alts[0] in dbsnp[rs_id][3])
                        )
                    ):
                        # Get the genotype
                        gt: str = "/".join(map(str, record.samples[sample_id]["GT"]))
                        # Get the VAF
                        if (
                            "AD" in record.samples[sample_id]
                            and record.samples[sample_id]["DP"] > 0
                        ):
                            vaf: float = (
                                record.samples[sample_id]["AD"][1] / record.samples[sample_id]["DP"]
                            )
                        else:
                            vaf = 0.0

                        # Print the results
                        print_list.append(
                            f"{print_sample_id}\t{rs_id}\t{dbsnp[rs_id][0]}\t{dbsnp[rs_id][1]}\t{gt}\t{vaf}"
                        )
                    else:
                        print(
                            f"Skipping {rs_id} {record.pos} in {vcf_fname}",
                            file=sys.stderr,
                        )
        except Exception as e:
            print(f"Error processing {vcf_fname}: {e}", file=sys.stderr)
            sys.exit(1)
        return print_list


def parse_joint_vcf(dbsnp: dict[str, list], vcf_fname: str, out_file: IO):
    """Parse a joint VCF file and collate the SNP genotype and VAF data.

    Args:
        dbsnp (dict[str, list]): Dictionary with rsID as key and a list of [chrom, pos] as value.
        vcf_fname (str): Path to the VCF file.
        out_file (IO): Output file handle to write the results to.

    """
    with VariantFile(vcf_fname, threads=8) as vcf_file:
        print(f"Processing joint calls {vcf_fname}", file=sys.stderr)
        for rs_id in dbsnp:
            print(f"Processing {rs_id}", file=sys.stderr)
            # format location as SAM region string as it's 1-based
            sam_region = f"{dbsnp[rs_id][0]}:{dbsnp[rs_id][1]}-{dbsnp[rs_id][1]}"
            try:
                record: VariantRecord = vcf_file.fetch(region=sam_region).__next__()
                for sample_id in record.samples:
                    # We want it to either be a call in a ref block, or an already annotated rs_id
                    if (record.id is not None and record.id == rs_id) or (
                        record.pos == dbsnp[rs_id][1]
                        and (record.alts is not None and record.alts[0] in dbsnp[rs_id][3])
                    ):
                        # Get the genotype
                        gt: str = "/".join(map(str, record.samples[sample_id]["GT"]))
                        # Get the VAF
                        if (
                            "AD" in record.samples[sample_id]
                            and record.samples[sample_id]["DP"] > 0
                        ):
                            vaf: float = (
                                record.samples[sample_id]["AD"][1] / record.samples[sample_id]["DP"]
                            )
                        else:
                            vaf = 0.0

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
                print(
                    f"{e}. Skipping {rs_id} {dbsnp[rs_id][0]}:{dbsnp[rs_id][1]}, no calls found",
                    file=sys.stderr,
                )
                # Need to reopen VCF file iterator for the next rs_id
                # This is a workaround for the StopIteration error
                vcf_file.reset()


def main():
    parser = argparse.ArgumentParser(
        description=(
            "Collate SNP genotype and VAF data from multiple files into a single file."
            "Use manifest ot single joint VCF"
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
        "-j",
        "--joint_vcf",
        action="store",
        dest="joint_vcf",
        help="Joint VCF file instead of manifest",
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
    parser.add_argument(
        "-f",
        "--field",
        action="store",
        dest="field",
        help="Which ID field to use for sample ID",
        default="Kids First Biospecimen ID",
    )

    args = parser.parse_args()
    print("Reading rs ID list and getting related dbSNP coordinates", file=sys.stderr)
    rs_id_list: list[str] | None = None
    if args.rs_id_list is not None:
        with open(args.rs_id_list) as rs_id_file:
            rs_id_list = rs_id_file.read().splitlines()
    dbsnp: dict[str, list] = get_dbsnp_coords(args.dbsnp, rs_id_list, args.contig)
    with open(args.out_file, "w") as out_file:
        print("sample_id\trs_id\tchrom\tpos\tsample_genotype\tsample_vaf", file=out_file)
        if args.manifest is not None:
            with open(args.manifest) as manifest:
                # print header
                manifest_file = csv.reader(manifest, delimiter="\t")
                head: list[str] = next(manifest_file)
                name_idx: int = head.index("name")
                sample_idx: int = head.index(args.field)
                with ProcessPoolExecutor(max_workers=4) as executor:
                    tasks = [
                        executor.submit(
                            parse_vcfs, dbsnp, f"{args.sb_mount}/{line[name_idx]}", line[sample_idx]
                        )
                        for line in manifest_file
                        if not line[name_idx].endswith("tbi")
                    ]
                    try:
                        for task in as_completed(tasks):
                            print(*task.result(), sep="\n", file=out_file)
                    except KeyboardInterrupt:
                        print("Keyboard interrupt, exiting", file=sys.stderr)
                        executor.shutdown(wait=False, cancel_futures=True)
                        sys.exit(1)
                    except TimeoutError:
                        print("Timeout occurred during shutdown.", file=sys.stderr)
                    finally:
                        out_file.close()
        elif args.joint_vcf is not None:
            parse_joint_vcf(dbsnp, args.joint_vcf, out_file)
        else:
            print("No manifest or joint VCF file provided, exiting", file=sys.stderr)
            sys.exit(1)

    print("Finished processing all files", file=sys.stderr)


if __name__ == "__main__":
    main()
