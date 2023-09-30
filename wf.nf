#!/usr/bin/env nextflow
params.bioProjectId = 'PRJEB31266'
bioProjectIdChan = Channel.of(params.bioProjectId)

process fetchRunAccesionsForBioProject {
    input:
        val bioProjectId

    output:
        stdout

    script:
    """
    bash $projectDir/wf.sh fetchRunAccesionsForBioProject "$bioProjectId"
    """

}

workflow {
    resChan = fetchRunAccesionsForBioProject(bioProjectIdChan)
    resChan.view { it }
}
