FROM python:3.10-slim

LABEL maintainer="Yi Zhang <yzhangmaximumko@gmail.com>"
LABEL description="Docker container for DaPars (Dynamic analysis of Alternative PolyAdenylation from RNA-seq)"
LABEL version="0.1.1"
LABEL source="https://github.com/ZhengXia/dapars"

# Install system dependencies and Python packages
RUN apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends \
    git \
    wget \
    figlet \
    procps \
    bedtools \
    && pip install --no-cache-dir --upgrade pip setuptools \
    && pip install --no-cache-dir numpy==1.24.4 scipy==1.10.1 matplotlib==3.7.5 statsmodels==0.14.1 \
    && git clone --depth 1 https://github.com/ZhengXia/dapars.git /opt/dapars \
    && find /opt/dapars -name "*.py" -exec chmod +x {} \; \
    && apt-get purge -y git wget \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /opt

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

# Set working directory for data processing
WORKDIR /data

# Set default command
ENTRYPOINT ["/usr/local/bin/dapars_wrapper.sh"]
CMD ["--help"]
