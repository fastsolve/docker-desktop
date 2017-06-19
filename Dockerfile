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
WORKDIR $DOCKER_HOME/fastsolve

# Install gdutil
RUN add-apt-repository ppa:webupd8team/atom && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        ddd \
        electric-fence \
        valgrind && \
    apt-get clean && \
    \
    git clone --depth 1 https://github.com/hpdata/gdutil /usr/local/gdutil && \
    pip2 install -r /usr/local/gdutil/requirements.txt && \
    pip3 install -r /usr/local/gdutil/requirements.txt && \
    ln -s -f /usr/local/gdutil/gd_get_pub.py /usr/local/bin/gd-get-pub && \
    mkdir -p $DOCKER/HOME/fastsolve && \
    chown -R $DOCKER_USER:$DOCKER_GROUP $DOCKER_HOME && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

USER $DOCKER_USER

# Install PETSc
RUN curl -s http://ftp.mcs.anl.gov/pub/petsc/release-snapshots/petsc-lite-${PETSC_VERSION}.tar.gz | \
    tar zx && \
    cd petsc-${PETSC_VERSION} && \
    unset PETSC_DIR && \
    \
    mkdir -p /tmp/archive && \
    sudo mv /usr/lib/liblapack*.so /usr/lib/libopenblas*.so /tmp/archive && \
    ./configure --COPTFLAGS="-g" \
                --CXXOPTFLAGS="-g" \
                --FOPTFLAGS="-g" \
                --with-blas-lib=/usr/lib/libopenblas.a \
                --with-lapack-lib=/usr/lib/liblapack.a \
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
     sudo make install && \
     sudo mv /tmp/archive/*.so /usr/lib && \
     rm -rf /tmp/* /var/tmp/*

ENV PETSC_DIR=/usr/local/petsc-$PETSC_VERSION-dbg

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
    echo "@start_matlab -desktop" >> $DOCKER_HOME/.config/lxsession/LXDE/autostart && \
    echo "PATH=$DOCKER_HOME/bin:/usr/local/gdutil/bin:$PATH" >> $DOCKER_HOME/.profile

USER root
