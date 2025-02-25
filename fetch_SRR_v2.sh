#!/bin/bash

FETCH_METADATA=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --debug)
            set -x
            shift
            ;;
        --metadata)
            FETCH_METADATA=true
            shift
            ;;
        *)
            SRR_LIST_FILE=$1
            shift
            ;;
    esac
done

ARIA2C_COMMANDS_FILE="aria2c_commands.txt"
METADATA_FILE="metadata.txt"
# MAX_PARALLEL=4  

> $ARIA2C_COMMANDS_FILE
> $METADATA_FILE



fetch_info() {
    local SRR=$1

    echo "Processing SRR: $SRR"

    echo "Fetching download links from EBI..."
    API_RESPONSE=$(curl -s --compressed --max-time 30 --retry 3 --retry-delay 2 \
        "https://www.ebi.ac.uk/ena/portal/api/filereport?result=read_run&fields=study_accession,sample_accession,experiment_accession,run_accession,tax_id,scientific_name,fastq_ftp,submitted_ftp,sra_ftp,fastq_md5,submitted_md5,sra_md5,sample_alias,sample_title,instrument_platform,instrument_model,library_layout,library_strategy,library_source,library_selection,read_count,base_count,experiment_title,study_title,submission_accession,center_name,first_public,last_updated&format=JSON&accession=$SRR")
    ALL_DATA=$(echo "$API_RESPONSE" | jq -r '.[]| [
        .study_accession, 
        .sample_accession,
        .experiment_accession,
        .run_accession,
        .tax_id,
        .scientific_name,
        .fastq_ftp,
        .submitted_ftp,
        .sra_ftp,
        .fastq_md5,
        .submitted_md5,
        .sra_md5,
        .sample_alias,
        .sample_title,
        .instrument_platform,
        .instrument_model,
        .library_layout,
        .library_strategy,
        .library_source,
        .library_selection,
        .read_count,
        .base_count,
        .experiment_title,
        .study_title,
        .submission_accession,
        .center_name,
        .first_public,
        .last_updated
        ] | @tsv')
    DOWNLOAD_LINKS=$(echo "$API_RESPONSE" | jq -r '.[] | .fastq_ftp' | tr ';' '\n')
    SAMPLE_ALIAS=$(echo "$API_RESPONSE" | jq -r '.[] | .sample_alias')

    echo "$ALL_DATA" >> "$METADATA_FILE"
    echo "$ALL_DATA" | cut -f 1,4,13,14,17

    RUN_ACCESSION=$(echo "$API_RESPONSE" | jq -r '.[].run_accession')
    RUN_ACCESSION=$(echo "$API_RESPONSE" | jq -r '.[].run_accession')


    
    echo "----------------------------------------"
}


while IFS= read -r line; do
  fetch_info "$line" 
#   while [ "$(jobs -r -p | wc -l)" -ge "$MAX_PARALLEL" ]; do
#     sleep 1
#   done
done < "$SRR_LIST_FILE"

wait

set +x

echo "Creating aria2c commands from metadata..."
while IFS=$'\t' read -r study_accession sample_accession experiment_accession run_accession tax_id scientific_name fastq_ftp submitted_ftp sra_ftp fastq_md5 sra_md5 sample_alias sample_title instrument_platform instrument_model library_layout library_strategy library_source library_selection read_count base_count experiment_title study_title submission_accession center_name first_public last_updated; do
    IFS=';' read -ra URLS <<< "$fastq_ftp"
    for i in "${!URLS[@]}"; do
        URL="https://${URLS[$i]}"
        echo "aria2c -x 16 -s 16 --out=${sample_alias}_${run_accession}.fastq.gz ${URL}"
    done
done < "$METADATA_FILE" | sort -u >> "$ARIA2C_COMMANDS_FILE"

echo "Aria2c commands have been written to $ARIA2C_COMMANDS_FILE"