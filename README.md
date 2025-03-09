
# DaPars Docker Container

This repository provides a Docker container for DaPars (Dynamic analysis of Alternative PolyAdenylation from RNA-seq), a tool for discovering and analyzing alternative polyadenylation events from RNA-seq data. 


## About DaPars
[DaPars](https://github.com/ZhengXia/dapars) is a bioinformatics tool that directly infers dynamic alternative polyadenylation (APA) usage by comparing standard RNA-seq data. Given the annotated gene model, DaPars can identify de novo proximal APA sites as well as quantify the long and short 3'UTR expression levels. This enables researchers to study changes in 3'UTR usage across different conditions.
## Quick Start
### GitHub Container Registry
Supports both x86_64 and ARM64 platforms (works on Apple Silicon Macs)

```bash
# Pull the image 
docker pull ghcr.io/maximumko/dapars-docker:latest

# View usage instructions 
docker run -it --rm ghcr.io/maximumko/dapars-docker:latest --help

# Run the integrated workflow
docker run --rm -v $(pwd):/data ghcr.io/maximumko/dapars-docker:latest run_complete_dapars \
  --gene-bed /data/gene.bed \
  --symbol-map /data/symbol_map.txt \
  --sample-file /data/sample_list.txt \
  --output-dir /data/output
```
### Usage Modes
#### 1. Two-step workflow (Original)
##### Step 1: Generate region annotation
```bash
docker run --rm -v $(pwd):/data ghcr.io/maximumko/dapars-docker:latest \
  /opt/dapars/src/DaPars_Extract_Anno.py \
  -b /data/gene.bed \
  -s /data/symbol_map.bed \
  -o /data/extracted_3UTR.bed
```
##### Step 2: Run DaPars main analysis
```bash
docker run --rm -v $(pwd):/data ghcr.io/maximumko/dapars-docker:latest \
  /data/config_file.txt
```

#### 2. Integrated workflow (Recommended)
```bash
docker run --rm -v $(pwd):/data ghcr.io/maximumko/dapars-docker:latest run_complete_dapars \
  --gene-bed /data/gene.bed \
  --symbol-map /data/symbol_map.bed \
  --sample-file /data/sample_list.txt \
  --output-dir /data/output
```
##### For detailed help on the integrated workflow:
```bash
docker run --rm -v $(pwd):/data ghcr.io/maximumko/dapars-docker:latest run_complete_dapars --help
```
## Example Data
The container includes an example dataset to help you get started with DaPars:
```bash
# Run a shell in the container to copy the example data
docker run --rm -it -v $(pwd):/data --entrypoint bash ghcr.io/maximumko/dapars-docker:latest

# Then inside the container:
cp -r /opt/dapars/example_data/* /data/
exit

# Now you can run DaPars with the example data
docker run --rm -v $(pwd):/data ghcr.io/maximumko/dapars-docker:latest run_complete_dapars \
  --gene-bed /data/RefSeq_hg19.bed \
  --symbol-map /data/RefSeq_hg19_GeneName.bed \
  --sample-file /data/Example_sample_list.txt \
  --output-dir /data/output
```

## File Format
Input Files
DaPars requires the following input files:

Alignment files: Wig files for each sample (referenced in the sample list file)

`--gene-bed` (BED format): Standard 12-column BED file representing gene models; 
`--symbol-map`: Tab-separated file mapping transcript IDs to gene symbols;
`--sample-file`: Configuration file specifying file paths for the groups to compare

The sample list file should contain:
```
Group1_Tophat_aligned_Wig=/data/sample1_condition1.wig,/data/sample2_condition1.wig
Group2_Tophat_aligned_Wig=/data/sample1_condition2.wig,/data/sample2_condition2.wig
Num_least_in_group1=1
Num_least_in_group2=1
```

## Citation
If you use DaPars in your research, please cite:

Xia, Z., et al. (2014). Dynamic analyses of alternative polyadenylation from RNA-seq reveal a 3′-UTR landscape across seven tumour types. Nature Communications, 5:5274. PMID: [25409906](https://pubmed.ncbi.nlm.nih.gov/25409906/)

Yi Zhang. (2025). dapars-docker. GitHub. https://github.com/maximumko/dapars-docker

For more details about DaPars, visit the original repository: https://github.com/ZhengXia/dapars
## Authors

- [@maximumko](https://www.github.com/maximumko)

