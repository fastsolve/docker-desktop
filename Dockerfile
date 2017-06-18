# Builds a Docker image for FastSolve development environment
# with Ubuntu 16.04, Octave, Python3, Jupyter Notebook and Atom
#
# Authors:
# Xiangmin Jiao <xmjiao@gmail.com>

FROM fastsolve/desktop:dev-env
LABEL maintainer "Xiangmin Jiao <xmjiao@gmail.com>"

USER root
WORKDIR /tmp

ARG DEBIAN_FRONTEND=noninteractive

ARG SSHKEY_ID=secret
ARG MFILE_ID=secret
ADD image/etc /etc
ADD image/bin $DOCKER_HOME/bin
ADD image/config $DOCKER_HOME/.config

# Install gdutil
RUN git clone --depth 1 https://github.com/hpdata/gdutil /usr/local/gdutil && \
    pip3 install -r /usr/local/gdutil/requirements.txt && \
    ln -s -f /usr/local/gdutil/gd_get_pub.py /usr/local/bin/gd-get-pub && \
    chown -R $DOCKER_USER:$DOCKER_GROUP $DOCKER_HOME && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

USER $DOCKER_USER
WORKDIR $DOCKER_HOME/fastsolve

# Install PETSc
RUN curl -s http://ftp.mcs.anl.gov/pub/petsc/release-snapshots/petsc-lite-${PETSC_VERSION}.tar.gz | \
    tar zx && \
    cd petsc-${PETSC_VERSION} && \
    unset PETSC_DIR && \
    \
    ln -s -f /usr/lib/liblapack.a /usr/lib/libopenblas.a . && \
    ./configure --COPTFLAGS="-g" \
               --CXXOPTFLAGS="-g" \
               --FOPTFLAGS="-g" \
               --with-blas-lib=$PWD/libopenblas.a \
               --with-lapack-lib=$PWD/liblapack.a \
               --with-c-support \
               --with-debugging=1 \
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
               --download-spai && \
    make all test

ENV PETSC_DIR $DOCKER_HOME/fastsolve/petsc-${PETSC_VERSION}

###############################################################
# Temporarily install MATLAB and build ilupack4m, paracoder, and
# petsc4m for Octave and MATLAB. Install Atom packages.
###############################################################
RUN gd-get-pub $(sh -c "echo '$SSHKEY_ID'") | tar xf - -C $DOCKER_HOME && \
    ssh-keyscan -H github.com >> $DOCKER_HOME/.ssh/known_hosts && \
    \
    rm -f $DOCKER_HOME/.octaverc && \
    $DOCKER_HOME/bin/pull_fastsolve && \
    $DOCKER_HOME/bin/build_fastsolve && \
    \
    gd-get-pub $(sh -c "echo '$MFILE_ID'") | \
        sudo bsdtar zxf - -C /usr/local --strip-components 2 && \
    MATLAB_VERSION=$(cd /usr/local/MATLAB; ls) sudo -E /etc/my_init.d/make_aliases.sh && \
    \
    $DOCKER_HOME/bin/build_fastsolve -matlab && \
    sudo rm -rf /usr/local/MATLAB/R* && \
    \
    echo "addpath $DOCKER_HOME/fastsolve/ilupack4m/matlab/ilupack" > $DOCKER_HOME/.octaverc && \
    echo "run $DOCKER_HOME/fastsolve/paracoder/.octaverc" >> $DOCKER_HOME/.octaverc && \
    echo "run $DOCKER_HOME/fastsolve/petsc4m/.octaverc" >> $DOCKER_HOME/.octaverc && \
    \
    rm -f $DOCKER_HOME/.ssh/id_rsa* && \
    ln -s -f $DOCKER_HOME/.config/matlab $DOCKER_HOME/.matlab && \
    echo "@start_matlab -desktop -Ddebugger ddd -r 'dbmex on'" >> $DOCKER_HOME/.config/lxsession/LXDE/autostart && \
    echo "PATH=$DOCKER_HOME/bin:/usr/local/gdutil/bin:$PATH" >> $DOCKER_HOME/.profile

USER root
