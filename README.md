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

### Interface

- Commandline Parameters

- BioProjectID: String[]
- ReferenceSequence: String
- 
