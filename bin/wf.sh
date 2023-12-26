#!/usr/bin/bash

function fetchRunAccesionsForBioProject {
    # Fetch run accessions using efetch from Entrez Direct
    
    # Set the email address for NCBI Entrez Direct
    export ENTREZ_EMAIL=gdv1@aber.ac.uk
    
    # Search the bioproject on SRA
    esearch -db sra -query "$1" | \
    
    # Get the runs in csv format?
    efetch -format runinfo | \
    
    # Remove the header line
    tail -n +2 | \
    
    # Get the first column from a comma delimited file
    # -d for specifying delimiter
    # -f for specifying column
    cut -d ',' -f 1
}

function buildBowtieIndexFromFASTA {
    # Build a bowtie index with arguments
    bowtie2-build "$1" "$2"
}

function downloadSRAForRunAccession {
    # Download compressed SRA files
    # Requires 1 argument:
    # $1[String] = Run accession number
    # The max-size of 50GB is greater than the default limit not less
    prefetch "$1" --output-directory data/ \
    --verbose --progress --max-size 50G \
    --resume yes -L debug
}

function extractFASTQFromSRAFile {
    # Extract FASTQ for SRA file
    # Does not check if the pairs already exist
    # Does not check if sufficient number of pairs present
    # Requires 3 arguments:
    # $1[String] = Run accession number
    # $2[Number] = Max memory / 1000 available to fastq command
    # $3[Number] = Number of threads to use
    fasterq-dump "$1" --outdir pairs/ --temp tmp/ \
    --bufsize "${2}0MB" --curcache "${2}00MB" --mem "${2}000MB" --threads "$3" \
    --progress --verbose --details --log-level debug
}

function alignRunWithBowtie {
    # Run bowtie with following arguments
    # $1 = Name of aligned sam file
    # $2 = Name of pair_1
    # $3 = Name of pair_2
    # $4 = Name of reference sequence index file
    # $5 = Number of threads
    bowtie2 \
    -1 "$2" -2 "$3" -S aln/"$1".sam \
    -x "$4" \
    --threads "$5" --time \
    -q --phred33 --local --very-sensitive-local --no-unal \
    -N 1 -L 12 --rfg 5,2
    
}

# Stolen: https://stackoverflow.com/questions/8818119
# Check if the function exists (bash specific)
if declare -f "$1" > /dev/null
then
    # call arguments verbatim
    "$@"
else
    # Show a helpful error
    echo "'$1' is not a known function name" >&2
    exit 1
fi
