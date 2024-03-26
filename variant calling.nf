params {
    input = file('SRR1634077.fastq')  // Input single FASTQ file
}

workflow {
    // Step 1: Trimming with FASTP
    process trim_reads {
        input:
        file(input) from input

        output:
        file 'trimmed_reads.fastq' into fastqc

        script:
        """
        fastp --in $input --out trimmed_reads.fastq --json trimmed_reads.json --html trimmed_reads.html
        """
    }

    // Step 2: Quality control with FASTQC
    process fastqc {
        input:
        file 'trimmed_reads.fastq' from trim_reads

        script:
        """
        fastqc trimmed_reads.fastq
        """
    }

    // Step 3: BWA alignment
    process bwa_align {
        input:
        file 'trimmed_reads.fastq' from trim_reads

        output:
        file 'aligned_reads.bam' into mosdepth

        script:
        """
        bwa mem reference_genome.fa trimmed_reads.fastq | samtools view -b - > aligned_reads.bam
        """
    }

    // Step 4: Calculate coverage with Mosdepth
    process mosdepth {
        input:
        file 'aligned_reads.bam' from bwa_align

        script:
        """
        mosdepth coverage output_directory aligned_reads.bam
        """
    }

    // Step 5: Variant calling with ASCAT
    process ascat_variant_calling {
        input:
        file 'aligned_reads.bam' from bwa_align

        script:
        """
        ascat --bam aligned_reads.bam --ref reference_genome.fa --output ascat_results
        """
    }
}
