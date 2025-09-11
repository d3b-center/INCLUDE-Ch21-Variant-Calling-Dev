process BCFTOOLS_RENAME_SAMPLE {
    label 'C4'
    container 'pgc-images.sbgenomics.com/d3b-bixu/bcftools:1.20'
    // Currently supports a single mid-genome chromosome insertion

    input:
    tuple path("sample_to_rename.vcf.gz"), path("sample_to_rename.vcf.gz.tbi") // generically stage input so output name can stay
    val(output_filename)
    val(sample_name)

    output:
    tuple path("*.vcf.gz"), path("*.vcf.gz.tbi"), emit: reheadered_vcf

    script:
    def create_samp_file = "echo $sample_name > sample_rename.txt;"
    """
    $create_samp_file
    bcftools view --threads 4 sample_to_rename.vcf.gz | \\
    bcftools reheader -s sample_rename.txt | \\
    bcftools view -O z --threads 4 -o $output_filename;
    bcftools index --threads 4 -t $output_filename
    """

    stub:
    """
    touch test.g.vcf.gz
    touch test.g.vcf.gz.tbi
    """
}