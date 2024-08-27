FROM nvidia/cuda:12.6.0-runtime-ubuntu24.04

# Install APT dependencies
RUN apt-get update
RUN apt-get install git wget gcc python3 python3-pip -y 

WORKDIR /app

# Clone the ComfyUI repository
RUN git clone https://github.com/comfyanonymous/ComfyUI.git

WORKDIR /app/ComfyUI

# Install Python dependencies
RUN pip3 install -r requirements.txt --break-system-packages
RUN pip3 install requests tqdm --break-system-packages

# Copy config files
COPY ./config/ /app/ComfyUI/docker_config

# Copy scripts
COPY ./scripts/ /app/ComfyUI/docker_scripts/
RUN chmod +x /app/ComfyUI/docker_scripts/*

# Container entrypoint
CMD "python3 ./docker_scripts/deploy.py"