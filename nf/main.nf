#!/usr/bin/env nextflow

include { SENTIEON_DNASCOPE } from './modules/local/sentieon/dnascope/main'
include { SENTIEON_DNASCOPE as SENTIEON_DNASCOPE_DIPLOID } from './modules/local/sentieon/dnascope/main'
include { GATK_INTERVALLISTOOLS } from './modules/local/gatk/intervallisttools/main'

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
    diploid_vcf.view()
    non_diploid_vcf.view()
}