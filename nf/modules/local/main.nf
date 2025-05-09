process SENTIEON_DNASCOPE {
    container "pgc-images.sbgenomics.com/hdchen/sentieon:202308.03"

    input:
    tuple path(alignment), path(align_index)
    path(reference)

    output:
    path('*vcf.gz'), emit: output_vcf

    script:
    def dnascope_ext_args = task.ext.args ?: ''
    """
    sentieon driver --algo DNAscope \\
    -i $alignment \\
    -r $reference \\
    $dnascope_ext_args
    """

}