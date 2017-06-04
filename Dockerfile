# Builds a Docker image with Ubuntu 16.04, Octave, Python3 and Jupyter Notebook
# for FastSolve
#
# Authors:
# Xiangmin Jiao <xmjiao@gmail.com>

FROM x11vnc/desktop:latest
LABEL maintainer "Xiangmin Jiao <xmjiao@gmail.com>"

USER root
WORKDIR /tmp

# Install system packages
RUN apt-add-repository ppa:octave/stable && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        python3-dev \
        gfortran \
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
    apt-get install -y --no-install-recommends \
        octave \
        gnuplot-x11 \
        liboctave-dev \
        libopenblas-base \
        libatlas3-base \
        pstoedit \
        octave-info \
        \
        pandoc \
        ttf-dejavu && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install SciPy, SymPy, Pandas, and Jupyter Notebook for Python3 and Octave
# Customize Atom for Octave and MATLAB
RUN curl -O https://bootstrap.pypa.io/get-pip.py && \
    python3 get-pip.py && \
    pip3 install -U \
         setuptools \
         requests \
         progressbar2 \
         PyDrive \
         \
         numpy \
         matplotlib \
         sympy \
         scipy \
         pandas \
         nose \
         sphinx \
         flufl.lock \
         ply \
         pytest \
         six \
         urllib3 \
         ipython \
         jupyter \
         ipywidgets && \
    jupyter nbextension install --py --system \
         widgetsnbextension && \
    jupyter nbextension enable --py --system \
         widgetsnbextension && \
    pip3 install -U \
        jupyter_latex_envs==1.3.8.4 && \
    jupyter nbextension install --py --system \
        latex_envs && \
    jupyter nbextension enable --py --system \
        latex_envs && \
    jupyter nbextension install --system \
        https://bitbucket.org/ipre/calico/downloads/calico-spell-check-1.0.zip && \
    jupyter nbextension install --system \
        https://bitbucket.org/ipre/calico/downloads/calico-document-tools-1.0.zip && \
    jupyter nbextension install --system \
        https://bitbucket.org/ipre/calico/downloads/calico-cell-tools-1.0.zip && \
    jupyter nbextension enable --system \
        calico-spell-check && \
    pip3 install -U octave_kernel && \
    python3 -m octave_kernel.install && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Download ilupack4m and compile it
RUN mkdir -p /usr/local/ilupack4m && \
    curl -s  -L https://github.com/fastsolve/ilupack4m/archive/master.tar.gz | \
        bsdtar zxf - --strip-components 1 -C /usr/local/ilupack4m && \
    cd /usr/local/ilupack4m/makefiles && make TARGET=Octave

# Install PETSc from source.
ENV PETSC_VERSION=3.7.6 \
    OPENBLAS_NUM_THREADS=1 \
    OPENBLAS_VERBOSE=0

RUN curl -s http://ftp.mcs.anl.gov/pub/petsc/release-snapshots/petsc-lite-${PETSC_VERSION}.tar.gz | \
    tar zx && \
    cd petsc-${PETSC_VERSION} && \
    ./configure --COPTFLAGS="-O2" \
                --CXXOPTFLAGS="-O2" \
                --FOPTFLAGS="-O2" \
                --with-blas-lib=/usr/lib/libopenblas.a --with-lapack-lib=/usr/lib/liblapack.a \
                --with-c-support \
                --with-debugging=0 \
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
                --prefix=/usr/local/petsc-$PETSC_VERSION && \
     make && \
     make install && \
     rm -rf /tmp/* /var/tmp/*

ENV PETSC_DIR=/usr/local/petsc-$PETSC_VERSION

# Install paracoder and petsc4m
RUN mkdir -p /usr/local/paracoder && \
    curl -s  -L https://github.com/fastsolve/paracoder/archive/master.tar.gz | \
        bsdtar zxf - --strip-components 1 -C /usr/local/paracoder && \
    cd /usr/local/paracoder && octave --eval "build_m2c -force" && \
    rm -rf `find /usr/local/paracoder -name lib` && \
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
    echo 'addpath /usr/local/ilupack4m/matlab/ilupack' >> $DOCKER_HOME/.octaverc && \
    echo 'run /usr/local/paracoder/.octaverc' >> $DOCKER_HOME/.octaverc && \
    echo 'run /usr/local/petsc4m/.octaverc' >> $DOCKER_HOME/.octaverc && \
    echo '@octave --force-gui' >> $DOCKER_HOME/.config/lxsession/LXDE/autostart && \
    chown -R $DOCKER_USER:$DOCKER_GROUP $DOCKER_HOME

WORKDIR $DOCKER_HOME
