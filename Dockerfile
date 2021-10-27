FROM nvidia/cuda:11.2.0-cudnn8-runtime-ubuntu18.04

USER root

## Basic Env
ENV \
    SHELL="/bin/bash" \
    HOME="/root"  \
    USER_GID=0
WORKDIR $HOME




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
    chmod -R a+rwx /usr/local/bin/ 


# Install package from requirements.txt (Not recommended to edit)
COPY requirements.txt ./requirements.txt
RUN pip install -r ./requirements.txt && rm requirements.txt

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
