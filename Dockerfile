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
ADD WELCOME $DOCKER_HOME/WELCOME

# Install diffmerge and gdutil
RUN chown -R $DOCKER_USER:$DOCKER_GROUP $DOCKER_HOME && \
    echo "deb http://debian.sourcegear.com/ubuntu precise main" > \
         /etc/apt/sources.list.d/sourcegear.list && \
    curl -L http://debian.sourcegear.com/SOURCEGEAR-GPG-KEY | apt-key add - && \
    apt-get update && \
    apt-get install -y diffmerge && \
    \
    git clone --depth 1 https://github.com/hpdata/gdutil /usr/local/gdutil && \
    pip2 install -r /usr/local/gdutil/requirements.txt && \
    pip3 install -r /usr/local/gdutil/requirements.txt && \
    ln -s -f /usr/local/gdutil/bin/* /usr/local/bin/ && \
    chown -R $DOCKER_USER:$DOCKER_GROUP $DOCKER_HOME && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

USER $DOCKER_USER

###############################################################
# Temporarily install MATLAB and build ilupack4m, paracoder, and
# petsc4m for Octave and MATLAB. Install Atom packages.
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
    MATLAB_VERSION=$(cd /usr/local/MATLAB; ls) sudo -E /etc/my_init.d/make_aliases.sh && \
    \
    $DOCKER_HOME/bin/build_fastsolve -matlab && \
    sudo rm -rf /usr/local/MATLAB/R* && \
    \
    echo "run $DOCKER_HOME/fastsolve/paracoder/startup.m" >> $DOCKER_HOME/.octaverc && \
    echo "run $DOCKER_HOME/fastsolve/ilupack4m/startup.m" > $DOCKER_HOME/.octaverc && \
    echo "run $DOCKER_HOME/fastsolve/petsc4m/startup.m" >> $DOCKER_HOME/.octaverc && \
    \
    rm -f $DOCKER_HOME/.ssh/id_rsa* && \
    ln -s -f $DOCKER_HOME/.config/matlab $DOCKER_HOME/.matlab && \
    echo "@start_matlab -desktop" >> $DOCKER_HOME/.config/lxsession/LXDE/autostart && \
    echo "PATH=$DOCKER_HOME/bin:/usr/local/gdutil/bin:$PATH" >> $DOCKER_HOME/.profile

WORKDIR $DOCKER_HOME/fastsolve
USER root
