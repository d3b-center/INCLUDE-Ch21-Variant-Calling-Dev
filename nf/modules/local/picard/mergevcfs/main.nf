process PICARD_MERGEVCFS {
    label 'C2'
    container 'pgc-images.sbgenomics.com/d3b-bixu/picard:2.18.9R'

    input:
    path(input_vcfs)
    path(input_vcf_indexes)
    val(biospecimen_name)

    output:
    tuple path("*.g.vcf.gz"), path("*.g.vcf.gz.tbi"), emit: merged_vcf

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "merged.g.vcf.gz"
    def inputs_command = input_vcfs.collect{"INPUT=$it"}.join(' ')
    def optional_rename = biospecimen_name ? "| /VcfSampleRename.py $biospecimen_name" : ''
    """
    java -Xmx${(task.memory.mega*0.8).intValue()}M -jar /picard.jar \\
        MergeVcfs \\
        $inputs_command \\
        OUTPUT=/dev/stdout \\
        CREATE_INDEX=false \\
    $optional_rename \\
    | bgzip \\
        -c \\
        -@ 4 \\
        > ${prefix}.g.vcf.gz \\
    && tabix \\
        -p vcf \\
        ${prefix}.g.vcf.gz
    """

    stub:
    """
    touch test.g.vcf.gz
    touch test.g.vcf.gz.tbi
    """
}