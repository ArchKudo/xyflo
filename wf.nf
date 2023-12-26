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
    publishDir "$projectDir/data/"
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
        tuple val("${runAccession}"), path("aln/${runAccession}.sam")

    script:
    """
    mkdir -p aln/
    wf.sh alignRunWithBowtie "$runAccession" "$pair_1" "$pair_2" "$referenceSequences/$referenceSequencesName" "12"
    """
}

workflow {
    index = buildBowtieIndexFromFASTA(Channel.fromPath(params.referenceSequences))
            // | map { it.join('/') }
            | view
    println index.getClass()

    align = fetchRunAccesionsForBioProject
            | map { it.readLines() }
            | flatten
            | take(3)
            // | view
            | downloadSRAForRunAccession
            // | view
            | extractFASTQFromSRAFile
            // | view
            | combine(index)
            | alignRunWithBowtie
            | view
}
