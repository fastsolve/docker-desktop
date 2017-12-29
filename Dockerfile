# Builds a Docker image for FastSolve development environment
# with Ubuntu 16.04, Octave, Python3, Jupyter Notebook and Atom
#
# Authors:
# Xiangmin Jiao <xmjiao@gmail.com>

FROM fastsolve/desktop:base
LABEL maintainer "Xiangmin Jiao <xmjiao@gmail.com>"

USER root
WORKDIR /tmp

ADD image/home $DOCKER_HOME/

# Install atom, diffmerge, and PETSc with Hypre
RUN add-apt-repository ppa:webupd8team/atom && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        openjdk-8-jre-headless \
        meld \
        atom \
        clang-format && \
    \
    echo "deb http://debian.sourcegear.com/ubuntu precise main" > \
             /etc/apt/sources.list.d/sourcegear.list && \
    curl -L http://debian.sourcegear.com/SOURCEGEAR-GPG-KEY | apt-key add - && \
    apt-get update && \
    apt-get install -y diffmerge && \
    \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    chown -R $DOCKER_USER:$DOCKER_GROUP $DOCKER_HOME && \
    echo "move_to_config atom" >> /usr/local/bin/init_vnc && \
    rm -rf /tmp/* /var/tmp/*

USER $DOCKER_USER
ENV  GIT_EDITOR=vi EDITOR=atom

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
    rm -rf /tmp/*

WORKDIR $DOCKER_HOME
USER root
