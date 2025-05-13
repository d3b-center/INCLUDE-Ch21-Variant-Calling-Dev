process GATK_INTERVALLISTOOLS {
    label 'C4'
    container "broadinstitute/gatk:4.4.0.0"
    input:
    path(input)
    val(action)

    output:
    path('*interval_list'), emit: output_intervallist

    script:
    def ext_args = task.ext.args ?: ''
    """
    gatk IntervalListTools \\
    -I $input \\
    --ACTION $action \\
    $ext_args

    """

    stub:
    """
    touch result.interval_list
    """
}