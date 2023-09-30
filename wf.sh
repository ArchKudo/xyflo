#!/usr/bin/bash

function fetchRunAccesionsForBioProject {
    # Set the email address for NCBI Entrez Direct
    export ENTREZ_EMAIL=gdv1@aber.ac.uk
    
    # Fetch run accessions using efetch from Entrez Direct
    
    # Search the bioproject on SRA
    esearch -db sra -query "$1" | \
    
    # Get the runs in csv format?
    efetch -format runinfo | \
    
    # Get the first column from a comma delimited file
    # -d for specifying delimiter
    # -f for specifying column
    cut -d ',' -f 1 |tee "read_accesions.$1"
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
