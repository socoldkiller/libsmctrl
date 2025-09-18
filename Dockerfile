# Use an official NVIDIA CUDA runtime as a parent image
FROM nvidia/cuda:11.3.1-devel-ubuntu20.04

# Set environment variables to avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install basic development tools
RUN apt-get update && apt-get install -y \
    gcc \
    git \
    cmake \ 
    gdb \ 
    && rm -rf /var/lib/apt/lists/*

# Set the working directory
WORKDIR /workspace



# Set the default command to bash
CMD ["/bin/bash"]
