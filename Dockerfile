FROM python:3.8-slim

LABEL maintainer="Yi Zhang <yzhangmaximumko@gmail.com>"
LABEL description="Docker container for DaPars (Dynamic analysis of Alternative PolyAdenylation from RNA-seq)"
LABEL version="1.0.0"
LABEL source="https://github.com/ZhengXia/dapars"

# Install system dependencies and bedtools
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    wget \
    build-essential \
    bedtools \
    && rm -rf /var/lib/apt/lists/*

# Install DaPars Python dependencies
RUN pip install numpy scipy matplotlib statsmodels

# Download DaPars
WORKDIR /opt
RUN git clone https://github.com/ZhengXia/dapars.git

# Check the structure and make files executable
RUN find /opt/dapars -name "*.py" -exec chmod +x {} \;

# Add example dataset
COPY Example_dataset /opt/dapars/example_data

# Add the wrapper scripts
COPY dapars_wrapper.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/dapars_wrapper.sh

COPY run_complete_dapars.sh /usr/local/bin/run_complete_dapars
RUN chmod +x /usr/local/bin/run_complete_dapars

# Set environment variables
ENV PATH=/opt/dapars:/usr/local/bin:$PATH
ENV PYTHONPATH=/opt/dapars

# Set working directory
WORKDIR /data

# Set entrypoint to our wrapper script
ENTRYPOINT ["/usr/local/bin/dapars_wrapper.sh"]
