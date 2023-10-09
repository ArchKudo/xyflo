# xyflo

A nextflow pipeline for finding enzymes in metagenomes

## Require Dependencies

Install Nextflow

```sh
curl -s https://get.nextflow.io | bash
```

Install nf-test

```sh
curl -fsSL https://code.askimed.com/install/nf-test | bash
```

## Usage

```sh
nextflow run wf.nf --bioProjectId PRJNA732531 -resume
nf-test test tests/wf.nf.test
```

## Design Notes

- Current comfort level : Poor
    - Groovy: Poor
    - Nextflow: Poor
    - Bash: Ok
    - WF: Ok
    - Docker: Poor
    - Help from ChatGPT: Poor
    - Language Server: Poor
    
- [ ] Download fastq file using https://github.com/nf-core/fetchngs ?
    - [ ] How to use it from my pipeline instead of using it from commandline?
- [ ] Manage files in bash or nextflow?
- [ ] Poor commenting in bash
