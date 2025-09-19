process SENTIEON_GVCFTYPER {
    label 'C32'
    container "pgc-images.sbgenomics.com/hdchen/sentieon:202308.03"

    input:
    tuple path(gvcf), path(gvcf_index)
    tuple path(reference), path(fai)
    tuple path(dbsnp), path(dbsnp_index)
    val(output_filename)

    output:
    tuple path('*vcf.gz'), path('*vcf.gz.tbi'), emit: output_vcf

    script:
    def license_export = task.ext.export_args ?: ''
    def dbsnp_flag = dbsnp ? "-d $dbsnp" : ''
    def algo_ext_args = task.ext.algo_args ?: ''
    """
    $license_export \\
    sentieon driver \\
    -r $reference \\
    --algo GVCFtyper \\
    -v $gvcf \\
    $dbsnp_flag \\
    $algo_ext_args \\
    $output_filename
    """

    stub:
    """
    touch result.vcf.gz
    """
}