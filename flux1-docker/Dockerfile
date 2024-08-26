FROM nvidia/cuda:12.6.0-runtime-ubuntu24.04

# Install APT dependencies
RUN apt-get update
RUN apt-get install git wget gcc python3 python3-pip -y 

# Set working directory
WORKDIR /app

# Clone the ComfyUI repository
RUN git clone https://github.com/comfyanonymous/ComfyUI.git
WORKDIR /app/ComfyUI

# Install Python dependencies
RUN pip3 install -r requirements.txt --break-system-packages
RUN pip3 install requests tqdm --break-system-packages

# Copy compatibility script
COPY ./scripts/check_compatibility.sh /app/ComfyUI/check_compatibility.sh
RUN chmod +x check_compatibility.sh

# Copy model files
COPY ./models/config.json /app/ComfyUI/modelConfig.json
COPY ./models/deploy.py /app/ComfyUI/modelDeploy.py

# Container entrypoint
CMD "python3 modelDeploy.py"