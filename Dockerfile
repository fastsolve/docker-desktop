# Builds a Docker image for FastSolve development environment
# with Ubuntu 16.04, Octave, Python3, Jupyter Notebook and Atom
#
# Authors:
# Xiangmin Jiao <xmjiao@gmail.com>

FROM fastsolve/desktop:base
LABEL maintainer "Xiangmin Jiao <xmjiao@gmail.com>"

USER root
WORKDIR /tmp

ADD config/atom $DOCKER_HOME/.config/atom

# Install debugging tools and PETSc with Hypre
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
    rm -rf /var/lib/apt/lists/* && \
    chown -R $DOCKER_USER:$DOCKER_GROUP $DOCKER_HOME/.config && \
    \
    curl -s http://ftp.mcs.anl.gov/pub/petsc/release-snapshots/petsc-lite-${PETSC_VERSION}.tar.gz | \
    tar zx && \
    cd petsc-${PETSC_VERSION} && \
    unset PETSC_DIR && \
    \
    mkdir -p /tmp/archive && \
    mv /usr/lib/liblapack.so* /usr/lib/libopenblas.so* /tmp/archive && \
    ./configure --COPTFLAGS="-g" \
               --CXXOPTFLAGS="-g" \
               --FOPTFLAGS="-g" \
               --with-blas-lib=/usr/lib/libopenblas.a \
               --with-lapack-lib=/usr/lib/liblapack.a \
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
               --prefix=/usr/local/petsc-$PETSC_VERSION-32-dbg && \
    make all test && \
    make install && \
    mv /tmp/archive/lib*.* /usr/lib && \
    rm -rf /tmp/* /var/tmp/*

USER $DOCKER_USER

###############################################################
# Customize Atom
###############################################################
RUN sudo pip3 install -U \
         autopep8 \
         flake8 \
         PyQt5 \
         spyder && \
    \
    sudo mkdir -p /usr/local/mlint && \
    curl -L https://goo.gl/ExjLDP | \
    sudo bsdtar zxf - -C /usr/local/mlint --strip-components 4 && \
    sudo ln -s -f /usr/local/mlint/bin/glnxa64/mlint /usr/local/bin && \
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
    ln -s -f $DOCKER_HOME/.config/atom/* $DOCKER_HOME/.atom && \
    rm -rf /tmp/*

WORKDIR $DOCKER_HOME
USER root
