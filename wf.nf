#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

// Create a commandline parameter for NCBI's BioProject identifier
// with default value as PRJNA1005421
params.bioProjectID = 'PRJNA1005421'

// Create a commandline parameter for reference sequences fasta file
// with default value as xylo.fna
params.referenceSequences = 'data/xylo.fna'

process fetchRunAccesionsForBioProject {
    output:
        path 'runAccessions.txt'

    script:
    """
    wf.sh fetchRunAccesionsForBioProject "${params.bioProjectID}" > "runAccessions.txt"
    """
}

process downloadSRAForRunAccession {
    input:
        val runAccession
    output:
        tuple val("${runAccession}"), path("data/${runAccession}/${runAccession}.sra")
    script:
    """
    wf.sh downloadSRAForRunAccession "$runAccession"
    """
}

process extractFASTQFromSRAFile {
    input:
        tuple val(runAccession), val(sraFilePath)
    output:
        tuple val("${runAccession}"),
        path("pairs/${runAccession}_1.fastq"),
        path("pairs/${runAccession}_2.fastq")

    script:
    """
    # TODO: Don't hardcode mem and threads requirement
    wf.sh extractFASTQFromSRAFile "$sraFilePath" "5" "12"
    """
}

process buildBowtieIndexFromFASTA {
    input:
        path referenceSequencesFASTA
    output:
        tuple path('db'), val("$name")
    script:
        name = "$referenceSequencesFASTA.fileName.name"
        """
        mkdir -p db/
        wf.sh buildBowtieIndexFromFASTA "$referenceSequencesFASTA" "db/$name" --threads 12
        """
}

process alignRunWithBowtie {
    input:
        // TODO: Use https://www.nextflow.io/docs/latest/process.html#dynamic-input-file-names
        tuple val(runAccession), path(pair_1), path(pair_2), path(referenceSequences), val(referenceSequencesName)
    output:
        path("aln/${runAccession}.sam")

    script:
    """
    mkdir -p aln/
    wf.sh alignRunWithBowtie "$runAccession" "$pair_1" "$pair_2" "$referenceSequences/$referenceSequencesName" "12"
    """
}

process mergeSAMFiles {
    input:
        path(alignedSAMFile)
    output:
        path('merged.sam')
    script:
    args = alignedSAMFile.collect { "-I $it" }.join(' ')
    """
    picard MergeSamFiles $args -O "merged.sam"
    """
}

process convertSAMToBAM {
    input:
        path(mergedSAMFile)
    output:
        path('merged.bam')
    script:
    """
    samtools view -@ 16 --verbosity 100 -b "$mergedSAMFile" -o "merged.bam"
    """
}

process sortBAMFile {
    input:
        path(mergedBAMFile)
    output:
        path('sorted.bam')
    script:
    """
    samtools sort -m 512M --threads 16 --verbosity 100 -o sorted.bam "$mergedBAMFile"
    """
}

process deduplicateBAMFile {
    input:
        path(sortedBAMFile)
    output:
        path('dedup.sam')
    script:
    """
    picard.jar MarkDuplicates INPUT="$sortedBAMFile" OUTPUT=dedup.bam METRICS_FILE=dedup.metrics
    """
}

process createBAMIndexFile {
    input:
        path(bamFile)
    output:
        tuple path(bamFile), path("${bamFile}.bai")
    script:
    """
    samtools index "$bamFile"
    """
}

process pileUpAndVariantCallBAM {
    input:
        tuple path(referenceSequence), path(targetBAMFile)
    output:
        path('calls.vcf')
    script:
    """
    bcftools mpileup -Ou --threads 12 -f "$referenceSequence" "$targetBAMFile" | \
    bcftools call --threads 12 -mv -Oz -o calls.vcf
    """
}

process recoverHaplotypes {
    errorStrategy 'ignore'
    input:
        tuple path(bamFile), path(bamFileIndex), path(referenceSequence)
    output:
        path('out.fasta')
    script:
    """
    wf.sh recoverHaplotypes "$bamFile" "$referenceSequence" "$projectDir/bin/snpper.py"
    """
}

workflow {
    seqChan = Channel.fromPath(params.referenceSequences)
    index = buildBowtieIndexFromFASTA(seqChan)
    wf = fetchRunAccesionsForBioProject
        | map { it.readLines() }
        | flatten
        | take(3)
        | downloadSRAForRunAccession
        | extractFASTQFromSRAFile
        | combine(index)
        | alignRunWithBowtie
        | flatten
        | toList
        | mergeSAMFiles
        | convertSAMToBAM
        | createBAMIndexFile
        | combine(seqChan)
        // | flatten
        | recoverHaplotypes
        | view

    // Use snpper instead
    // variant = pileUpAndVariantCallBAM(Channel.fromPath(params.referenceSequences).combine(align.first()))
    // variant | view
}
