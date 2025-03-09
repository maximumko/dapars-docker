#!/bin/bash

# Display DaPars logo
function display_logo {
  figlet -f standard "DaPars"
  echo "Dynamic analysis of Alternative PolyAdenylation from RNA-seq"
  echo "Version 0.1.0"
  echo "=================================================="
}

# Function to display help with proper formatting
function show_help {
  display_logo
  cat << EOF

USAGE:
  docker run -it --rm ghcr.io/maximumko/dapars-docker:latest run_complete_dapars \\
    --gene-bed /data/gene.bed \\
    --symbol-map /data/symbol_map.txt \\
    --sample-file /data/sample_list.txt \\
    --output-dir /data/output

REQUIRED PARAMETERS:
  --gene-bed PATH        Gene model in BED format
  --symbol-map PATH      Transcript-to-gene symbol mapping file
  --sample-file PATH     Sample list file with group information
  --output-dir PATH      Directory for output files

OPTIONAL PARAMETERS:
  --coverage INT         Coverage threshold [default: 30]
  --pdui FLOAT           PDUI threshold [default: 0.2]
  --fold-change FLOAT    Fold change threshold (log2) [default: 0.59]
  --help                 Show this help message and exit

INPUT FILE FORMATS:
  1. sample_list.txt:
     Group1_Tophat_aligned_file=sample1_condition1.wig,sample2_condition1.wig
     Group2_Tophat_aligned_file=sample1_condition2.wig,sample2_condition2.wig
     Num_least_in_group1=1
     Num_least_in_group2=1

  2. gene_bed:
     Standard 12-column BED file (UCSC format)

  3. symbol_map:
     Tab-separated file with transcript ID and gene symbol:
     TranscriptID\tGeneSymbol

EXAMPLES:
  Basic usage:
  docker run -it --rm ghcr.io/maximumko/dapars-docker:latest run_complete_dapars \\
    --gene-bed /data/hg19.bed \\
    --symbol-map /data/gene_map.txt \\
    --sample-file /data/samples.txt \\
    --output-dir /data/results

  With custom parameters:
  docker run -it --rm ghcr.io/maximumko/dapars-docker:latest run_complete_dapars \\
    --gene-bed /data/hg19.bed \\
    --symbol-map /data/gene_map.txt \\
    --sample-file /data/samples.txt \\
    --output-dir /data/results \\
    --coverage 20 \\
    --pdui 0.3 \\
    --fold-change 0.5

Citation:
  Xia, Z., et al. (2014). Dynamic Analyses of Alternative Polyadenylation from 
  RNA-Seq Reveal 3'-UTR Landscape Across Seven Tumor Types. 
  Nature Communications, 5:5274. PMID: 25409906
EOF
  exit 0
}

# Parameter parsing
GENE_BED=""
SYMBOL_MAP=""
SAMPLE_FILE=""
Num_least_in_group1=1
Num_least_in_group2=1
OUTPUT_DIR=""
OUTPUT_RESULT_FILE="DaPars_results"
COVERAGE=30
PDUI=0.2
FOLD_CHANGE=0.59

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --help|-h)
      show_help
      ;;
    --gene-bed)
      GENE_BED="$2"
      shift 2
      ;;
    --symbol-map)
      SYMBOL_MAP="$2"
      shift 2
      ;;
    --sample-file)
      SAMPLE_FILE="$2"
      shift 2
      ;;
    --output-dir)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    --coverage)
      COVERAGE="$2"
      shift 2
      ;;
    --pdui)
      PDUI="$2"
      shift 2
      ;;
    --fold-change)
      FOLD_CHANGE="$2"
      shift 2
      ;;
    *)
      echo "Unknown parameter: $1"
      show_help
      ;;
  esac
done

# Validate required parameters
if [[ -z "$GENE_BED" || -z "$SYMBOL_MAP" || -z "$SAMPLE_FILE" || -z "$OUTPUT_DIR" ]]; then
  echo "Error: Missing required parameters"
  show_help
fi

# Display logo at the start of execution
display_logo
echo

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Create status file to track progress
STATUS_FILE="${OUTPUT_DIR}/.dapars_status"

# Step 1: Extract 3'UTR annotation
EXTRACTED_UTR="${OUTPUT_DIR}/extracted_3UTR.bed"

# Check if step 1 is already completed
if [[ -f "$EXTRACTED_UTR" && -s "$EXTRACTED_UTR" ]]; then
  echo "[1/3] ✓ 3'UTR extraction already completed, skipping..."
else
  echo "[1/3] Extracting 3'UTR annotation..."

  # Create a temp file for output
  TEMP_OUTPUT=$(mktemp)

  # Run the extraction in the background and capture output
  python /opt/dapars/src/DaPars_Extract_Anno.py -b "$GENE_BED" -s "$SYMBOL_MAP" -o "$EXTRACTED_UTR" > "$TEMP_OUTPUT" 2>&1 &
  extract_pid=$!

  # Display a spinner while waiting
  spinner="-\\|/"
  i=0
  while kill -0 $extract_pid 2>/dev/null; do
    i=$(( (i+1) % 4 ))
    printf "\r  Progress: %c" "${spinner:$i:1}"
    sleep 0.5
  done

  # Wait for process to finish and get status
  wait $extract_pid
  extract_status=$?

  # Clear the progress line
  printf "\r                      \r"

  # Display the output
  cat "$TEMP_OUTPUT"
  rm "$TEMP_OUTPUT"

# Check for success
if [[ $extract_status -ne 0 || ! -f "$EXTRACTED_UTR" || ! -s "$EXTRACTED_UTR" ]]; then
  echo "Error: Failed to extract 3'UTR annotations or file is empty"
  exit 1
