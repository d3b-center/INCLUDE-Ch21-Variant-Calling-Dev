#!/usr/bin/env nextflow

include { SENTIEON_DNASCOPE as SENTIEON_DNASCOPE_DIPLOID } from './modules/local/sentieon/dnascope/main'
include { SENTIEON_HAPLOTYPER } from './modules/local/sentieon/haplotyper/main'
include { GATK_INTERVALLISTOOLS } from './modules/local/gatk/intervallisttools/main'
// include { PICARD_MERGEVCFS } from './modules/local/picard/mergevcfs/main'
include { BCFTOOLS_CONCAT_RENAME } from './modules/local/bcftools/concat_rename/main'
include { SENTIEON_GVCFTYPER } from './modules/local/sentieon/gvcftyper/main.nf'

workflow {
    main:
    alignment = Channel.fromPath(params.alignment)
    align_index = Channel.fromPath(params.align_index)
    reference = Channel.fromPath(params.reference).first()
    reference_index = Channel.fromPath(params.reference_index).first()
    wgs_intervals = Channel.fromPath(params.wgs_intervals).first()
    non_diploid_intervals = Channel.fromPath(params.non_diploid_intervals).first()
    non_diploid_ploidy = params.non_diploid_ploidy
    dnascope_model = params.dnascope_model ? Channel.fromPath(params.dnascope_model) : Channel.value([])
    dbsnp = params.dbsnp ? Channel.fromPath(params.dbsnp) : Channel.value([])
    dbsnp_index = params.dbsnp_index ? Channel.fromPath(params.dbsnp_index) : Channel.value([])
    indexed_alignment = alignment.combine(align_index)
    reference_plus_fai = reference.combine(reference_index)
    dbsnp_combined = dbsnp.combine(dbsnp_index)
    sample_id = params.sample_id ? Channel.value(params.sample_id) : Channel.value([])

    subtracted_intervals = GATK_INTERVALLISTOOLS(
        wgs_intervals,
        non_diploid_intervals,
        'SUBTRACT'
    )
    diploid_vcf = SENTIEON_DNASCOPE_DIPLOID(
        indexed_alignment,
        reference_plus_fai,
        subtracted_intervals,
        2,
        dbsnp_combined,
        dnascope_model
    )
    non_diploid_vcf = SENTIEON_HAPLOTYPER(
        indexed_alignment,
        reference_plus_fai,
        non_diploid_intervals,
        non_diploid_ploidy,
        dbsnp_combined
    )
    merged_gvcf = BCFTOOLS_CONCAT_RENAME(
        diploid_vcf,
        non_diploid_vcf,
        sample_id
    )
    SENTIEON_GVCFTYPER(
        merged_gvcf,
        reference_plus_fai,
        dbsnp_combined
    )
}