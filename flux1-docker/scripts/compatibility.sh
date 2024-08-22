#!/bin/bash

# Colors
ORANGE='\033[0;33m'
GREEN='\033[0;32m'
RESET='\033[0m'

# Global Variables
WARNINGS=0

# ------------------------------

# Message Functions
warn() {
    echo -e "${ORANGE}WARNING| $1${RESET}"
    WARNINGS=$((WARNINGS + 1))
}

info() {
    echo -e "${GREEN}INFO| $1${RESET}"
}

askContinue() {
    if [ $WARNINGS -gt 0 ]; then
        echo -e "There are warnings in the system checks. Do you want to continue? (y/n)${RESET}"
        read -r response
        if [ "$response" != "y" ]; then
            echo "Exiting..."
            exit 1
        fi
    fi
}

# Check GPU and VRAM
check_gpu() {
    if ! command -v nvidia-smi &> /dev/null; then
        warn "NVIDIA GPU with CUDA support not detected."
        return
    else
        info "NVIDIA GPU with CUDA support detected."
    fi

    vram=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits)
    if [ "$vram" -lt 8000 ]; then
        warn "GPU VRAM is less than 8 GB. Detected: ${vram} MB"
    else
        info "GPU VRAM: ${vram} MB"
    fi
}

# Check CUDA
check_cuda() {
    if ! command -v nvcc &> /dev/null; then
        warn "CUDA Toolkit is not installed or not in the PATH."
    else
        cuda_version=$(nvcc --version | grep release | awk '{print $6}')
        info "CUDA Toolkit Version: $cuda_version"
    fi
}

# Check CPU cores/threads
check_cpu() {
    cores=$(nproc --all)
    if [ "$cores" -lt 4 ]; then
        warn "CPU has less than 4 cores. Detected: ${cores} cores"
    else
        info "CPU Cores: ${cores}"
    fi
}

# Check RAM
check_ram() {
    ram=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    ram_gb=$((ram / 1024 / 1024))
    if [ "$ram_gb" -lt 16 ]; then
        warn "System RAM is less than 16 GB. Detected: ${ram_gb} GB"
    else
        info "System RAM: ${ram_gb} GB"
    fi
}

# Check Storage
check_storage() {
    free_space=$(df / | grep / | awk '{print $4}')
    free_space_gb=$((free_space / 1024 / 1024))
    if [ "$free_space_gb" -lt 50 ]; then
        warn "Free disk space is less than 50 GB. Detected: ${free_space_gb} GB"
    else
        info "Free Disk Space: ${free_space_gb} GB"
    fi
}

# ------------------------------

main() {
    echo "Performing system checks for Flux.1 AI on ComfyUI..."

    check_gpu
    check_cuda
    check_cpu
    check_ram
    check_storage

    if [ $WARNINGS -gt 0 ]; then
        if [ "$1" == "--force" ]; then
            echo -e "${ORANGE}There are warnings in the system checks. Continuing with --force flag.${RESET}"
        else
            askContinue
        fi
    fi
    echo -e "${GREEN}System checks completed successfully.${RESET}"
}

main $1