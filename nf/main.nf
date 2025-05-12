#!/usr/bin/env nextflow

include { SENTIEON_DNASCOPE } from './modules/local/main'

workflow {
    main:
    alignment = params.alignment ? Channel.fromPath(params.alignment) : Channel.value()
    align_index = params.align_index ? Channel.fromPath(params.align_index) : Channel.value()
    reference = Channel.fromPath(params.reference).first()
    reference_index = Channel.fromPath(params.reference_index).first()
    indexed_alignment = alignment.combine(align_index)
    reference_fai = reference.combine(reference_index)


    output_vcf = SENTIEON_DNASCOPE(
        indexed_alignment,
        reference: reference_fai,
    )

    output_vcf.view()
}