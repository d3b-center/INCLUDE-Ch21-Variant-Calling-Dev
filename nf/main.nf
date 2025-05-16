#!/usr/bin/env nextflow

include { SENTIEON_DNASCOPE } from './modules/local/sentieon/dnascope/main'
include { SENTIEON_DNASCOPE as SENTIEON_DNASCOPE_DIPLOID } from './modules/local/sentieon/dnascope/main'
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
        dbsnp_combined
    )
    non_diploid_vcf = SENTIEON_DNASCOPE(
        indexed_alignment,
        reference_plus_fai,
        non_diploid_intervals,
        non_diploid_ploidy,
        dbsnp_combined
    )
    // vcfs_to_merge = diploid_vcf.map { it[0] }.combine(non_diploid_vcf.map { it[0] })
    // vcf_indexes_to_merge = diploid_vcf.map { it[1] }.combine(non_diploid_vcf.map { it[1] })
    // merged_gvcf = PICARD_MERGEVCFS(
    //     vcfs_to_merge,
    //     vcf_indexes_to_merge,
    //     sample_id
        
    // )
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