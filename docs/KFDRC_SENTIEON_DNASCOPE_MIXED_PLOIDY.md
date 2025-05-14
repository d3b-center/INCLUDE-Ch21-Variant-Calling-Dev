# KFDRC Sentieon DNAscope Mixed Ploidy Workflow
This is a beta workflow to test the efficacy of using DNAscope for mixed ploidy samples.

<p align="center">
  <img src="logo/kids_first_logo.svg" alt="Kids First repository logo" width="660px" />
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
### Optional
- dbSNP: dbSNP reference to use for populating VCF `ID` column
- sample_id: If VCF `FORMAT` column sample names should be different from what is in `alignment` `SM:` `@RG` field, put new name here
- emit_mode: Currently changing this will break the workflow

## OUTPUTS:
- DNAscope GVCF
- DNAscope Genotyped VCF