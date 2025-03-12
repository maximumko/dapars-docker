#!/bin/bash

# Display help if requested
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
  figlet -f standard "DaPars"
  echo "Dynamic analysis of Alternative PolyAdenylation from RNA-seq"
  echo "Version 0.1.0"
  echo "=================================================="

  cat << EOF

USAGE MODES:
  1. Two-step workflow (Original):
     
     Step 1: Generate region annotation
       docker run -it --rm -v \$(pwd):/data maximumko/dapars-docker:latest \\
         /opt/dapars/src/DaPars_Extract_Anno.py \\
         -b /data/gene.bed \\
         -s /data/symbol_map.bed \\
         -o /data/extracted_3UTR.bed

     Step 2: Run DaPars main analysis
       docker run -it --rm -v \$(pwd):/data maximumko/dapars-docker:latest \\
         /data/config_file.txt

  2. Integrated workflow (Recommended):
       docker run -it --rm -v \$(pwd):/data maximumko/dapars-docker:latest run_complete_dapars \\
         --gene-bed /data/gene.bed \\
         --symbol-map /data/symbol_map.bed \\
         --sample-file /data/sample_list.txt \\
         --output-dir /data/output
  


MORE INFORMATION:
  Detailed help for integrated workflow:
    docker run -it --rm maximumko/dapars-docker:latest run_complete_dapars --help

  For more details, visit: 
    https://github.com/ZhengXia/dapars


EXAMPLE DATA:
  An example dataset is included in the container at /opt/dapars/example_data
  To use it, you can mount your current directory and copy the example data:

  # Run a shell in the container to copy the example data
  docker run --rm -it -v \$(pwd):/data --entrypoint bash maximumko/dapars-docker:latest

  # Then inside the container:
  cp -r /opt/dapars/example_data/* /data/
  exit

  # Now you can run DaPars with the example data
  docker run -it --rm -v \$(pwd):/data maximumko/dapars-docker:latest run_complete_dapars \\
    --gene-bed /data/RefSeq_hg19.bed \\
    --symbol-map /data/RefSeq_hg19_GeneName.bed \\
    --sample-file /data/Example_sample_list.txt \\
    --output-dir /data/output


CITATION:
  Xia, Z., et al. (2014). Dynamic Analyses of Alternative Polyadenylation from 
  RNA-Seq Reveal 3'-UTR Landscape Across Seven Tumor Types. 
  Nature Communications, 5:5274
EOF
  exit 0
fi

# Check if the command is to run the integrated mode
if [[ "$1" == "run_complete_dapars" ]]; then
  exec /usr/local/bin/run_complete_dapars "${@:2}"
  exit $?
fi

# Check if the first argument is a Python script for extraction
if [[ "$1" == *"DaPars_Extract_Anno.py"* ]]; then
  python "$@"
else
  # Default behavior - run DaPars main analysis
  python /opt/dapars/src/DaPars_main.py "$@"
fi


