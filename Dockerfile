# Builds a Docker image for FastSolve development environment
# with Ubuntu 16.04, Octave, Python3, Jupyter Notebook and Atom
#
# Authors:
# Xiangmin Jiao <xmjiao@gmail.com>

FROM fastsolve/desktop:latest
LABEL maintainer "Xiangmin Jiao <xmjiao@gmail.com>"

USER root
WORKDIR /tmp

# Build PETSc with debugging from source.
RUN curl -s http://ftp.mcs.anl.gov/pub/petsc/release-snapshots/petsc-lite-${PETSC_VERSION}.tar.gz | \
    tar zx && \
    cd petsc-${PETSC_VERSION} && \
    unset PETSC_DIR && \
    ./configure --COPTFLAGS="-g" \
                --CXXOPTFLAGS="-g" \
                --FOPTFLAGS="-g" \
                --with-blas-lib=/usr/lib/libopenblas.a --with-lapack-lib=/usr/lib/liblapack.a \
                --with-c-support \
                --with-debugging=1 \
                --with-shared-libraries \
                --download-suitesparse \
                --download-superlu \
                --download-superlu_dist \
                --download-scalapack \
                --download-metis \
                --download-parmetis \
                --download-ptscotch \
                --download-hypre \
                --download-mumps \
                --download-blacs \
                --download-spai \
                --download-ml \
                --prefix=/usr/local/petsc-$PETSC_VERSION-dbg && \
     make && \
     make install && \
     rm -rf /tmp/* /var/tmp/*

ENV PETSC_DIR=/usr/local/petsc-$PETSC_VERSION-dbg

ADD image/etc /etc
ADD image/bin $DOCKER_HOME/bin

# Install debugging tools and Atom
RUN add-apt-repository ppa:webupd8team/atom && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        ddd \
        electric-fence \
        valgrind \
        meld \
        atom \
        clang-format && \
    apt-get clean && \
    pip3 install -U \
         autopep8 \
         flake8 \
         PyQt5 \
         spyder && \
    rm -rf /var/lib/apt/lists/* && \
    apm install \
        language-cpp14 \
        language-matlab \
        language-fortran \
        language-docker \
        autocomplete-python \
        autocomplete-fortran \
        git-plus \
        merge-conflicts \
        split-diff \
        gcc-make-run \
        platformio-ide-terminal \
        intentions \
        busy-signal \
        linter-ui-default \
        linter \
        linter-gcc \
        linter-gfortran \
        linter-flake8 \
        linter-matlab \
        dbg \
        output-panel \
        dbg-gdb \
        python-debugger \
        auto-detect-indentation \
        python-autopep8 \
        clang-format && \
    \
    mkdir -p /usr/local/mlint && \
    curl -L https://goo.gl/ExjLDP | bsdtar zxf - -C /usr/local/mlint --strip-components 4 && \
    ln -s -f /usr/local/mlint/bin/glnxa64/mlint /usr/local/bin && \
    \
    curl -L "https://onedrive.live.com/download?cid=831ECDC40715C12C&resid=831ECDC40715C12C%21105&authkey=ACzYNYIvbCFhD48" | \
        tar xf - -C $DOCKER_HOME && \
    ssh-keyscan -H github.com >> $DOCKER_HOME/.ssh/known_hosts && \
    chown -R $DOCKER_USER:$DOCKER_GROUP $DOCKER_HOME

USER $DOCKER_USER

###############################################################
# Temporarily install MATLAB
# Build ilupack4m, paracoder, and petsc4m for Octave and MATLAB
###############################################################
RUN $DOCKER_HOME/bin/pull_fastsolve && \
    \
    curl -L "$(cat /tmp/url)" | sudo bsdtar zxf - -C /usr/local --strip-components 2 && \
    sudo /etc/my_init.d/make_aliases.sh && \
    rm -f $DOCKER_HOME/.octave && \
    $DOCKER_HOME/bin/build_fastsolve && \
    sudo rm -rf /usr/local/MATLAB/R* && \
    \
    rm -f $DOCKER_HOME/.octaverc && \
    echo "addpath $DOCKER_HOME/fastsolve/ilupack4m/matlab/ilupack" > $DOCKER_HOME/.octaverc && \
    echo "run $DOCKER_HOME/fastsolve/paracoder/.octaverc" >> $DOCKER_HOME/.octaverc && \
    echo "run $DOCKER_HOME/fastsolve/petsc4m/.octaverc" >> $DOCKER_HOME/.octaverc && \
    echo "PATH=$DOCKER_HOME/bin:$PATH" >> $DOCKER_HOME/.profile && \
    \
    echo "@octave --force-gui" >> $DOCKER_HOME/.config/lxsession/LXDE/autostart && \
    echo "@start_matlab" >> $DOCKER_HOME/.config/lxsession/LXDE/autostart

WORKDIR $DOCKER_HOME/fastsolve
USER root
