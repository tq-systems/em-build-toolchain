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

# TODO: Remove this after moving to Ubuntu 24.04
# Add Ubuntu 24.04 sources temporarily, update, install packages, and remove sources
RUN echo 'deb http://archive.ubuntu.com/ubuntu noble main universe' > /etc/apt/sources.list.d/ubuntu-24.04.list \
	&& apt-get update \
	&& apt-get install -y libsoup-3.0-dev libglib2.0-dev libgupnp-1.6 libgupnp-1.6-dev \
	&& rm -f /etc/apt/sources.list.d/ubuntu-24.04.list \
	&& rm -rf /var/lib/apt/lists/*

ARG GO_VERSION=1.25.5
RUN wget -c -nv --no-check-certificate https://go.dev./dl/go${GO_VERSION}.linux-amd64.tar.gz -O - \
	| tar -xz -C /usr/local

RUN pip3 install cpplint gcovr lizard pytest pymodbus

# TODO: workaround: git clone as user and install as root - we need to install only fixed versions
ARG DOCKER_USER
USER ${DOCKER_USER}
ARG LIBDEVICEINFO_VERSION=1.8.0
RUN git clone https://github.com/tq-systems/libdeviceinfo-em.git libdeviceinfo \
	&& cd libdeviceinfo && git checkout v${LIBDEVICEINFO_VERSION} \
	&& mkdir build && cd build && cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr .. && make
USER root
RUN make -C libdeviceinfo/build install && rm -r libdeviceinfo

USER ${DOCKER_USER}

ARG PB_VERSION=25.3
ARG PB_URL="https://github.com/protocolbuffers/protobuf"
ARG PB_FILE="protoc-${PB_VERSION}-linux-x86_64.zip"
RUN curl -LO ${PB_URL}/releases/download/v${PB_VERSION}/${PB_FILE} \
	&& unzip ${PB_FILE} -d /home/${DOCKER_USER}/.local && rm -f ${PB_FILE}
RUN git clone ${PB_URL}.git && cd protobuf && git checkout v${PB_VERSION} \
	&& git submodule update --init --recursive && mkdir cmake/build && cd cmake/build \
	&& cmake -Dprotobuf_WITH_ABSEIL=ON -Dprotobuf_BUILD_SHARED_LIBS=ON -Dprotobuf_BUILD_TESTS=OFF \
		-DCMAKE_BUILD_TYPE=Release ../.. \
	&& sudo make -j$(nproc) && sudo make install && rm -rf /workspace/protobuf && sudo ldconfig

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
RUN go install github.com/CycloneDX/cyclonedx-gomod/cmd/cyclonedx-gomod@v1.9.0

# Files that change rapidly are processed last to improve build performance
USER root
COPY ./docker/opt/ /opt/

USER ${DOCKER_USER}

ENTRYPOINT ["sh", "-c", "exec \"$@\"", "-"]
