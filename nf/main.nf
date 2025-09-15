#!/usr/bin/env nextflow

include { SENTIEON_DNASCOPE as SENTIEON_DNASCOPE_DIPLOID } from './modules/local/sentieon/dnascope/main'
include { SENTIEON_HAPLOTYPER } from './modules/local/sentieon/haplotyper/main'
include { GATK_INTERVALLISTOOLS } from './modules/local/gatk/intervallisttools/main'
include { BCFTOOLS_RENAME_SAMPLE } from './modules/local/bcftools/rename_sample/main.nf'
include { BCFTOOLS_RENAME_SAMPLE as BCFTOOLS_RENAME_SAMPLE_DIPLOID } from './modules/local/bcftools/rename_sample/main.nf'
include { SENTIEON_GVCFTYPER as SENTIEON_GVCFTYPER_DIPLOID } from './modules/local/sentieon/gvcftyper/main.nf'
include { SENTIEON_GVCFTYPER } from './modules/local/sentieon/gvcftyper/main.nf'

workflow {
    main:
    alignment = Channel.fromPath(params.alignment)
    align_index = Channel.fromPath(params.align_index)
    reference = Channel.fromPath(params.reference).first()
    reference_index = Channel.fromPath(params.reference_index).first()
    wgs_intervals = Channel.fromPath(params.wgs_intervals).first()
    non_diploid_intervals = params.non_diploid_intervals ? Channel.fromPath(params.non_diploid_intervals).first() : ""
    non_diploid_ploidy = params.non_diploid_ploidy
    dnascope_model_bundle = params.dnascope_model_bundle ? Channel.fromPath(params.dnascope_model_bundle) : Channel.value([])
    dbsnp = params.dbsnp ? Channel.fromPath(params.dbsnp) : Channel.value([])
    dbsnp_index = params.dbsnp_index ? Channel.fromPath(params.dbsnp_index) : Channel.value([])
    indexed_alignment = alignment.combine(align_index)
    reference_plus_fai = reference.combine(reference_index)
    dbsnp_combined = dbsnp.combine(dbsnp_index)
    sample_id = params.sample_id ? Channel.value(params.sample_id) : ""

    diplioid_intervals = non_diploid_intervals ? GATK_INTERVALLISTOOLS(
        wgs_intervals,
        non_diploid_intervals,
        'SUBTRACT'
    ) : wgs_intervals
    diploid_vcf = SENTIEON_DNASCOPE_DIPLOID(
        indexed_alignment,
        reference_plus_fai,
        diplioid_intervals,
        2,
        dbsnp_combined,
        dnascope_model_bundle
    )
    if (sample_id) {
        fname = diploid_vcf.map { vcf, _idx -> vcf.name }
        diploid_vcf = BCFTOOLS_RENAME_SAMPLE_DIPLOID(
            diploid_vcf,
            fname,
            sample_id
        )
    }
    if (non_diploid_intervals){
        non_diploid_vcf = SENTIEON_HAPLOTYPER(
            indexed_alignment,
            reference_plus_fai,
            non_diploid_intervals,
            non_diploid_ploidy,
            dbsnp_combined
        )
    }
    if (sample_id && non_diploid_intervals) {
        fname = non_diploid_vcf.map { vcf, _idx -> vcf.name }
        non_diploid_vcf = BCFTOOLS_RENAME_SAMPLE(
            non_diploid_vcf,
            fname,
            sample_id
        )
    }
    // add either here or in tool the output filename
    diploid_output_fname = params.output_basename ? "${params.output_basename}.dnascope.vcf.gz" : "genotyped.dnascope.vcf.gz"
    SENTIEON_GVCFTYPER_DIPLOID(
        diploid_vcf,
        reference_plus_fai,
        dbsnp_combined,
        diploid_output_fname
    )
    if (non_diploid_intervals){
        non_diploid_output_fname = params.output_basename ? "${params.output_basename}.haplotyper.vcf.gz" : "genotyped.haplotyper.vcf.gz"
        SENTIEON_GVCFTYPER(
            non_diploid_vcf,
            reference_plus_fai,
            dbsnp_combined,
            non_diploid_output_fname
        )
    }
}