fi

  # Record step 1 as completed
  echo "STEP1_COMPLETED=$(date +%s)" > "$STATUS_FILE"
  echo "✓ 3'UTR extraction complete."
fi

# Create configuration file
CONFIG_FILE="${OUTPUT_DIR}/dapars_config.txt"


SAMPLE_CONTENT=$(cat "$SAMPLE_FILE")

# Check if step 2 is already completed
if [[ -f "$CONFIG_FILE" && -s "$CONFIG_FILE" ]]; then
  echo "[2/3] ✓ Configuration file already created, skipping..."
else
  echo "[2/3] Creating configuration file..."

  # Generate the config file with the correct format
  cat > "$CONFIG_FILE" << EOF
Annotated_3UTR=$EXTRACTED_UTR
$SAMPLE_CONTENT
Output_directory=$OUTPUT_DIR
Output_result_file=$OUTPUT_RESULT_FILE
Num_least_in_group1=$Num_least_in_group1
Num_least_in_group2=$Num_least_in_group2
Coverage_cutoff=$COVERAGE
PDUI_cutoff=$PDUI
Fold_change_cutoff=$FOLD_CHANGE
EOF

  # Record step 2 as completed
  echo "STEP2_COMPLETED=$(date +%s)" >> "$STATUS_FILE"
  echo "✓ Configuration file created at: $CONFIG_FILE"
fi

# Create a temporary file to track success
SUCCESS_FILE=$(mktemp)
echo "false" > $SUCCESS_FILE

# Check various result files that could indicate completion
RESULT_FILES=(
  "${OUTPUT_DIR}/${OUTPUT_RESULT_FILE}_All_Prediction_Results.txt"
  "${OUTPUT_DIR}/DaPars_results_All_Prediction_Results.txt"
  "${OUTPUT_DIR}/${OUTPUT_RESULT_FILE}_result_All_Prediction_Results.txt"
)

# Check if any of the result files exist
for file in "${RESULT_FILES[@]}"; do
  if [[ -f "$file" && -s "$file" ]]; then
    echo "[3/3] ✓ DaPars analysis already completed, skipping..."
    echo "Results are available at: $OUTPUT_DIR"
    rm $SUCCESS_FILE
    exit 0
  fi
done

# Step 3: Run DaPars main analysis
echo "[3/3] Running DaPars main analysis..."
echo "This may take a while. Progress updates will appear below:"

# Use a FIFO for real-time output
FIFO_FILE=$(mktemp -u)
mkfifo $FIFO_FILE

# Start DaPars in the background with unbuffered output
python -u /opt/dapars/src/DaPars_main.py "$CONFIG_FILE" > $FIFO_FILE 2>&1 &
DAPARS_PID=$!

# Start a timer
START_TIME=$(date +%s)

# Process the output in real-time
cat $FIFO_FILE | while read -r line; do
  # Calculate elapsed time
  CURRENT_TIME=$(date +%s)
  ELAPSED=$((CURRENT_TIME - START_TIME))
  MINS=$((ELAPSED / 60))
  SECS=$((ELAPSED % 60))
  
  # Display the line with elapsed time
  printf "  [%02d:%02d] > %s\n" $MINS $SECS "$line"
  
  # Check for the Finished! message
  if [[ "$line" == *"Finished!"* ]]; then
    echo "true" > $SUCCESS_FILE
  fi
done

# Wait for DaPars to finish and clean up
wait $DAPARS_PID
DAPARS_STATUS=$?
rm $FIFO_FILE

# Check if DaPars completed successfully
SUCCESS=$(cat $SUCCESS_FILE)
rm $SUCCESS_FILE

if [[ "$SUCCESS" == "true" || $DAPARS_STATUS -eq 0 ]]; then
  # Record step 3 as completed
  echo "STEP3_COMPLETED=$(date +%s)" >> "$STATUS_FILE"
  # Sort the result files for consistent output
  RESULT_FILES=(
    "${OUTPUT_DIR}/${OUTPUT_RESULT_FILE}_All_Prediction_Results.txt"
    "${OUTPUT_DIR}/DaPars_result_All_Prediction_Results.txt"
    "${OUTPUT_DIR}/${OUTPUT_RESULT_FILE}_result_All_Prediction_Results.txt"
  )
  
  for file in "${RESULT_FILES[@]}"; do
    if [[ -f "$file" && -s "$file" ]]; then
      echo "Sorting results in: $file"
      # Get header line
      HEADER=$(head -n 1 "$file")
      # Sort content (skipping header) and save to temporary file
      (echo "$HEADER"; tail -n +2 "$file" | sort) > "${file}.sorted"
      # Replace original with sorted version
      mv "${file}.sorted" "$file"
    fi
  done

  echo "✓ DaPars analysis complete. Results saved to: $OUTPUT_DIR"
else
  echo "⚠ Warning: DaPars may not have completed successfully."
  echo "  Please check the output files in: $OUTPUT_DIR"
  echo "  Exit status: $DAPARS_STATUS"
fi

# Display run summary
echo
echo "SUMMARY:"
echo "--------"
echo "Input gene model: $GENE_BED"
echo "Symbol mapping: $SYMBOL_MAP"
echo "Sample file: $SAMPLE_FILE"
echo "Output directory: $OUTPUT_DIR"
echo
echo "Configuration parameters:"
echo "- Coverage threshold: $COVERAGE"
echo "- PDUI threshold: $PDUI"
echo "- Fold change threshold: $FOLD_CHANGE"
echo
echo "To view results, check the files in: $OUTPUT_DIR"
