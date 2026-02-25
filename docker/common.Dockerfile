#
# base image for common settings and tools
#

ARG BASE_REGISTRY
ARG BASE_DOCKER_TAG
FROM ${BASE_REGISTRY}/ubuntu:${BASE_DOCKER_TAG}

# copy ./docker/etc
COPY ./docker/etc/ /etc/

# install basic tools
RUN apt-get update && apt-get -y upgrade && apt-get install -y \
	autoconf \
	automake \
	bash-completion \
	bsdmainutils \
	build-essential \
	curl \
	fakeroot \
	gawk \
	git \
	jq \
	libtool \
	nano \
	python3 \
	python3-pip \
	python3-yaml \
	rsync \
	software-properties-common \
	sudo \
	wget \
	unzip

# Install a fixed node version
ARG NODE_VERSION=22.13.0
RUN apt-get install -y nodejs=${NODE_VERSION}-1nodesource1 && apt-mark hold nodejs

# prepare working directory
ARG DOCKER_USER
ENV DOCKER_USER=${DOCKER_USER}
RUN mkdir /workspace && chown -R ${DOCKER_USER}:${DOCKER_USER} /workspace
WORKDIR /workspace

# Install a fixed yarn version directly, without corepack
ARG YARN_VERSION=4.6.0
ENV YARN_ENABLE_TELEMETRY=0
RUN curl -fsSL https://repo.yarnpkg.com/${YARN_VERSION}/packages/yarnpkg-cli/bin/yarn.js \
    -o /usr/local/lib/yarn.cjs && \
    printf '#!/bin/sh\nexec node /usr/local/lib/yarn.cjs "$@"\n' \
    > /usr/local/bin/yarn && \
    chmod +x /usr/local/bin/yarn && \
    npm uninstall -g corepack

# Set locales
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8
ENV LANGUAGE=C.UTF-8

# Prepare golang environment for further images
ENV GOPATH=/workspace/go
ENV PATH=/usr/local/go/bin:$PATH:$GOPATH/bin
ENV GO111MODULE=on
ARG GOPRIVATE
ENV GOPRIVATE=${GOPRIVATE}

# Enable access to local binaries
ENV PATH=$PATH:/home/${DOCKER_USER}/.local/bin

# We need to add 'tqemci' user for sudoers to enable it for the 'docker' user
RUN printf "tqemci ALL=(ALL) NOPASSWD:ALL\n" >> /etc/sudoers

# Enable to use the scripts in further images
COPY ./scripts/*.sh /usr/local/bin/

# Enable to use the local usr dir in further images
COPY ./docker/usr/local/ /usr/local/
