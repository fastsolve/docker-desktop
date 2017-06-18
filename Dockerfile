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
        gdb \
        ccache \
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

# Install PETSc from source.
ENV PETSC_VERSION=3.7.6 \
    OPENBLAS_NUM_THREADS=1 \
    OPENBLAS_VERBOSE=0

RUN curl -s http://ftp.mcs.anl.gov/pub/petsc/release-snapshots/petsc-lite-${PETSC_VERSION}.tar.gz | \
    tar zx && \
    cd petsc-${PETSC_VERSION} && \
    unset PETSC_DIR && \
    \
    ln -s -f /usr/lib/liblapack.a /usr/lib/libopenblas.a . && \
    ./configure --COPTFLAGS="-O2" \
                --CXXOPTFLAGS="-O2" \
                --FOPTFLAGS="-O2" \
                --with-blas-lib=$PWD/libopenblas.a \
                --with-lapack-lib=$PWD/liblapack.a \
                --with-c-support \
                --with-debugging=0 \
                --with-shared-libraries \
                --download-suitesparse \
                --download-superlu \
                --download-scalapack \
                --download-metis \
                --download-parmetis \
                --download-ptscotch \
                --download-hypre \
                --download-mumps \
                --download-blacs \
                --download-spai \
                --prefix=/usr/local/petsc-$PETSC_VERSION && \
     make all test && \
     make install && \
     rm -rf /tmp/* /var/tmp/*

ENV PETSC_DIR=/usr/local/petsc-$PETSC_VERSION

########################################################
# Customization for user
########################################################
RUN sed -e 's/autohide=0/autohide=1/g' -i \
        $DOCKER_HOME/.config/lxpanel/LXDE/panels/panel && \
    echo "export OMP_NUM_THREADS=\$(nproc)" >> $DOCKER_HOME/.profile && \
    touch $DOCKER_HOME/.log/jupyter.log && \
    chown -R $DOCKER_USER:$DOCKER_GROUP $DOCKER_HOME

WORKDIR $DOCKER_HOME
