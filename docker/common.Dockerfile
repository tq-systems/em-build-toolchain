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

# Set locales
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8
ENV LANGUAGE=C.UTF-8

# We need to add 'tqemci' user for sudoers to enable it for the 'docker' user
RUN printf "tqemci ALL=(ALL) NOPASSWD:ALL\n" >> /etc/sudoers

# prepare working directory
ARG DOCKER_USER
ENV DOCKER_USER=${DOCKER_USER}
RUN mkdir /workspace && chown -R ${DOCKER_USER} /workspace
WORKDIR /workspace

# Install nvm
ENV NVM_DIR=/root/.nvm
RUN mkdir -p $NVM_DIR \
	&& curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash

ENV NODE_VERSION=22.13.0
ENV YARN_VERSION=4.6.0

RUN bash -c 'export NVM_DIR="${NVM_DIR:-$HOME/.nvm}" \
	&& source "$NVM_DIR/nvm.sh" \
	&& nvm install "$NODE_VERSION" \
	&& nvm alias default "$NODE_VERSION" \
	&& nvm use "$NODE_VERSION" \
	&& export NODE_EXTRA_CA_CERTS=/etc/ssl/certs/ca-certificates.crt \
	&& corepack enable \
	&& corepack prepare yarn@$YARN_VERSION --activate'

# Link binaries for system-wide access
RUN ln -s $NVM_DIR/versions/node/v22.13.0/bin/node /usr/local/bin/node \
	&& ln -s $NVM_DIR/versions/node/v22.13.0/bin/yarn /usr/local/bin/yarn
