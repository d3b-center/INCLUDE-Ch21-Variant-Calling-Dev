# INCLUDE chr21 Variant Pipeline Development Project

This repo is used to house tools and workflows to improve and enhance analysis of non-diploid human genome data 


<p align="center">
  <a href="https://github.com/d3b-center/INCLUDE-Ch21-Variant-Calling-Dev Managed/blob/master/LICENSE"><img src="https://img.shields.io/github/license/kids-first/kf-api-dataservice.svg?style=for-the-badge"></a>
</p>

## [Kids First DRC GATK HaplotypeCaller Modified Ploidy BETA Workflow](docs/KFDRC_GATK_HC_MOD_PLOIDY_README.md)
This is a research workflow for users wishing to modify the ploidy of certain
regions of their existing GVCF calls. This uses the `coalescent` genotype model, equivalent to GATK 3.8
from Sentieon, a close analog of the original production workflow GATK 3.5 (via 4beta).

## [KFDRC Sentieon DNAscope/Haplotyper Hybrid Mixed Ploidy Workflow](docs/KFDRC_SENTIEON_HYBRID_MIXED_PLOIDY.md)
This is a beta workflow to test the efficacy of using DNAscope + Haplotyper for mixed ploidy samples.