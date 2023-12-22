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

process alignRunWithBowtie {
    input:
        tuple val(runAccession), path(referenceSequences), path(pair_1), path(pair_2)
    output:
        tuple val("${runAccession}"), path("aln/${runAccession}.sam")

    script:
    """
    wf.sh alignRunWithBowtie "$referenceSequences" "12"
    """
}

workflow {
    s = fetchRunAccesionsForBioProject
        | map { it.readLines() }
        | flatten
        | view
        | downloadSRAForRunAccession
        | view
        | extractFASTQFromSRAFile
}
