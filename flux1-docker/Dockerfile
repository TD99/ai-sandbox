FROM python:3.12.5-slim

# Install APT dependencies
RUN apt-get update
RUN apt-get install git wget -y

# Set working directory
WORKDIR /app

# Clone the ComfyUI repository
RUN git clone https://github.com/comfyanonymous/ComfyUI.git
WORKDIR /app/ComfyUI

# Install Python dependencies
RUN pip3 install -r requirements.txt

# # Download the flux schnell FP8 checkpoint if not already downloaded
# RUN mkdir -p ./models/checkpoints && \
#     [ -f ./models/checkpoints/flux1-schnell-fp8.safetensors ] || \
#     wget https://huggingface.co/Comfy-Org/flux1-schnell/resolve/main/flux1-schnell-fp8.safetensors -P ./models/checkpoints/

# # Download the VAE model if not already downloaded
# RUN mkdir -p ./models/vae && \
#     [ -f ./models/vae/ae.safetensors ] || \
#     wget https://huggingface.co/black-forest-labs/FLUX.1-schnell/resolve/main/ae.safetensors -P ./models/vae/

# # Download the UNet model if not already downloaded
# RUN mkdir -p ./models/unet && \
#     [ -f ./models/unet/flux1-schnell.safetensors ] || \
#     wget https://huggingface.co/black-forest-labs/FLUX.1-schnell/resolve/main/flux1-schnell.safetensors -P ./models/unet/

CMD [ "python3", "./main.py" ]