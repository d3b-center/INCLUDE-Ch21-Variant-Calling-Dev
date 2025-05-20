import argparse
import sys

from natsort import natsorted
from pysam import TabixFile, VariantFile, VariantHeader, tabix_index


def get_contig_list(vcf_file: str) -> list[str]:
    """Get the list of contigs from a VCF file.

    Args:
        vcf_file (str): Path to the VCF file.

    Returns:
        list: List of contig names.

    """
    tbx = TabixFile(vcf_file)
    return tbx.contigs


def print_contig_record(in_vcf: VariantFile, contig: str, out_vcf: VariantFile):
    """Print the records for a specific contig from a VCF file.

    Args:
        vcf_file (str): Path to the VCF file.
        contig (str): Contig name.
        out_vcf (VariantFile): Output VCF file handle.

    """
    try:
        for record in in_vcf.fetch(contig):
            out_vcf.write(record)
    except Exception as e:
        print(f"Error writing record {record} to output VCF: {e}", file=sys.stderr)
        sys.exit(1)


def main():
    parser = argparse.ArgumentParser(
        description="Merge VCFs and rename sample name in coordinate sorted VCFs."
    )
    parser.add_argument("--first_vcf", help="Input VCF file")
    parser.add_argument("--second_vcf", help="Input VCF file")
    parser.add_argument("--output_vcf", help="Output VCF file", default="output.vcf.gz")
    parser.add_argument("--sample_name", nargs="?", help="New sample name to replace the old one")

    args = parser.parse_args()
    # get contig list from first VCF
    contig_vcf1 = get_contig_list(args.first_vcf)
    # get contig list from second VCF
    contig_vcf2 = get_contig_list(args.second_vcf)
    contig_order = natsorted(list(set(contig_vcf1) | set(contig_vcf2)))

    with (
        VariantFile(args.first_vcf, threads=4) as vcf1,
        VariantFile(args.second_vcf, threads=4) as vcf2,
    ):
        vcf_header = VariantHeader()
        for record in vcf1.header.records:
            vcf_header.add_record(record)
        # replace sample name in header
        if args.sample_name:
            vcf_header.add_sample(args.sample_name)
        else:
            vcf_header = vcf1.header
        with VariantFile(args.output_vcf, "w", header=vcf_header, threads=4) as out_vcf:
            # open output VCF file
            for contig in contig_order:
                if contig in contig_vcf1:
                    print(f"Writing contig {contig} from {args.first_vcf}", file=sys.stderr)
                    print_contig_record(vcf1, contig, out_vcf)
                else:
                    print(f"Writing contig {contig} from {args.second_vcf}", file=sys.stderr)
                    print_contig_record(vcf2, contig, out_vcf)
        print(f"Indexing output VCF file {args.output_vcf}", file=sys.stderr)
        tabix_index(args.output_vcf, preset="vcf", force=True)


if __name__ == "__main__":
    main()
