# 1. Base Image: Use an official NVIDIA CUDA image with the developer toolkit.
FROM nvidia/cuda:12.1.1-cudnn8-devel-ubuntu22.04

# 2. System Dependencies: Install build tools and Python.
# Using non-interactive to prevent prompts during build.
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    git \
    cmake \
    python3.11 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# 3. User Setup: Create a non-root user for security.
RUN useradd -m -u 1000 user
USER user
ENV HOME=/home/user \
    PATH=/home/user/.local/bin:$PATH
WORKDIR $HOME/app

# 4. Python Dependencies: Copy and install requirements first to leverage Docker caching.
COPY --chown=user:user requirements.txt.
RUN pip install --no-cache-dir -r requirements.txt

# 5. ASMK Compilation: Clone and install the required 'asmk' library.
RUN git clone https://github.com/jenicek/asmk && \
    cd asmk && \
    pip install. && \
    cd.. && \
    rm -rf asmk

# 6. Application Code: Copy the rest of your project files.
COPY --chown=user:user..

# 7. Optional: Compile CUDA kernels for RoPE for better performance.
# This step can be uncommented if you need maximum performance.
# RUN cd dust3r/croco/models/curope/ && \
#     python3 setup.py build_ext --inplace && \
#     cd../../../../

# 8. Expose Port and Run Application: Define the command to start the Gradio demo.
EXPOSE 7860
CMD ["gradio", "demo.py", "--server-name", "0.0.0.0", "--share"]
