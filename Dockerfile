# Builds a Docker image for FastSolve development environment
# with Ubuntu, Octave, Python3, Jupyter Notebook and VS Code
#
# Authors:
# Xiangmin Jiao <xmjiao@gmail.com>

FROM fastsolve/desktop:dev
LABEL maintainer "Xiangmin Jiao <xmjiao@gmail.com>"

USER root
WORKDIR /tmp

ARG DEBIAN_FRONTEND=noninteractive

ARG SSHKEY_ID=secret
ARG MFILE_ID=secret

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ddd \
        electric-fence \
        valgrind && \
    apt-get clean && \
    \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install PETSc
RUN curl -s http://ftp.mcs.anl.gov/pub/petsc/release-snapshots/petsc-lite-${PETSC_VERSION}.tar.gz | \
    tar zx && \
    cd petsc-${PETSC_VERSION} && \
    unset PETSC_DIR && \
    \
    mkdir -p /tmp/archive && \
    ./configure --COPTFLAGS="-g" \
                --CXXOPTFLAGS="-g" \
                --FOPTFLAGS="-g" \
                --with-blas-lib=/usr/lib/x86_64-linux-gnu/libopenblas.so \
                --with-lapack-lib=/usr/lib/x86_64-linux-gnu/liblapack.so \
                --with-log=1 \
                --with-c-support \
                --with-debugging=1 \
                --with-shared-libraries \
                --download-suitesparse \
                --download-scalapack \
                --download-ptscotch \
                --download-hypre \
                --download-mumps \
                --download-blacs \
                --download-spai \
                --prefix=/usr/local/petsc-$PETSC_VERSION-dbg && \
     make all test && \
     make install && \
     rm -rf /tmp/* /var/tmp/*

ENV PETSC_DIR=/usr/local/petsc-$PETSC_VERSION-dbg

USER $DOCKER_USER

###############################################################
# Temporarily install MATLAB and build ilupack4m, paracoder, and
# petsc4m for Octave and MATLAB.
###############################################################
RUN gd-get-pub -o - $(sh -c "echo '$SSHKEY_ID'") | tar xf - -C $DOCKER_HOME && \
    ssh-keyscan -H github.com >> $DOCKER_HOME/.ssh/known_hosts && \
    \
    rm -f $DOCKER_HOME/.octaverc && \
    $DOCKER_HOME/bin/pull_fastsolve && \
    $DOCKER_HOME/bin/build_fastsolve && \
    \
    gd-get-pub -o - $(sh -c "echo '$MFILE_ID'") | \
        sudo bsdtar zxf - -C /usr/local --strip-components 2 && \
    \
    $DOCKER_HOME/bin/build_fastsolve -matlab && \
    sudo rm -rf /usr/local/MATLAB/R* && \
    \
    echo "run $DOCKER_HOME/fastsolve/paracoder/startup.m" >> $DOCKER_HOME/.octaverc && \
    echo "run $DOCKER_HOME/fastsolve/ilupack4m/startup.m" > $DOCKER_HOME/.octaverc && \
    echo "run $DOCKER_HOME/fastsolve/petsc4m/startup.m" >> $DOCKER_HOME/.octaverc && \
    \
    rm -f $DOCKER_HOME/.ssh/id_rsa*

WORKDIR $DOCKER_HOME/fastsolve
USER root
