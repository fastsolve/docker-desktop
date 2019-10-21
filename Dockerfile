# Builds a Docker image with Ubuntu 18.04, Octave, Python3 and Jupyter Notebook
# for FastSolve
#
# Authors:
# Xiangmin Jiao <xmjiao@gmail.com>

FROM fastsolve/desktop:latest
LABEL maintainer "Xiangmin Jiao <xmjiao@gmail.com>"

USER root
WORKDIR /tmp

ENV UBUNTU_VERSION=1804
ENV CUDA_VERSION=10.1.243-1
ENV CUDA_MAMI_VERSION=10.1
ENV CUDA_PKG_VERSION=10-1=10.1.243-1

# Install CUDA runtime
RUN curl -O http://developer.download.nvidia.com/compute/cuda/repos/ubuntu${UBUNTU_VERSION}/x86_64/cuda-repo-ubuntu${UBUNTU_VERSION}_${CUDA_VERSION}_amd64.deb && \
    dpkg -i cuda-repo-ubuntu${UBUNTU_VERSION}_${CUDA_VERSION}_amd64.deb && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        cuda-nvrtc-$CUDA_PKG_VERSION \
        cuda-nvgraph-$CUDA_PKG_VERSION \
        cuda-cusolver-$CUDA_PKG_VERSION \
        cuda-cublas-$CUDA_PKG_VERSION \
        cuda-cufft-$CUDA_PKG_VERSION \
        cuda-curand-$CUDA_PKG_VERSION \
        cuda-cusparse-$CUDA_PKG_VERSION \
        cuda-npp-$CUDA_PKG_VERSION \
        cuda-cudart-$CUDA_PKG_VERSION && \
    ln -s cuda-${CUDA_MAMI_VERSION} /usr/local/cuda && \
    echo "/usr/local/cuda/lib64" >> /etc/ld.so.conf.d/cuda.conf && ldconfig && \
    echo "/usr/local/nvidia/lib" >> /etc/ld.so.conf.d/nvidia.conf && \
    echo "/usr/local/nvidia/lib64" >> /etc/ld.so.conf.d/nvidia.conf && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install CUDA devel
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      cuda-core-$CUDA_PKG_VERSION \
      cuda-misc-headers-$CUDA_PKG_VERSION \
      cuda-command-line-tools-$CUDA_PKG_VERSION \
      cuda-nvrtc-dev-$CUDA_PKG_VERSION \
      cuda-nvml-dev-$CUDA_PKG_VERSION \
      cuda-nvgraph-dev-$CUDA_PKG_VERSION \
      cuda-cusolver-dev-$CUDA_PKG_VERSION \
      cuda-cublas-dev-$CUDA_PKG_VERSION \
      cuda-cufft-dev-$CUDA_PKG_VERSION \
      cuda-curand-dev-$CUDA_PKG_VERSION \
      cuda-cusparse-dev-$CUDA_PKG_VERSION \
      cuda-npp-dev-$CUDA_PKG_VERSION \
      cuda-cudart-dev-$CUDA_PKG_VERSION \
      cuda-driver-dev-$CUDA_PKG_VERSION && \
    apt-get clean && \
    echo "/usr/local/cuda/lib64" >> /etc/ld.so.conf.d/cuda.conf && ldconfig && \
    echo "/usr/local/nvidia/lib" >> /etc/ld.so.conf.d/nvidia.conf && \
    echo "/usr/local/nvidia/lib64" >> /etc/ld.so.conf.d/nvidia.conf && \
    rm -rf /var/lib/apt/lists/*

ENV PATH=/usr/local/nvidia/bin:/usr/local/cuda/bin:$PATH
ENV LD_LIBRARY_PATH=/usr/local/nvidia/lib:/usr/local/nvidia/lib64:$LD_LIBRARY_PATH

WORKDIR $DOCKER_HOME
