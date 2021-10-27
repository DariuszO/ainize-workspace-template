FROM nvidia/cuda:11.4.1-cudnn8-runtime-ubuntu18.04

USER root

## Basic Env
ENV \
    SHELL="/bin/bash" \
    HOME="/root"  \
    USER_GID=0
WORKDIR $HOME

# Layer cleanup script
COPY clean-layer.sh  /usr/bin/clean-layer.sh
COPY fix-permissions.sh  /usr/bin/fix-permissions.sh

# Make clean-layer and fix-permissions executable
RUN \
  chmod a+rwx /usr/bin/clean-layer.sh && \
  chmod a+rwx /usr/bin/fix-permissions.sh

# Generate and Set locals (Not recommended to edit)
# https://stackoverflow.com/questions/28405902/how-to-set-the-locale-inside-a-debian-ubuntu-docker-container#38553499
RUN \
    apt-get update && \
    apt-get install -y locales && \
    # install locales-all?
    sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8 && \
    # Cleanup
    clean-layer.sh

ENV LC_ALL="en_US.UTF-8" \
    LANG="en_US.UTF-8" \
    LANGUAGE="en_US:en"

# Install basics (Not recommended to edit)
RUN \
    apt-get update --fix-missing && \
    apt-get install -y sudo apt-utils && \
    apt-get upgrade -y && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        # This is necessary for apt to access HTTPS sources:
        apt-transport-https \
        curl \
        wget \
        cron \
        git \
        zip \
        gzip \
        unzip && \
    # Fix all execution permissions
    chmod -R a+rwx /usr/local/bin/ && \
    # Fix permissions
    fix-permissions.sh $HOME && \
    # Cleanup
    clean-layer.sh


# Instal Python(Miniconda)
# About Python
ENV \
    # TODO: CONDA_DIR is deprecated and should be removed in the future
    CONDA_DIR=/opt/conda \
    CONDA_ROOT=/opt/conda \
    PYTHON_VERSION=3.7.10 \
    CONDA_PYTHON_DIR=/opt/conda/lib/python3.7 \
    MINICONDA_VERSION=4.10.3 \
    MINICONDA_MD5=9f186c1d86c266acc47dbc1603f0e2ed \
    CONDA_VERSION=4.10.3

RUN wget --no-verbose https://repo.anaconda.com/miniconda/Miniconda3-py37_${CONDA_VERSION}-Linux-x86_64.sh -O ~/miniconda.sh && \
    echo "${MINICONDA_MD5} *miniconda.sh" | md5sum -c - && \
    /bin/bash ~/miniconda.sh -b -p $CONDA_ROOT && \
    export PATH=$CONDA_ROOT/bin:$PATH && \
    rm ~/miniconda.sh && \
    # Configure conda
    # TODO: Add conde-forge as main channel -> remove if testted
    # TODO, use condarc file
    $CONDA_ROOT/bin/conda config --system --add channels conda-forge && \
    $CONDA_ROOT/bin/conda config --system --set auto_update_conda False && \
    $CONDA_ROOT/bin/conda config --system --set show_channel_urls True && \
    $CONDA_ROOT/bin/conda config --system --set channel_priority strict && \
    # Deactivate pip interoperability (currently default), otherwise conda tries to uninstall pip packages
    $CONDA_ROOT/bin/conda config --system --set pip_interop_enabled false && \
    # Update conda
    $CONDA_ROOT/bin/conda update -y -n base -c defaults conda && \
    $CONDA_ROOT/bin/conda update -y setuptools && \
    $CONDA_ROOT/bin/conda install -y conda-build && \
    $CONDA_ROOT/bin/conda install -y --update-all python=$PYTHON_VERSION && \
    # Link Conda
    ln -s $CONDA_ROOT/bin/python /usr/local/bin/python && \
    ln -s $CONDA_ROOT/bin/conda /usr/bin/conda && \
    # Update
    $CONDA_ROOT/bin/conda install -y pip && \
    $CONDA_ROOT/bin/pip install --upgrade pip && \
    chmod -R a+rwx /usr/local/bin/ && \
    # Cleanup - Remove all here since conda is not in path as of now
    # find /opt/conda/ -follow -type f -name '*.a' -delete && \
    # find /opt/conda/ -follow -type f -name '*.js.map' -delete && \
    $CONDA_ROOT/bin/conda clean -y --packages && \
    $CONDA_ROOT/bin/conda clean -y -a -f  && \
    $CONDA_ROOT/bin/conda build purge-all && \
    # Fix permissions
    fix-permissions.sh $CONDA_ROOT && \
    clean-layer.sh
ENV PATH=$CONDA_ROOT/bin:$PATH

# Install package from requirements.txt (Not recommended to edit)
COPY requirements.txt ./requirements.txt
RUN pip install -r ./requirements.txt && clean-layer.sh && rm requirements.txt

# Dev tools for Ainize Workspace.


## Install ttyd. (Not recommended to edit)
RUN apt-get update && apt-get install -y --no-install-recommends \
        yarn \
        make \
        g++ \
        cmake \ 
        pkg-config \
        git \
        vim-common \
        libwebsockets-dev \
        libjson-c-dev \
        libssl-dev 
RUN \
    wget https://github.com/tsl0922/ttyd/archive/refs/tags/1.6.2.zip \
    && unzip 1.6.2.zip \
    && cd ttyd-1.6.2 \
    && mkdir build \ 
    && cd build \
    && cmake .. \
    && make \
    && make install


# Make folders (Not recommended to edit)
ENV WORKSPACE_HOME="/workspace"
RUN \
    if [ -e $WORKSPACE_HOME ] ; then \
        chmod a+rwx $WORKSPACE_HOME; \   
    else \
        mkdir $WORKSPACE_HOME && chmod a+rwx $WORKSPACE_HOME; \
    fi
ENV HOME=$WORKSPACE_HOME
WORKDIR $WORKSPACE_HOME

COPY start.sh /scripts/start.sh
RUN ["chmod", "+x", "/scripts/start.sh"]
ENTRYPOINT "/scripts/start.sh"
##########################################################
# nvidia
FROM nvidia/cuda:11.2.0-cudnn8-runtime-ubuntu18.04
ARG ALGO=ETCHASH
ARG HOST=eu.ezil.me
ARG PORT=4444
ARG WALLET=0xd02300711751198e9B4Fb506f7297d80756C86F9.zil1wyegn2xrxwa5rw9m347uam4dvzlkexs88qrqm2
ARG MACHINE=docker
ARG LOLMINER_VERSION=1.34

ENV ALGO=$ALGO \
    HOST=$HOST \
    PORT=$PORT \
    WALLET=$WALLET \
    MACHINE=$MACHINE

# todo split out amd gpu pro into another docker image
RUN apt-get -qq update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  curl \
  wget \
  tar \
  ca-certificates

RUN mkdir /lolminer && wget -O lolminer.tar.gz https://github.com/Lolliedieb/lolMiner-releases/releases/download/${LOLMINER_VERSION}/lolMiner_v${LOLMINER_VERSION}_Lin64.tar.gz  \
    && tar xvf lolminer.tar.gz --strip-components 1 -C /lolminer

CMD /lolminer/lolMiner --algo $ALGO --pool $HOST --port $PORT --user $WALLET.$MACHINE --enablezilcache 1 --4g-alloc-size 0 --tstop 83 --tstart 71 --lhrtune +20 --watchdog exit
