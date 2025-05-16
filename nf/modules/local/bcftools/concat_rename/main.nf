process BCFTOOLS_CONCAT_RENAME {
    label 'C4'
    container 'pgc-images.sbgenomics.com/d3b-bixu/bcftools:1.20'
    // Currently supports a single mid-genome chromosome insertion

    input:
    tuple path(vcf1), path(vcf1_index)
    tuple path(vcf2), path(vcf2_index)
    val(sample_name)

    output:
    tuple path("*.g.vcf.gz"), path("*.g.vcf.gz.tbi"), emit: merged_vcf

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "merged.g.vcf.gz"
    def create_samp_file = sample_name ? "echo $sample_name > sample_rename.txt &&" : ''
    def rename_cmd = sample_name ? "bcftools reheader -s sample_rename.txt |" : ''
    """
    $create_samp_file \\
    tabix -l $vcf1 > vcf1_chr.txt && \\
    tabix -l $vcf2 > vcf2_chr.txt && \\
    sort -V vcf1_chr.txt vcf2_chr.txt > chr_order.txt && \\
    single_line=\$(grep -n \$(tabix -l $vcf2) chr_order.txt | cut -f 1 -d ":") && \\
    total_chr=\$(wc -l chr_order.txt | cut -f 1 -d " ") && \\
    region_list1=\$(head -n \$((single_line-1)) chr_order.txt | tr "\n" ",") && \\
    region_list2=\$(tail -n \$((total_chr - single_line)) chr_order.txt | tr "\n" ",") && \\
    cat  <(bcftools view --threads 4 -r \$region_list1 $vcf1) <(bcftools view --threads 4 -H $vcf2) <(bcftools view --threads 4 -H -r \$region_list2 $vcf1) | \\
    $rename_cmd \\
    bcftools view -O z --threads 4 -o ${prefix}.g.vcf.gz &&
    bcftools index --threads 4 -t ${prefix}.g.vcf.gz
    """

    stub:
    """
    touch test.g.vcf.gz
    touch test.g.vcf.gz.tbi
    """
}