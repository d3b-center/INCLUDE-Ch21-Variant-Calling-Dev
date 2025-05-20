#!/usr/bin/env python3
"""Plot SNP genotype and VAF data using ggplot into dotplot."""

import argparse
import pdb
from turtle import color

import pandas as pd
from ggplot import ggplot, aes, geom_point, geom_hline, labs, theme, element_text, scale_x_discrete


def main():
    parser = argparse.ArgumentParser(
        description="Plot SNP genotype and VAF data using ggplot into dotplot"
    )
    parser.add_argument("-i", "--input", type=str, required=True, help="Input file with SNP data")
    parser.add_argument("-o", "--output", type=str, required=True, help="Output file for the plot")
    args = parser.parse_args()

    # Read the input data
    snp_gt_vaf_data: pd.DataFrame = pd.read_csv(args.input, delimiter="\t")
    snp_gt_vaf_data['rs_id'] = snp_gt_vaf_data['rs_id'].astype(str)
    snp_gt_vaf_data['sample_genotype'] = snp_gt_vaf_data['sample_genotype'].astype(str)
    # Create the plot
    p = (
        ggplot(snp_gt_vaf_data, aes(x="rs_id", y="sample_vaf", colour="sample_genotype"))
        + geom_point()
        # + geom_hline(yintercept=[0, 0.33, 0.66, 1.0], linetype="dashed")
        + labs(
            title="chr21 Common SNPs Genotyped VCF",
            x="rs ID",
            y="VAF",
        )
        + theme(axis_text_x=element_text(angle=90))
    )
    # Save the plot
    p.save(args.output)


if __name__ == "__main__":
    main()
