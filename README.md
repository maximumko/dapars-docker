DaPars Docker Container
This repository provides a Docker container for DaPars (Dynamic analysis of Alternative PolyAdenylation from RNA-seq), a tool for discovering and analyzing alternative polyadenylation events from RNA-seq data.
About DaPars
DaPars is a bioinformatics tool that directly infers dynamic alternative polyadenylation (APA) usage by comparing standard RNA-seq data. Given the annotated gene model, DaPars can identify de novo proximal APA sites as well as quantify the long and short 3'UTR expression levels. This enables researchers to study changes in 3'UTR usage across different conditions.
Quick Start
bashCopy# Pull the image
docker pull maximumko/dapars:1.0.0

# Run the integrated workflow
docker run --rm -v $(pwd):/data maximumko/dapars:1.0.0 run_complete_dapars \
  --gene-bed /data/gene.bed \
  --symbol-map /data/symbol_map.txt \
  --sample-file /data/sample_list.txt \
  --output-dir /data/output
Usage Modes
1. Two-step workflow (original)
Step 1: Generate region annotation
bashCopydocker run --rm -v $(pwd):/data maximumko/dapars:1.0.0 \
  /opt/dapars/src/DaPars_Extract_Anno.py \
  -b /data/gene.bed \
  -s /data/symbol_map.txt \
  -o /data/extracted_3UTR.bed
Step 2: Run DaPars main analysis
bashCopydocker run --rm -v $(pwd):/data maximumko/dapars:1.0.0 \
  /data/config_file.txt
2. Integrated workflow (recommended)
bashCopydocker run --rm -v $(pwd):/data maximumko/dapars:1.0.0 run_complete_dapars \
  --gene-bed /data/gene.bed \
  --symbol-map /data/symbol_map.txt \
  --sample-file /data/sample_list.txt \
  --output-dir /data/output
For detailed help on the integrated workflow:
bashCopydocker run --rm maximumko/dapars:1.0.0 run_complete_dapars --help
Example Data
The container includes an example dataset to help you get started with DaPars:
bashCopy# Run a shell in the container to copy the example data
docker run --rm -it -v $(pwd):/data --entrypoint bash maximumko/dapars:1.0.0

# Then inside the container:
cp -r /opt/dapars/example_data/* /data/
exit

# Now you can run DaPars with the example data
docker run --rm -v $(pwd):/data maximumko/dapars:1.0.0 run_complete_dapars \
  --gene-bed /data/RefSeq_hg19.bed \
  --symbol-map /data/RefSeq_hg19_GeneName.bed \
  --sample-file /data/Example_sample_list.txt \
  --output-dir /data/output
Building the Container
If you prefer to build the container yourself:
bashCopygit clone https://github.com/maximumko/dapars-docker.git
cd dapars-docker
docker build -t maximumko/dapars:1.0.0 .
Input Files
DaPars requires the following input files:

Gene model (BED format): Standard 12-column BED file representing gene models
Symbol mapping file: Tab-separated file mapping transcript IDs to gene symbols
Sample list file: Configuration file specifying file paths for the groups to compare
Alignment files: Wig files for each sample (referenced in the sample list file)

Sample File Format
The sample list file should contain:
CopyGroup1_Tophat_aligned_file=/data/sample1_condition1.wig,/data/sample2_condition1.wig
Group2_Tophat_aligned_file=/data/sample1_condition2.wig,/data/sample2_condition2.wig
Num_least_in_group1=1
Num_least_in_group2=1
Output Files
After a successful run, DaPars produces several output files in the specified output directory:

DaPars_result_All_Prediction_Results.txt: Contains all predicted APA events
DaPars_result_All_APA_Predictions.txt: Contains significant APA events based on the specified thresholds

Citation
If you use DaPars in your research, please cite:
Xia, Z., et al. (2014). Dynamic Analyses of Alternative Polyadenylation from RNA-Seq Reveal 3'-UTR Landscape Across 7 Tumor Types. Nature Communications, 5:5274
More Information
For more details about DaPars, visit the original repository: https://github.com/ZhengXia/dapars
License
This container is provided under the GPL-2.0 license, the same as the original DaPars software.