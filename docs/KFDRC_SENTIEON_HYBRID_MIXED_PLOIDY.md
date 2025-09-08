# KFDRC Sentieon DNAscope/Haplotyper Hybrid Mixed Ploidy Workflow
This is a beta workflow to test the efficacy of using DNAscope + Haplotyper for mixed ploidy samples. It runs `DNAscop`e with an optional model (recommended) for the diploid contigs, and Haplotyper for the non-diploid contig.

<p align="center">
  <img src="logo/d3b-inline-white.svg" alt="D3b repository logo" width="660px" />
</p>

## INPUTS
### Required:
- alignment: BAM or CRAM file
- align_index: Index of `alignment` file
- reference: FASTA reference
- reference_index: FAI index of `reference`
- wgs_intervals: GATK Interval List format WGS intervals
- non_diploid_intervals: GATK Interval list format intervals of non-diploid regions
- non_diploid_ploidy: ploidy of non-diploid regions
- sentieon_license_file _or_ sentieon_license_server: One of these must be populated, depending on local run or cloud
### Strongly Recommended:
 - dnascope_model_bundle: Obtainable from https://github.com/Sentieon/sentieon-models
### Optional
- dsnp: dbSNP reference to use for populating VCF `ID` column
- dbsnp_index: index of `dbsnp`
- sample_id: If VCF `FORMAT` column sample names should be different from what is in `alignment` `SM:` `@RG` field, put new name here
- emit_mode: Currently changing this will break the workflow

## OUTPUTS:
- Hybrid GVCF
- Hybrid Genotyped VCF