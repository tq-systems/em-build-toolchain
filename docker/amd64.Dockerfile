#
# amd64 image to run jobs for amd64 target
#
ARG PUBLIC_TOOLCHAIN_REGISTRY
ARG BUILD_TAG
FROM ${PUBLIC_TOOLCHAIN_REGISTRY}/common:${BUILD_TAG}

RUN apt-get update && apt-get -y upgrade \
&& apt-get install -y \
	cmake cmake-curses-gui \
	clang clang-format clang-tools \
	cppcheck \
	libcurl3-dev \
	libdaemon-dev \
	libdbus-1-dev \
	libglib2.0-dev \
	libjansson-dev \
	libjson-glib-dev \
	liblzma-dev \
	libmosquitto-dev \
	libmodbus-dev \
	libsqlite3-dev \
	libssl-dev \
	libsystemd-dev \
	mosquitto \
	socat \
	tzdata \
	libabsl-dev \
	python3-absl \
&& apt-get autoremove --yes && apt-get clean --yes

ENV OE_ARCH=aarch64-oe-linux
# Install cross-compiler toolchain
ARG PATH_AARCH64_TOOLCHAIN TMP_TOOLCHAIN=/tmp/toolchain.sh
COPY ${PATH_AARCH64_TOOLCHAIN} ${TMP_TOOLCHAIN}
RUN chmod +x ${TMP_TOOLCHAIN} && ${TMP_TOOLCHAIN} -d /opt/emos -y && rm ${TMP_TOOLCHAIN}

ENV GO_VERSION=1.23.6

# Fetch the latest Go version
RUN GO_VERSION=$(curl -s https://go.dev/VERSION?m=text | awk '/^go/{print $0}' | sed 's/^go//'); \
	if [ -z "$GO_VERSION" ]; then echo "Go version not found"; exit 1; fi && \
	echo "Using Go version: ${GO_VERSION}" && \
	wget -c -nv --no-check-certificate https://go.dev./dl/go${GO_VERSION}.linux-amd64.tar.gz -O - | tar -xz -C /usr/local
ENV PATH=/usr/local/go/bin:$PATH

RUN pip3 install cpplint gcovr lizard pytest pymodbus

ARG DOCKER_USER
ENV DOCKER_USER=${DOCKER_USER}
# TODO: workaround: git clone as user and install as root - we need to install only fixed versions
USER ${DOCKER_USER}
# 
RUN git clone https://github.com/tq-systems/libdeviceinfo-em.git libdeviceinfo && cd libdeviceinfo && git checkout v1.6.0 \
	&& mkdir build && cd build && cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr .. && make
USER root
RUN make -C libdeviceinfo/build install && rm -r libdeviceinfo

USER ${DOCKER_USER}

ENV GOPATH=/workspace/go
ENV PATH=$GOPATH/bin:/workspace/.yarn/node_modules/.bin:$PATH:/home/${DOCKER_USER}/.local/bin
ENV GO111MODULE=on
ARG GOPRIVATE
ENV GOPRIVATE=${GOPRIVATE}

ENV PROTOC_VERSION=25.3

ENV PB_REL="https://github.com/protocolbuffers/protobuf/releases"
RUN curl -LO $PB_REL/download/v${PROTOC_VERSION}/protoc-${PROTOC_VERSION}-linux-x86_64.zip; \
	unzip protoc-${PROTOC_VERSION}-linux-x86_64.zip -d /home/${DOCKER_USER}/.local

RUN git clone https://github.com/protocolbuffers/protobuf.git; \
	cd protobuf && git checkout v${PROTOC_VERSION} && git submodule update --init --recursive && mkdir cmake/build && \
	cd cmake/build && cmake -Dprotobuf_WITH_ABSEIL=ON -Dprotobuf_BUILD_SHARED_LIBS=ON -Dprotobuf_BUILD_TESTS=OFF -DCMAKE_BUILD_TYPE=Release ../.. && sudo make -j$(nproc) && sudo make install && \
	rm -rf /workspace/protobuf && rm -f /workspace/protoc-${PROTOC_VERSION}-linux-x86_64.zip && sudo ldconfig

RUN go install go.uber.org/mock/mockgen@v0.4.0
RUN go install github.com/golangci/golangci-lint/cmd/golangci-lint@v1.64.5
RUN go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.36.5
RUN go install github.com/go-delve/delve/cmd/dlv@v1.8.0
RUN go install golang.org/x/tools/cmd/godoc@v0.1.8
RUN go install github.com/jstemmer/go-junit-report@v0.9.1
RUN go install github.com/zricethezav/gitleaks/v8@v8.15.1
RUN go install github.com/planetscale/vtprotobuf/cmd/protoc-gen-go-vtproto@v0.6.0
RUN go install github.com/tq-systems/public-go-utils/cmd/omitemptyremover@v1.0.0
RUN go install github.com/tq-systems/em-go-licenses@v1.0.1-tq

COPY ./docker/opt/ /opt/

USER ${DOCKER_USER}

ENTRYPOINT ["sh", "-c", "exec \"$@\"", "-"]
