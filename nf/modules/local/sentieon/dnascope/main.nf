process SENTIEON_DNASCOPE {
    label 'C32'
    container "pgc-images.sbgenomics.com/hdchen/sentieon:202308.03"

    input:
    tuple path(alignment), path(align_index)
    tuple path(reference), path(fai)
    path(interval)
    val(ploidy)
    tuple path(dbsnp), path(dbsnp_index)
    path(dnascope_model_bundle)


    output:
    tuple path('*vcf.gz'), path('*vcf.gz.tbi'), emit: output_vcf
    script:
    def license_export = task.ext.export_args ?: ''
    def dbsnp_flag = dbsnp ? "-d $dbsnp" : ''
    def model_arg = dnascope_model_bundle ? "--model ${dnascope_model_bundle}/dnascope.model" : ''
    def algo_ext_args = task.ext.algo_args ?: ''
    def prefix = task.ext.prefix ?: 'output'
    """
    $license_export \\
    sentieon driver \\
    -i $alignment \\
    -r $reference \\
    --interval $interval \\
    --algo DNAscope \\
    --ploidy $ploidy \\
    $dbsnp_flag \\
    $model_arg \\
    $algo_ext_args \\
    "${prefix}.ploidy_${ploidy}.${params.emit_mode == 'gvcf' ? 'g.vcf.gz' : 'vcf.gz'}"
    """

    stub:
    """
    touch result.vcf.gz
    """
}