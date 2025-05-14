process SENTIEON_GVCFTYPER {
    label 'C32'
    container "pgc-images.sbgenomics.com/hdchen/sentieon:202308.03"

    input:
    tuple path(gvcf), path(gvcf_index)
    tuple path(reference), path(fai)
    tuple path(dbsnp), path(dbsnp_index)

    output:
    path('*vcf.gz'), emit: output_vcf
    path('*vcf.gz.tbi'), emit: output_vcf_index

    script:
    def license_export = task.ext.export_args ?: ''
    def algo_ext_args = task.ext.algo_args ?: ''
    """
    $license_export \\
    sentieon driver \\
    -r $reference \\
    --algo GVCFtyper \\
    -v $gvcf \\
    ${params.dbsnp ? '-d $dbsnp' : ''} \\
    $algo_ext_args
    """

    stub:
    """
    touch result.vcf.gz
    """
}