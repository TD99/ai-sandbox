#!/bin/bash

# Colors
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
RESET='\033[0m'

# Global Variables
WARNINGS=0
ERRORS=0

# Argument Booleans (Default values)
IS_FORCE_ARGUMENT=false
IS_STRICT_ARGUMENT=false
IS_CONTINUE_ON_ERROR_ARGUMENT=false

# ------------------------------

# Message Functions
error() {
    echo -e "${RED}ERROR| $1${RESET}"
    ERRORS=$((ERRORS + 1))
}

warn() {
    echo -e "${ORANGE}WARNING| $1${RESET}"
    WARNINGS=$((WARNINGS + 1))
}

info() {
    echo -e "${BLUE}INFO| $1${RESET}"
}

success() {
    echo -e "${GREEN}SUCCESS| $1${RESET}"
}

ask() {
    echo -e -n "$1"
    read -r response
    if [ "$response" == "y" ]; then
        return 1
    fi
    return 0
}

askContinueWarning() {
    if [ "$IS_FORCE_ARGUMENT" = true ]; then
        return 1
    fi
    if [ "$IS_STRICT_ARGUMENT" = true ]; then
        return 0
    fi

    ask "Do you want to continue? [y/N]: "
    return $?
}

showHelp() {
    echo "Usage: $0 [OPTIONS]"
    echo "Description: Perform system checks for Flux.1 AI on ComfyUI."
    echo ""
    echo "Options:"
    echo "  -h  | --help                Show this help message and exit."
    echo "  -f  | --force               Proceed with checks, even if warnings are present."
    echo "  -s  | --strict              Stop execution if any warnings are detected."
    echo "  -c  | --continue-on-error   Ignore errors and continue execution."
    echo ""
}

# Checks
## Main Check Function
do_checks() {
    echo "Performing system checks for Flux.1 AI on ComfyUI..."
    check_gpu
    check_cuda
    check_cpu
    check_ram
    check_storage
}

## Check GPU and VRAM
check_gpu() {
    if ! command -v nvidia-smi &> /dev/null; then
        error "NVIDIA GPU with CUDA support not detected."
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

## Check CUDA
check_cuda() {
    if ! command -v nvcc &> /dev/null; then
        error "CUDA Toolkit is not installed or not in the PATH."
    else
        cuda_version=$(nvcc --version | grep release | awk '{print $6}')
        info "CUDA Toolkit Version: $cuda_version"
    fi
}

## Check CPU cores/threads
check_cpu() {
    cores=$(nproc --all)
    if [ "$cores" -lt 4 ]; then
        warn "CPU has less than 4 cores. Detected: ${cores} cores"
    else
        info "CPU Cores: ${cores}"
    fi
}

## Check RAM
check_ram() {
    ram=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    ram_gb=$((ram / 1024 / 1024))
    if [ "$ram_gb" -lt 16 ]; then
        warn "System RAM is less than 16 GB. Detected: ${ram_gb} GB"
    else
        info "System RAM: ${ram_gb} GB"
    fi
}

## Check Storage
check_storage() {
    free_space=$(df / | grep / | awk '{print $4}')
    free_space_gb=$((free_space / 1024 / 1024))
    if [ "$free_space_gb" -lt 50 ]; then
        warn "Free disk space is less than 50 GB. Detected: ${free_space_gb} GB"
    else
        info "Free Disk Space: ${free_space_gb} GB"
    fi
}

# Argument Parsing
# Argument Parsing
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -f|--force)
            IS_FORCE_ARGUMENT=true
            ;;
        -s|--strict)
            IS_STRICT_ARGUMENT=true
            ;;
        -c|--continue-on-error)
            IS_CONTINUE_ON_ERROR_ARGUMENT=true
            ;;
        -h|--help)
            showHelp
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${RESET}"
            showHelp
            exit 1
            ;;
    esac
    shift
done

# Main Function
main() {
    do_checks

    if [ $ERRORS -gt 0 ]; then
        if [ "$IS_CONTINUE_ON_ERROR_ARGUMENT" = true ]; then
            warn "There are errors in the system checks. Continuing..."
        else
            error "System checks failed with errors. Exiting..."
            exit 1
        fi
    fi

    if [ $WARNINGS -gt 0 ]; then
        askContinueWarning
        if [ $? -eq 1 ]; then
            warn "There are warnings in the system checks. Continuing..."
        else
            error "System checks failed with warnings. Exiting..."
            exit 1
        fi
    fi

    success "All system checks passed successfully."
}

main $1