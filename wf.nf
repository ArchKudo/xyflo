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

workflow {
    s = fetchRunAccesionsForBioProject
        | map { it.readLines() }
        | flatten
        | view
        | downloadSRAForRunAccession
        | view
}
