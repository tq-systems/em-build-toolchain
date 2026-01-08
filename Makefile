include $(CURDIR)/environment.mk

IMAGE ?= common amd64 aarch64

all: prepare-files
	$(MAKE) $(IMAGE)

prepare:
	./prepare.sh env ${EM_BUILD_REF}

prepare-files: prepare
	mkdir -p ${TQEM_TMP_PATH}
	./prepare.sh files ${EM_BUILD_REF}

common: prepare
	${DOCKER_COMPOSE_BUILD} common

amd64: common
	${DOCKER_COMPOSE_BUILD} amd64

aarch64: prepare-files amd64
	${DOCKER_COMPOSE_BUILD} aarch64

push: prepare
ifeq (${PUBLIC_TOOLCHAIN_REGISTRY}, ${LOCAL_TOOLCHAIN})
	$(error Prevent pushing to non-existing docker.io/${LOCAL_TOOLCHAIN}, exit.)
endif
	docker compose ${COMPOSE_FILE} push ${IMAGE}

pull: prepare
	docker compose ${COMPOSE_FILE} pull ${IMAGE}

clean-env:
	rm -f ${DOCKER_COMPOSE_ENV}

clean-tmp:
	rm -rf ${TQEM_TMP_PATH}

# Allow clean-system to fail because docker system prune fails when run more than once at the same
# time. This can happen when multiple images are built at the same time on a single Gitlab runner.
clean-system:
	docker system prune -f || true

clean: clean-env clean-tmp clean-system

check-tag:
ifeq (${BUILD_TAG}, latest)
	$(error Set BUILD_TAG to a string which is not 'latest')
endif
ifneq (,$(shell echo "${BUILD_TAG}" | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+'))
	$(error Set BUILD_TAG to a string which is not a valid version)
endif

# Explicitly skip 'clean-tmp' target to enable exchanging files in tmp directory
test-release: check-tag clean-env
	$(MAKE) all
	$(MAKE) push clean-system

# Use clean-system to avoid errors in parallel builds
release: clean-env clean-tmp
	$(MAKE) all
	$(MAKE) push clean-system

.PHONY: all common amd64 aarch64 \
	prepare prepare-files \
	push pull \
	clean-env clean-tmp clean-system clean \
	check-tag test-release release
