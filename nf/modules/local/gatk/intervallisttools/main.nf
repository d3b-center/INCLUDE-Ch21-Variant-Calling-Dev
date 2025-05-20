process GATK_INTERVALLISTOOLS {
    label 'C4'
    container "pgc-images.sbgenomics.com/d3b-bixu/gatk:4.2.0.0R"
    input:
    path(input)
    path(input2)
    val(action)

    output:
    path('*interval_list'), emit: output_intervallist

    script:
    def prefix = task.ext.prefix ?: "${action}"
    """
    /gatk IntervalListTools \\
    -I $input \\
    --SECOND_INPUT $input2 \\
    --ACTION $action \\
    -O ${prefix}.interval_list

    """

    stub:
    """
    touch result.interval_list
    """
}