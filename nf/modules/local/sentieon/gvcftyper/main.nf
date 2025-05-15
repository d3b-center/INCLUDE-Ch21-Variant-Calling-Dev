process SENTIEON_GVCFTYPER {
    label 'C8'
    container "pgc-images.sbgenomics.com/hdchen/sentieon:202308.03"

    input:
    tuple path(gvcf), path(gvcf_index)
    tuple path(reference), path(fai)
    tuple path(dbsnp), path(dbsnp_index)

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
    $algo_ext_args
    """

    stub:
    """
    touch result.vcf.gz
    """
}