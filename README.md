# DaPars Docker Container

This repository provides a Docker container for DaPars (Dynamic analysis of Alternative PolyAdenylation from RNA-seq).

## About DaPars

The dynamic usage of the 3'untranslated region (3'UTR) resulting from alternative polyadenylation (APA) is emerging as a pervasive mechanism for regulating mRNA diversity, stability and translation. DaPars is the first de novo tool that directly infers the dynamic alternative polyadenylation (APA) usage by comparing standard RNA-seq data.

## DaPars Workflow

DaPars requires a two-step process:

### Step 1: Generate region annotation

Extract 3'UTR regions from gene model:

```bash
# Using Docker
docker run --rm -v $(pwd):/data maximumko/dapars:1.0.0 /opt/dapars/src/DaPars_Extract_Anno.py \
  -b /data/gene.bed \
  -s /data/symbol_map.txt \
  -o /data/extracted_3UTR.bed

# Using Singularity
singularity exec dapars_1.0.0.sif python /opt/dapars/src/DaPars_Extract_Anno.py \
  -b /data/gene.bed \
  -s /data/symbol_map.txt \
  -o /data/extracted_3UTR.bed


