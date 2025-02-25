# Fetch SRR Script

A bash script to fetch metadata and generate download commands for SRA/ENA sequence data.

## Description

This script takes a list of SRR accessions and:
1. Fetches detailed metadata from EBI's ENA database
2. Generates aria2c download commands for the associated FASTQ files
3. Optionally saves complete metadata information

## Prerequisites

- bash
- curl
- jq
- aria2c (for actual downloading)

## Installation

Clone this repository:

```bash
git clone https://github.com/your-username/fetch_srr.git
cd fetch_srr
chmod +x fetch_SRR_v2.sh
```

bash
./fetch_SRR_v2.sh input_list.txt

With options:

```bash
./fetch_SRR_v2.sh --metadata --debug input_list.txt
```

### Options

- `--metadata`: Save complete metadata information
- `--debug`: Enable debug mode (verbose output)

### Input File Format

Create a text file with one SRR accession per line:

```bash
SRR10010331
SRR10010328
SRR10010326
```

or 

```bash
PRJNA1000000
```

### Output Files

- `aria2c_commands.txt`: Contains aria2c commands for downloading FASTQ files
- `metadata.txt`: (When --metadata is used) Contains detailed metadata for each accession

## Example

1. Create an input file:

```bash
echo "SRR10010331" > srr_list.txt
```

2. Run the script:

```bash
./fetch_SRR_v2.sh --metadata srr_list.txt
```

3. Download the FASTQ files using the generated commands:
```bash
bash aria2c_commands.txt
```

## Notes

- The script uses EBI's ENA API to fetch metadata
- Download commands are optimized for aria2c with 16 connections per file
- Output filenames include both sample alias and run accession
