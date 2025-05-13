process SENTIEON_DNASCOPE {
    label 'C8'
    container "pgc-images.sbgenomics.com/hdchen/sentieon:202308.03"

    input:
    tuple path(alignment), path(align_index)
    tuple path(reference), path(fai)
    path(interval)
    val(ploidy)

    output:
    path('*vcf.gz'), emit: output_vcf

    script:
    def license_export = task.ext.export_args ?: ''
    def algo_ext_args = task.ext.algo_args ?: ''
    """
    $license_export \\
    sentieon driver \\
    -i $alignment \\
    -r $reference \\
    --interval $interval \\
    --algo DNAscope \\
    --ploidy $ploidy \\
    $algo_ext_args
    """

    stub:
    """
    touch result.vcf.gz
    """
}