#!/usr/bin/env nextflow

include { SENTIEON_DNASCOPE } from './modules/local/sentieon/dnascope/main'
include { SENTIEON_DNASCOPE as SENTIEON_DNASCOPE_DIPLOID } from './modules/local/sentieon/dnascope/main'
include { GATK_INTERVALLISTOOLS } from './modules/local/gatk/intervallisttools/main'
include { PICARD_MERGEVCFS } from './modules/local/picard/mergevcfs/main'
include { SENTIEON_GVCFTYPER } from './modules/local/sentieon/gvcftyper/main.nf'

workflow {
    main:
    alignment = params.alignment ? Channel.fromPath(params.alignment) : Channel.value()
    align_index = params.align_index ? Channel.fromPath(params.align_index) : Channel.value()
    reference = Channel.fromPath(params.reference).first()
    reference_index = Channel.fromPath(params.reference_index).first()
    wgs_intervals = Channel.fromPath(params.wgs_intervals).first()
    non_diploid_intervals = Channel.fromPath(params.non_diploid_intervals).first()
    non_diploid_ploidy = params.non_diploid_ploidy
    indexed_alignment = alignment.combine(align_index)
    reference_fai = reference.combine(reference_index)

    subtracted_intervals = GATK_INTERVALLISTOOLS(
        wgs_intervals,
        'SUBTRACT'
    )
    diploid_vcf = SENTIEON_DNASCOPE_DIPLOID(
        indexed_alignment,
        reference_fai,
        subtracted_intervals,
        2
    )
    non_diploid_vcf = SENTIEON_DNASCOPE(
        indexed_alignment,
        reference_fai,
        non_diploid_intervals,
        non_diploid_ploidy
    )
    merged_gvcf = PICARD_MERGEVCFS(
        diploid_vcf,
        non_diploid_vcf
    )

    gt_vcf = SENTIEON_GVCFTYPER(
        merged_gvcf,
        reference_fai,
    )
}