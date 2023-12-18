#!/usr/bin/env nextflow

// Create a commandline parameter for NCBI's BioProject identifier
// with default value as PRJEB31266
params.bioProjectID = 'PRJEB31266'

// Create a commandline parameter for reference sequences fasta file
// with default value as xylo.fna
params.referenceSequences = 'data/xylo.fna'

params.runAccessions = 'data/runAccessions.txt'

process fetchRunAccesionsForBioProject {
    output:
        path 'readAccessions.txt'

    script:
    """
    wf.sh fetchRunAccesionsForBioProject "${params.bioProjectID}" > "readAccessions.txt"
    """
}

process downloadSRAForRunAccession {
    input:
        val runAccession
    output:
        val runAccession
        // path "data/${runAccession}/${runAccession}.sra"

    script:
    """
    wf.sh downloadSRAForRunAccession "$runAccession"
    """
}

process extractFASTQFromSRAFile {
    input:
        val runAccession
    // val sraFilePath
    output:
        // path "pairs/${runAccession}_1.fastq"
        // path "pairs/${runAccession}_2.fastq"

    script:
    """
    # TODO: Don't hardcode mem and threads requirement
    wf.sh extractFASTQFromSRAFile "$runAccession" "5" "12"
    """
}

process alignRunWithBowtie {
    input:
        val runAccession
        val referenceSequences
    // val pairPaths
    output:
        val runAccession
        // path "aln/${runAccession}.sam"

    script:
    """
    wf.sh alignRunWithBowtie "$referenceSequences" "12"
    """
}

workflow {
    // fetchRunAccesionsForBioProject
    Channel
    .fromPath(params.runAccessions)
    .splitText(by: 1)
    .map { it.trim() }
    | downloadSRAForRunAccession
    | extractFASTQFromSRAFile
}
