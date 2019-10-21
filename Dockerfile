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

# Install CUDA runtime by following steps oulined here:
# https://developer.nvidia.com/cuda-downloads?target_os=Linux&target_arch=x86_64&target_distro=Ubuntu&target_version=1804&target_type=debnetwork
RUN apt-get update && \
    apt-get install -y --no-install-recommends dirmngr && \
    wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu${UBUNTU_VERSION}/x86_64/cuda-ubuntu${UBUNTU_VERSION}.pin && \
    mv cuda-ubuntu${UBUNTU_VERSION}.pin \
       /etc/apt/preferences.d/cuda-repository-pin-600 && \
    apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu${UBUNTU_VERSION}/x86_64/7fa2af80.pub && \
    add-apt-repository "deb http://developer.download.nvidia.com/compute/cuda/repos/ubuntu${UBUNTU_VERSION}/x86_64/ /" && \
    apt-get update && \
    apt-get install -y --no-install-recommends cuda && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV PATH=/usr/local/nvidia/bin:/usr/local/cuda/bin:$PATH
ENV LD_LIBRARY_PATH=/usr/local/nvidia/lib:/usr/local/nvidia/lib64:$LD_LIBRARY_PATH

WORKDIR $DOCKER_HOME
