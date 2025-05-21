#!/usr/bin/env python3
"""Plot SNP genotype and VAF data using ggplot into dotplot."""

import argparse

import pandas as pd
from plotnine import aes, element_text, geom_hline, geom_point, ggplot, labs, theme


def main():
    parser = argparse.ArgumentParser(
        description="Plot SNP genotype and VAF data using ggplot into dotplot"
    )
    parser.add_argument("-i", "--input", type=str, required=True, help="Input file with SNP data")
    parser.add_argument("-o", "--output", type=str, required=True, help="Output file for the plot")
    parser.add_argument(
        "-t",
        "--title",
        type=str,
        required=False,
        help="Title of the plot",
        default="SNP Genotype and VAF Plot",
    )
    args = parser.parse_args()
    # Read the input data
    snp_gt_vaf_data: pd.DataFrame = pd.read_csv(args.input, delimiter="\t")
    snp_gt_vaf_data = snp_gt_vaf_data.convert_dtypes()
    # Create the plot
    p = (
        ggplot(snp_gt_vaf_data, aes("rs_id", "sample_vaf"))
        + geom_point(aes(color="sample_genotype"), alpha=0.5, size=1)
        + labs(
            title=args.title,
            x="SNP ID",
            y="VAF",
        )
        + theme(
            axis_text_x=element_text(angle=90),
            legend_title=element_text(text="Genotype"),
            legend_position="bottom",
            figure_size=(7, 8)
        )
        + geom_hline(yintercept=[0, 0.33, 0.66, 1.0], linetype="dashed", color="grey", alpha=0.5)
    )
    # Save the plot
    p.save(args.output, dpi=300)


if __name__ == "__main__":
    main()
