# Pipeline description

This is a Nextflow pipeline to compare mapping performance of pairs of unaligned `.bam` files from Oxford Nanopore sequencing. In this case, it is being used to evaluate the extent of barcode crossover before and after a protocol change by determining how reads map to references from several different species on the same sequencing run.

## Running the pipeline

All processes have associated Docker images. If you have Nextflow and Docker (or another Docker-compatible container engine supported by Nextflow) installed, you don't need to install additional software and you can simply run `nextflow run main.nf -with-docker`. If you don't want to use Docker, you must have ONT Dorado, Samtools, and R (with tidyverse packages) in your path.

An example `nextflow.config` file is provided that enables Docker and gives paths to example samplesheets.

## Processes

The pipeline performs three processes.

1. It aligns each unaligned `.bam` against each reference `.fasta` with `dorado align` from ONT.
1. It computes alignment metrics with `samtools flagstat`.
1. It compiles `flagstat` metrics and plots the percentage of primary mapped reads with a custom R script and ggplot2 (`bin/plot.R`).

## Inputs

The pipeline expects two samplesheets.

### Samples

The first samplesheet describes which samples will be compared. The path to this samplesheet is given by `params.samples`.

There are three columns.

1. `name` is a sample name used in output files and reports.
1. `before` is a path to an unaligned `.bam` file.
1.  `after` is a path to an unaligned `.bam` file that will be compared to the `before` file.

```csv
name,before,after
Zymo-D5405,bc_zymo_3a.bam,bc_zymo_1b.bam
Lorem_ipsum,lipsum_before.bam,lipsum_after.bam
```

### References

The second samplesheet describes which references the samples will be aligned to. The path to this samplesheet is given by `params.references`.

There are two columns.

1. `name` if a reference name used in output files and repots.
1. `path` is a path to the reference `.fasta` file.

```csv
name,path
D5405,D5405.fa
Homo_sapiens,homo_sapiens-001.fa
lambda,lambda.fa
Oryza_sativa,oryza_sativa.fa
```

## Outputs

The pipeline creates a directory called `output/` with one subdirectory for each of the processes.

1. `align/` contains `*.aligned.bam` files output by `dorado align`.
1. `flagstat/` contains `*.flagstat.txt` files output by `samtools flagstat`.
1. `plot/` contains `results.csv`, which compiles the before and after metrics from `samtools flagstat`. It also contains one `.png` file per sample that plots the percentage of primary mapped

## Parameters

The pipeline expects three parameters.

1. `params.samples` is the path to the samples samplesheet.
1. `params.references` is the path to the references samplesheet.
1. `params.expected_reference` is the name of the reference that the samples are expected to map to. This name should match the name given in the references samplesheet. This reference is omitted from the output plot.

# Analysis results

The `samtools flagstat` and plotting results can be seen in the `output` folder.

Before the protocol change, 0.36% of reads primarily mapped to non-target references. After the protocol change, this decreased to 0.07% of reads, which can be seen in the plot. This suggests that barcode crossover is indeed reduced with the new protocol.

![output plot](https://github.com/paytoncarter14/renew-bfx-tech-interview/blob/0a905a9ff7add05f3dbd92981e74efa343401852/output/plot/Zymo-D5405.png)

However, this decrease (0.29% fewer reads mapping to non-target references) is minor compared to the increase in the percentage of reads mapping to the target D5405 reference (6.87%). While the protocol change did seem to reduce barcode crossover, perhaps the more significant finding is that it substantially improved mapping performance to the target reference.

|reference|state|primary_reads|primary_mapped_reads|pct_primary_mapped|
|---|---|---|---|---|
D5405|after|100218|98794|98.58|
D5405|before|99945|91656|91.71|
Homo_sapiens|after|100218|18|0.02|
Homo_sapiens|before|99945|205|0.21|
lambda|after|100218|7|0.01|
lambda|before|99945|40|0.04|
Oryza_sativa|after|100218|39|0.04|
Oryza_sativa|before|99945|109|0.11|
