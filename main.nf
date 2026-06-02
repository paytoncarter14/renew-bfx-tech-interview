// Path to .csv of samples to align.
// Header is `name,before,after`.
// `name` is a sample name used in reporting.
// `before` and `after` are paths to the unaligned .bam files.
params.samples = ''

// Path to .csv of references to align to.
// Header is `name,path`.
// `name` is a reference name used in reporting.
// `path` is the path to the reference .fasta file.
params.references = ''

// This is the name of the reference, given in the params.references file,
// that the sample is expected to map to.
// This is used in the plotting process.
params.expected_reference = ''

process ALIGN {

    // Align unaligned .bam files against a reference .fasta

    container 'nanoporetech/dorado:sha38b4ce849afa13eac8075f0b41cecd30799f169b'
    publishDir 'output/align'

    input: tuple val(sample_name),
        path(sample_path),
        val(reference_name),
        path(reference_path),
        val(state)
    output: path("*.aligned.bam"), emit: aligned

    script:
    """
    dorado aligner ${reference_path} ${sample_path} \
        > ${sample_name}__${state}__${reference_name}.aligned.bam
    """
}

process FLAGSTAT {

    // Compute alignment metrics on aligned .bam files

    container 'staphb/samtools:1.23.1'
    publishDir 'output/flagstat'

    input: path(bam)
    output: path("*.flagstat.txt"), emit: txt

    script:
    """
    samtools flagstat -O tsv ${bam} > ${bam.baseName}.flagstat.txt
    """
}

process PLOT {

    // Plot percent primary mapped reads
    // to compare before/after for each reference

    container 'rocker/tidyverse:4.6.0'
    publishDir 'output/plot'

    input: path(flagstat)
    output: tuple path("*.png"), path("*.csv")

    script:
    """
    plot.R ${params.expected_reference}
    """
}

workflow {

    // Prepare the channels to align each before and after file
    // against each reference.
    // End up with 2 [number of samples] * [number of references] emissions.

    samples_ch = channel
        .fromPath(params.samples)
        .flatMap{csv -> csv.splitCsv(header: true)}
        .flatMap{row -> [
            [
                sample_name: row.name,
                state: 'before',
                sample_path: file(row.before)
            ],
            [
                sample_name: row.name,
                state: 'after',
                sample_path: file(row.after)
            ]
        ]}

    references_ch = channel
        .fromPath(params.references)
        .flatMap{csv -> csv.splitCsv(header: true)}
        .map{row -> [reference_name: row.name, reference_path: file(row.path)]}

    combined_ch = samples_ch
    .combine(references_ch)
    .map{sample, ref -> sample + ref}

    ALIGN(combined_ch.map{
        it -> [
            it.sample_name,
            it.sample_path,
            it.reference_name,
            it.reference_path,
            it.state
        ]
    })
    FLAGSTAT(ALIGN.out.aligned)
    PLOT(FLAGSTAT.out.txt.collect())

}