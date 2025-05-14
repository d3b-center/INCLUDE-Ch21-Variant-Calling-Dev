process PICARD_MERGEVCFS {
    label 'C4'
    container "pgc-images.sbgenomics.com/d3b-bixu/picard:2.18.9R"
    input:
    tuple path(vcf1), path(vcf1_index)
    tuple path(vcf2), path(vcf2_index)

    output:
    tuple path('*.vcf.gz'), path('*.vcf.gz.tbi'), emit: merged_vcf

    script:
    def ext_args = task.ext.args ?: ''
    """
    java -Xms2000m -jar /picard.jar MergeVcfs \\
    INPUT=$vcf1 \\
    INPUT=$vcf2 \\
    OUTPUT=/dev/stdout \\
    CREATE_INDEX=false \\
    $ext_args

    """

    stub:
    """
    touch result.vcf.gz
    touch result.vcf.gz.tbi
    """
}