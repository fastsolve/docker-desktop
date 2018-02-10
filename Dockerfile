# Builds a Docker image with Ubuntu 16.04, Octave, Python3 and Jupyter Notebook
# for FastSolve
#
# Authors:
# Xiangmin Jiao <xmjiao@gmail.com>

FROM compdatasci/octave-desktop:latest
LABEL maintainer "Xiangmin Jiao <xmjiao@gmail.com>"

USER root
WORKDIR /tmp

# Install system packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        cmake \
        bison \
        flex \
        git \
        bash-completion \
        bsdtar \
        rsync \
        wget \
        unzip \
        gdb \
        ccache \
        \
        libboost-filesystem-dev \
        libboost-iostreams-dev \
        libboost-program-options-dev \
        libboost-system-dev \
        libboost-thread-dev \
        libboost-timer-dev \
        liblapack-dev \
        libmpich-dev \
        libopenblas-dev \
        mpich && \
    apt-get clean && \
    pip3 install -U \
        requests \
        progressbar2 \
        PyDrive && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install MKL
# Source: https://software.intel.com/en-us/articles/installing-intel-free-libs-and-python-apt-repo
ENV MKL_VERSION=2017.2.050 MKL_SHORTVER=174
ENV MKLROOT=/opt/intel/compilers_and_libraries_2017.2.174/linux/mkl
ENV LD_LIBRARY_PATH=$MKLROOT/lib/intel64

RUN curl -L -O http://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS-2019.PUB && \
    apt-key add GPG-PUB-KEY-INTEL-SW-PRODUCTS-2019.PUB && \
    sh -c 'echo deb http://apt.repos.intel.com/mkl all main > /etc/apt/sources.list.d/intel-mkl.list' && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        intel-mkl-rt-$MKL_SHORTVER \
        intel-mkl-common-$MKL_SHORTVER \
        intel-mkl-common-c-$MKL_SHORTVER \
        intel-mkl-common-c-64bit-$MKL_SHORTVER \
        intel-tbb-libs-$MKL_SHORTVER && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install PETSc from source.
ENV PETSC_VERSION=3.7.6

RUN curl -s http://ftp.mcs.anl.gov/pub/petsc/release-snapshots/petsc-lite-${PETSC_VERSION}.tar.gz | \
    tar zx && \
    unset PETSC_DIR && \
    cd petsc-${PETSC_VERSION} && \
    ./configure --COPTFLAGS="-O2" \
                --CXXOPTFLAGS="-O2" \
                --FOPTFLAGS="-O2" \
                --with-blas-lapack-dir=$MKLROOT \
                --with-c-support \
                --with-debugging=0 \
                --with-shared-libraries \
                --download-suitesparse \
                --download-superlu \
                --download-superlu_dist \
                --download-scalapack \
                --download-blacs \
                --download-metis \
                --download-parmetis \
                --download-ptscotch \
                --download-hypre \
                --download-mumps \
                --download-spai \
                --download-ml \
                --prefix=/usr/local/petsc-$PETSC_VERSION && \
     make && \
     make install && \
     rm -rf /tmp/* /var/tmp/*

ENV PETSC_DIR=/usr/local/petsc-$PETSC_VERSION

# Install ilupack4m, paracoder and petsc4m
RUN mkdir -p /usr/local/ilupack4m && \
    curl -s  -L https://github.com/fastsolve/ilupack4m/archive/master.tar.gz | \
        bsdtar zxf - --strip-components 1 -C /usr/local/ilupack4m && \
    cd /usr/local/ilupack4m/makefiles && make TARGET=Octave && \
    \
    mkdir -p /usr/local/paracoder && \
    curl -s  -L https://github.com/fastsolve/paracoder/archive/master.tar.gz | \
        bsdtar zxf - --strip-components 1 -C /usr/local/paracoder && \
    cd /usr/local/paracoder && octave --eval "build_m2c -force" && \
    rm -rf `find /usr/local/paracoder -name lib` && \
    \
    mkdir -p /usr/local/petsc4m && \
    curl -s  -L https://github.com/fastsolve/petsc4m/archive/master.tar.gz | \
        bsdtar zxf - --strip-components 1 -C /usr/local/petsc4m && \
    cd /usr/local/petsc4m && octave --eval "build_petsc -force" && \
    rm -rf `find /usr/local/petsc4m -name lib`

########################################################
# Customization for user
########################################################
RUN echo "export OMP_NUM_THREADS=\$(nproc)" >> $DOCKER_HOME/.profile && \
    touch $DOCKER_HOME/.log/jupyter.log && \
    \
    echo 'run /usr/local/ilupack4m/startup.m' >> $DOCKER_HOME/.octaverc && \
    echo 'run /usr/local/paracoder/startup.m' >> $DOCKER_HOME/.octaverc && \
    echo 'run /usr/local/petsc4m/startup.m' >> $DOCKER_HOME/.octaverc && \
    chown -R $DOCKER_USER:$DOCKER_GROUP $DOCKER_HOME

WORKDIR $DOCKER_HOME
