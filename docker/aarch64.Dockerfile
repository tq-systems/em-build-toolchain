#
# aarch64 image to run jobs for aarch64 target
#
ARG PUBLIC_TOOLCHAIN_REGISTRY
ARG BUILD_TAG
FROM ${PUBLIC_TOOLCHAIN_REGISTRY}/amd64:${BUILD_TAG} AS tools
FROM ${PUBLIC_TOOLCHAIN_REGISTRY}/common:${BUILD_TAG}

COPY --from=tools /usr/local/go /usr/local/go
ENV PATH=/usr/local/go/bin:$PATH

ENV PKG_ARCH=aarch64
ENV OE_ARCH=aarch64-oe-linux

# Install cross-compiler toolchain
ARG PATH_AARCH64_TOOLCHAIN TMP_TOOLCHAIN=/tmp/toolchain.sh
COPY ${PATH_AARCH64_TOOLCHAIN} ${TMP_TOOLCHAIN}
RUN chmod +x ${TMP_TOOLCHAIN} && ${TMP_TOOLCHAIN} -d /opt/emos -y && rm ${TMP_TOOLCHAIN}

COPY ./docker/make-toolchain-wrappers.sh /tmp/make-toolchain-wrappers.sh
RUN . /opt/emos/environment-setup-$OE_ARCH && /tmp/make-toolchain-wrappers.sh \
	&& rm /tmp/make-toolchain-wrappers.sh

RUN . /opt/emos/environment-setup-$OE_ARCH && \
	( \
		echo 'export GOARCH=arm64'; \
		echo 'export CGO_ENABLED=1'; \
	) > $OECORE_TARGET_SYSROOT/environment-setup.d/golang.sh

# Prebuild std library for ARM to speed up builds
RUN . /opt/emos/environment-setup-$OE_ARCH && go install std

# Store bootloader image and core image for em-aarch64
ARG PATH_EMIT_EM_AARCH64=/opt/energy-manager/emit/em-aarch64
RUN mkdir -p ${PATH_EMIT_EM_AARCH64}

ARG PATH_EM_AARCH64_BOOTLOADER \
	TMP_EM_AARCH64_BOOTLOADER=/tmp/em-image-core-em-aarch64.bootloader.tar
COPY ${PATH_EM_AARCH64_BOOTLOADER} ${TMP_EM_AARCH64_BOOTLOADER}
RUN tar -C ${PATH_EMIT_EM_AARCH64} -xf ${TMP_EM_AARCH64_BOOTLOADER} && rm ${TMP_EM_AARCH64_BOOTLOADER}

ARG PATH_EM_AARCH64_CORE_IMAGE
COPY ${PATH_EM_AARCH64_CORE_IMAGE} ${PATH_EMIT_EM_AARCH64}/em-image-core-em-aarch64.tar

# Install amd64 go binaries
COPY --from=tools /workspace/go/bin /workspace/go/bin

ARG DOCKER_USER
RUN chown -R ${DOCKER_USER} /workspace

COPY ./docker/opt/ /opt/

USER ${DOCKER_USER}

ENV GOPATH=/workspace/go
ENV PATH=$PATH:$GOPATH/bin

ENV GO111MODULE=on
ARG GOPRIVATE
ENV GOPRIVATE=${GOPRIVATE}

ENTRYPOINT ["sh", "-c", ". /opt/emos/environment-setup-$OE_ARCH && exec \"$@\"", "-"]
